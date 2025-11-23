import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _currentUser;
  String _selectedRole = '';
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUser => _currentUser;
  String get selectedRole => _selectedRole;
  ThemeMode get themeMode => _themeMode;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error state management
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // User state management
  void setCurrentUser(String? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setSelectedRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Combined state updates
  void updateState({
    bool? loading,
    String? error,
    String? user,
    String? role,
  }) {
    if (loading != null) _isLoading = loading;
    if (error != null) _error = error;
    if (user != null) _currentUser = user;
    if (role != null) _selectedRole = role;
    notifyListeners();
  }

  // Reset all state
  void reset() {
    _isLoading = false;
    _error = null;
    _currentUser = null;
    _selectedRole = '';
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}
