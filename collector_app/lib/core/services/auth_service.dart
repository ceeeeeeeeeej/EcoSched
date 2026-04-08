import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'background_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:collector_app/core/routes/app_routes.dart';
import 'package:collector_app/core/services/push_notification_service.dart';


class AuthService extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthCheckComplete = false;

  // Getters
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAuthCheckComplete => _isAuthCheckComplete;

  // For residents, consider them "authenticated" if they have location set
  bool get isResidentWithLocation =>
      _user != null && _user!['role'] == 'resident';

  static const String _prefKeyBarangay = 'resident_barangay';
  static const String _prefKeyPurok = 'resident_purok';
  static const String _prefKeyUserId = 'resident_user_id';

  AuthService() {
    _initializeAuthState();
  }

  // Initialize auth state listener
  Future<void> _initializeAuthState() async {
    // Listen for Supabase auth changes
    SupabaseConfig.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserProfile(session.user.id).then((_) {
          if (_user != null) {
            final serviceArea = _user!['serviceArea'] ?? _user!['barangay'];
            BackgroundService.setSession(session.user.id,
                serviceArea: serviceArea);
          } else {
            BackgroundService.setSession(session.user.id);
          }
        });
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _clearResidentPersistence();
        BackgroundService.setSession(null);
        notifyListeners();
      }
    });

    // Check current Supabase session
    final currentUser = SupabaseConfig.auth.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
      BackgroundService.setSession(currentUser.id);
      // Ensure device is registered even if session was persisted
      PushNotificationService.registerDeviceForPush(currentUser.id).catchError((e) {
        if (kDebugMode) print('Startup device registration error: $e');
      });
    } else {
      // Get stable device ID and check for persisted resident session
      final deviceId = await _getDeviceId();
      await _loadResidentLocation(fallbackId: deviceId);
    }

    _isAuthCheckComplete = true;
    notifyListeners();
  }

  Future<void> _loadResidentLocation({String? fallbackId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final barangay = prefs.getString(_prefKeyBarangay);
      final purok = prefs.getString(_prefKeyPurok);
      String? userId = prefs.getString(_prefKeyUserId);

      // If no persisted userId but we have a fallback (device ID), use it
      if (userId == null && fallbackId != null) {
        userId = 'resident_$fallbackId';
      }

      if (barangay != null && purok != null) {
        setResidentLocation(
          barangay: barangay,
          purok: purok,
          userId: userId,
          persist: false,
        );
      } else if (userId != null) {
        // Even if location is not set, establish the session if we have a userId
        _user = {
          'uid': userId,
          'role': 'resident',
          'displayName': 'Guest Resident',
        };
      }
    } catch (e) {
      if (kDebugMode) print('Error loading resident location: $e');
    }
  }

  Future<void> _persistResidentLocation(
      String barangay, String purok, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBarangay, barangay);
      await prefs.setString(_prefKeyPurok, purok);
      await prefs.setString(_prefKeyUserId, userId);
    } catch (e) {
      if (kDebugMode) print('Error persisting resident location: $e');
    }
  }

  Future<void> _clearResidentPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyBarangay);
      await prefs.remove(_prefKeyPurok);
      await prefs.remove(_prefKeyUserId);
    } catch (e) {
      if (kDebugMode) print('Error clearing resident persistence: $e');
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

      final firstName = response['first_name'] as String? ?? '';
      final lastName = response['last_name'] as String? ?? '';
      final displayName = '$firstName $lastName'.trim();

      _user = {
        'uid': response['id'],
        'email': response['email'],
        'displayName': displayName.isNotEmpty
            ? displayName
            : (response['email'] as String).split('@')[0],
        'firstName': firstName,
        'lastName': lastName,
        'phone': response['phone'],
        'role': response['role'],
        'status': response['status'],
        'photoURL': response['photo_url'],
        'barangay': response['barangay'],
        'purok': response['purok'],
        'emailVerified': true, // Supabase handles email verification
        // Derive serviceArea from barangay for collectors
        'serviceArea': response['service_area'] ??
            _mapBarangayToServiceArea((response['barangay'] ?? '').toString()),
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

        final firstName = collectorResponse['first_name'] as String? ?? '';
        final lastName = collectorResponse['last_name'] as String? ?? '';
        final displayName = '$firstName $lastName'.trim();

        _user = {
          'uid': userId,
          'email': collectorResponse['email'],
          'displayName': displayName.isNotEmpty ? displayName : 'Collector',
          'firstName': firstName,
          'lastName': lastName,
          'phone': collectorResponse['phone'],
          'role': collectorResponse['role'],
          'status': collectorResponse['status'],
          'photoURL': null,
          'emailVerified': true,
          'barangay': collectorResponse['barangay'],
          'serviceArea': collectorResponse['service_area'] ??
              _mapBarangayToServiceArea(
                  (collectorResponse['barangay'] ?? '').toString()),
        };
        notifyListeners();
      } catch (e) {
        // If still not found, create basic user profile from Auth Meta
        final currentUser = SupabaseConfig.auth.currentUser;
        if (currentUser != null) {
          // Try to get name from metadata if available
          final metaName =
              currentUser.userMetadata?['full_name'] as String? ?? '';
          final metaFirst =
              currentUser.userMetadata?['first_name'] as String? ?? '';
          final metaLast =
              currentUser.userMetadata?['last_name'] as String? ?? '';

          String displayName = metaName;
          if (displayName.isEmpty &&
              (metaFirst.isNotEmpty || metaLast.isNotEmpty)) {
            displayName = '$metaFirst $metaLast'.trim();
          }
          if (displayName.isEmpty) {
            displayName = 'EcoSched User';
          }

          _user = {
            'uid': userId,
            'email': currentUser.email,
            'displayName': displayName,
            'role': _inferRoleFromEmail(currentUser.email ?? ''),
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

        // Register device for real push notifications (non-blocking)
        PushNotificationService.registerDeviceForPush(response.user!.id).catchError((e) {
          if (kDebugMode) print('Failed to register device: $e');
        });

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

      final nameParts = displayName?.split(' ') ?? ['', ''];
      final firstName = nameParts[0];
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'role': role ?? 'resident', // Default role in metadata
        },
      );

      if (response.user != null) {
        // Create user profile in database
        final userRole = role ?? _inferRoleFromEmail(email);

        await SupabaseConfig.client.from(SupabaseConfig.usersTable).insert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
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
    String? userId,
    String? currentLocation,
    bool persist = true,
  }) {
    final locationString = '$purok, $barangay';
    final serviceArea = _mapBarangayToServiceArea(barangay);

    // If no userId provided, generate or use stable ID
    String effectiveUserId = userId ??
        (_user != null &&
                _user!['uid'] != null &&
                _user!['uid'].startsWith('resident_')
            ? _user!['uid']
            : '');

    if (effectiveUserId.isEmpty) {
      // If we still don't have an ID, we'll try to get it asynchronously or fallback to timestamp
      // But since this method is sync, we hope it was already set in _initializeAuthState
      effectiveUserId = 'resident_${DateTime.now().millisecondsSinceEpoch}';
    }

    _user = {
      'uid': effectiveUserId,
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

    if (persist) {
      _persistResidentLocation(barangay, purok, effectiveUserId);
    }

    notifyListeners();
  }

  /// Automatically register a resident in the database for tracking in the Admin Dashboard
  Future<void> registerResidentInDatabase({
    required String barangay,
    required String userId,
    String? purok,
  }) async {
    try {
      if (kDebugMode) {
        print('📡 Automatically registering resident: $userId in $barangay');
      }

      final now = DateTime.now().toIso8601String();

      // Upsert user record for resident tracking
      await SupabaseConfig.client.from(SupabaseConfig.usersTable).upsert({
        'id': userId,
        'first_name': 'Guest',
        'last_name': 'Resident',
        'role': 'resident',
        'barangay': barangay,
        'purok': purok ?? '',
        'status': 'active',
        'created_at': now,
        'updated_at': now,
      }, onConflict: 'id');

      if (kDebugMode) {
        print('✅ Resident registered successfully: $userId');

        // Immediate verification
        final verification = await SupabaseConfig.client
            .from(SupabaseConfig.usersTable)
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (verification != null) {
          print(
              '🔍 Verified database record: FOUND for $userId in ${verification['barangay']}');
        } else {
          print(
              '⚠️ Verified database record: NOT FOUND for $userId immediately after upsert!');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error auto-registering resident: $e');
      }
      // We don't throw here to avoid blocking the user if registration fails
      // (as long as they are geofenced correctly)
    }
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
    } catch (e) {
      if (kDebugMode) print('Supabase signOut error: $e');
    } finally {
      _user = null;
      _clearResidentPersistence();
      _setLoading(false);
      notifyListeners();
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
        final updates = <String, dynamic>{};
        if (displayName != null) {
          final nameParts = displayName.split(' ');
          updates['first_name'] = nameParts[0];
          updates['last_name'] =
              nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        }

        // Update user metadata
        await SupabaseConfig.auth.updateUser(
          UserAttributes(
            data: updates,
          ),
        );

        // Update database profile
        if (displayName != null || photoURL != null) {
          final dbUpdates = <String, dynamic>{
            'updated_at': DateTime.now().toIso8601String(),
          };

          if (displayName != null) {
            final nameParts = displayName.split(' ');
            dbUpdates['first_name'] = nameParts[0];
            dbUpdates['last_name'] =
                nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          }
          if (photoURL != null) {
            dbUpdates['photo_url'] = photoURL;
          }

          await SupabaseConfig.client
              .from(SupabaseConfig.usersTable)
              .update(dbUpdates)
              .eq('id', currentUser.id);
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
    return _user?['role']?.toString().toLowerCase();
  }

  // Check if user is collector or admin
  bool isCollector() {
    final role = getUserRole();
    return role == 'collector' || role == 'admin';
  }

  // Check if user is resident
  bool isResident() {
    return getUserRole() == 'resident';
  }

  /// Centralized logic to navigate to the correct dashboard based on role
  void goHome(BuildContext context) {
    if (isCollector()) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.collectorDashboard, (route) => false);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.residentDashboard, (route) => false);
    }
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

  Future<String> _getDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Consistent device ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ??
            DateTime.now().millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      if (kDebugMode) print('Error getting device ID: $e');
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
