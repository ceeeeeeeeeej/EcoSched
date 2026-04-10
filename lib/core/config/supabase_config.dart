import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your Supabase project URL and anon key
  static const String supabaseUrl = 'https://bfqktqtsjchbmopafgzf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcWt0cXRzamNoYm1vcGFmZ3pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAyMDgwMTIsImV4cCI6MjA4NTc4NDAxMn0.Xu7Ncwr5bWYF8x2t5h7XHw_nPrjlTSkQEdnQB4OtcNo';

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get Supabase auth instance
  static GoTrueClient get auth => client.auth;

  // Database table names
  static const String usersTable = 'users';
  static const String registeredCollectorsTable = 'registered_collectors';
  static const String userActivitiesTable = 'user_activities';
  static const String notificationsTable = 'user_notifications';
  static const String systemSettingsTable = 'system_settings';
  static const String residentFeedbackTable = 'resident_feedback';
  static const String scheduledPickupsTable = 'scheduled_pickups';
  static const String specialCollectionsTable = 'special_collections';
  static const String binsTable = 'bins';
  static const String collectionSchedulesTable = 'collection_schedules';
  static const String routesTable = 'routes';
  static const String announcementsTable = 'announcements';
  static const String remindersTable = 'reminders';
  static const String areaSchedulesTable = 'area_schedules';

  // User roles
  static const String adminRole = 'admin';
  static const String supervisorRole = 'supervisor';
  static const String collectorRole = 'collector';
  static const String residentRole = 'resident';
}
