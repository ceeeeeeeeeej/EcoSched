import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // For residents, consider them "authenticated" if they have location set
  bool get isResidentWithLocation =>
      _user != null && _user!['role'] == 'resident';

  AuthService() {
    _initializeAuthState();
  }

  // Initialize auth state listener
  void _initializeAuthState() {
    SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        notifyListeners();
      }
    });

    // Check current session
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser != null) {
      _loadUserProfile(currentUser.id);
    }
  }

  // Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .single();

      _user = {
        'uid': response['id'],
        'email': response['email'],
        'displayName':
            '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'
                .trim(),
        'firstName': response['first_name'],
        'lastName': response['last_name'],
        'phone': response['phone'],
        'role': response['role'],
        'status': response['status'],
        'photoURL': response['photo_url'],
        'barangay': response['barangay'],
        'purok': response['purok'],
        'serviceArea': _mapBarangayToServiceArea(response['barangay'] ?? ''),
        'emailVerified': true, // Supabase handles email verification
      };
      notifyListeners();
    } catch (e) {
      // If user profile doesn't exist in users table, check registered_collectors
      try {
        final collectorResponse = await SupabaseConfig.client
            .from(SupabaseConfig.registeredCollectorsTable)
            .select()
            .eq('user_id', userId)
            .single();

        _user = {
          'uid': userId,
          'email': collectorResponse['email'],
          'displayName':
              '${collectorResponse['first_name']} ${collectorResponse['last_name']}',
          'firstName': collectorResponse['first_name'],
          'lastName': collectorResponse['last_name'],
          'phone': collectorResponse['phone'],
          'role': collectorResponse['role'],
          'status': collectorResponse['status'],
          'photoURL': null,
          'emailVerified': true,
        };
        notifyListeners();
      } catch (e) {
        // If still not found, create basic user profile
        final currentUser = SupabaseConfig.auth.currentUser;
        if (currentUser != null) {
          // Check metadata for role first, then infer from email
          final metadataRole = currentUser.userMetadata?['role'];
          final role =
              metadataRole ?? _inferRoleFromEmail(currentUser.email ?? '');

          _user = {
            'uid': userId,
            'email': currentUser.email,
            'displayName': currentUser.userMetadata?['full_name'] ??
                (currentUser.email?.split('@')[0] ?? 'EcoSched User'),
            'role': role,
            'emailVerified': currentUser.emailConfirmedAt != null,
          };
          notifyListeners();
        }
      }
    }
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign in with email and password
  Future<Map<String, dynamic>?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return _user;
      } else {
        _setError('Authentication failed. Please try again.');
        return null;
      }
    } on AuthException catch (e) {
      String message = 'Authentication failed. Please try again.';
      if (e.message.contains('Invalid login credentials')) {
        message = 'Invalid email or password.';
      } else if (e.message.contains('Email not confirmed')) {
        message = 'Please confirm your email address.';
      }
      _setError(message);
      return null;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? role,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': displayName,
        },
      );

      if (response.user != null) {
        // Create user profile in database
        final userRole = role ?? _inferRoleFromEmail(email);
        final nameParts = displayName?.split(' ') ?? ['', ''];

        await SupabaseConfig.client.from(SupabaseConfig.usersTable).insert({
          'id': response.user!.id,
          'email': email,
          'first_name': nameParts[0],
          'last_name':
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          'role': userRole,
          'status': 'active',
        });

        await _loadUserProfile(response.user!.id);
        return _user;
      } else {
        _setError('Registration failed. Please try again.');
        return null;
      }
    } on AuthException catch (e) {
      String message = 'Registration failed. Please try again.';
      if (e.message.contains('already registered')) {
        message = 'An account already exists for that email.';
      } else if (e.message.contains('Password should be')) {
        message = 'Password is too weak. Please choose a stronger one.';
      }
      _setError(message);
      return null;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Set resident location (no authentication required)
  void setResidentLocation({
    required String barangay,
    required String purok,
    String? currentLocation,
  }) {
    final locationString = '$purok, $barangay';
    final userId = 'resident_${DateTime.now().millisecondsSinceEpoch}';
    final serviceArea = _mapBarangayToServiceArea(barangay);

    _user = {
      'uid': userId,
      'displayName': 'Resident',
      'emailVerified': false,
      'role': 'resident',
      'barangay': barangay,
      'purok': purok,
      'location': locationString,
      'serviceArea': serviceArea,
      if (currentLocation != null && currentLocation.isNotEmpty)
        'currentLocation': currentLocation,
    };

    notifyListeners();
  }

  String _mapBarangayToServiceArea(String barangay) {
    final value = barangay.trim().toLowerCase();
    if (value.contains('victoria')) {
      return 'victoria';
    }
    if (value.contains('dayo-an') || value.contains('dayo-ay')) {
      return 'dayo-an';
    }
    return value;
  }

  // Sign in with location (barangay and purok) - kept for backward compatibility
  Future<Map<String, dynamic>?> signInWithLocation({
    required String barangay,
    required String purok,
  }) async {
    setResidentLocation(barangay: barangay, purok: purok);
    return _user;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await SupabaseConfig.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await SupabaseConfig.auth.resetPasswordForEmail(email);
      notifyListeners();
    } on AuthException catch (e) {
      String message = 'Password reset failed. Please try again.';
      if (e.message.contains('User not found')) {
        message = 'No user found for that email.';
      }
      _setError(message);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = SupabaseConfig.auth.currentUser;
      if (currentUser != null) {
        // Update user metadata
        await SupabaseConfig.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': displayName,
            },
          ),
        );

        // Update database profile
        if (displayName != null) {
          final nameParts = displayName.split(' ');
          await SupabaseConfig.client.from(SupabaseConfig.usersTable).update({
            'first_name': nameParts[0],
            'last_name':
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
            'photo_url': photoURL,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', currentUser.id);
        }

        await _loadUserProfile(currentUser.id);
      }
    } catch (e) {
      _setError('Profile update failed. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Get user role (helper method)
  String? getUserRole() {
    return _user?['role'];
  }

  // Check if user is collector
  bool isCollector() {
    return getUserRole() == 'collector';
  }

  // Check if user is resident
  bool isResident() {
    return getUserRole() == 'resident';
  }

  // Debug method to see all registered users (for testing)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response =
          await SupabaseConfig.client.from(SupabaseConfig.usersTable).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  String _inferRoleFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('collector') || lower.contains('demo@ecosched.com')) {
      return 'collector';
    }
    return 'resident';
  }
}
