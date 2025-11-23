import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  // Mock user data for now
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  // Mock database to store user roles
  static final Map<String, Map<String, dynamic>> _mockUserDatabase = {};

  // Getters
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // For residents, consider them "authenticated" if they have location set
  bool get isResidentWithLocation =>
      _user != null && _user!['role'] == 'resident';

  AuthService() {
    // Initialize with no user
    _user = null;
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

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Check if user exists in mock database
      if (_mockUserDatabase.containsKey(email)) {
        // User exists, retrieve their data
        _user = Map<String, dynamic>.from(_mockUserDatabase[email]!);
        _user!['emailVerified'] = true; // Mark as verified for login
      } else {
        // New user or demo login - determine role based on email for demo
        String userRole = 'resident'; // default
        if (email.contains('collector') ||
            email.contains('demo@ecosched.com')) {
          userRole = 'collector';
        }

        _user = {
          'uid': 'mock_user_id',
          'email': email,
          'displayName': 'Demo User',
          'emailVerified': true,
          'role': userRole,
        };
      }

      notifyListeners();
      return _user;
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

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful registration
      final userId = 'mock_user_id_${DateTime.now().millisecondsSinceEpoch}';
      _user = {
        'uid': userId,
        'email': email,
        'displayName': displayName ?? 'New User',
        'emailVerified': false,
        'role': role ?? 'resident',
      };

      // Store user data in mock database
      _mockUserDatabase[email] = {
        'uid': userId,
        'email': email,
        'displayName': displayName ?? 'New User',
        'emailVerified': false,
        'role': role ?? 'resident',
      };

      notifyListeners();
      return _user;
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

    _user = {
      'uid': userId,
      'displayName': 'Resident',
      'emailVerified': false,
      'role': 'resident',
      'barangay': barangay,
      'purok': purok,
      'location': locationString,
      if (currentLocation != null && currentLocation.isNotEmpty)
        'currentLocation': currentLocation,
    };

    notifyListeners();
  }

  // Sign in with location (barangay and purok) - kept for backward compatibility
  Future<Map<String, dynamic>?> signInWithLocation({
    required String barangay,
    required String purok,
  }) async {
    setResidentLocation(barangay: barangay, purok: purok);
    return _user;
  }

  // Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate Google sign-in
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful Google login
      _user = {
        'uid': 'google_user_id_${DateTime.now().millisecondsSinceEpoch}',
        'email': 'user@gmail.com',
        'displayName': 'Google User',
        'emailVerified': true,
        'photoURL': 'https://via.placeholder.com/150',
        'role': 'resident', // default for Google sign-in
      };

      notifyListeners();
      return _user;
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
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

      // Simulate password reset
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful password reset
      notifyListeners();
    } catch (e) {
      _setError('Password reset failed. Please try again.');
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

      if (_user != null) {
        _user!['displayName'] = displayName;
        if (photoURL != null) {
          _user!['photoURL'] = photoURL;
        }
        notifyListeners();
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
  Map<String, Map<String, dynamic>> getAllUsers() {
    return Map.from(_mockUserDatabase);
  }
}
