class AppConstants {
  // App Information
  static const String appName = 'EcoSched';
  static const String appVersion = '1.0.0';
  static const String defaultBarangay = 'Victoria';
  static const String defaultPurok = 'M. homes';
  
  // Role Types
  static const String collectorRole = 'collector';
  static const String residentRole = 'resident';
  
  // API Endpoints (placeholder)
  static const String baseUrl = 'https://api.ecosched.com';
  static const String authEndpoint = '/auth';
  static const String scheduleEndpoint = '/schedule';
  static const String notificationEndpoint = '/notifications';
  
  // AI Service API Key
  static const String geminiApiKey = 'AIzaSyBk0YsIM8kE1MViPGO9XvsSrUZr1LUSGX8';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}