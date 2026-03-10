import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import 'package:timezone/data/latest.dart' as tz;
import '../routes/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class NotificationService {
  static SupabaseClient get _supabase => SupabaseConfig.client;
  static RealtimeChannel? _notificationChannel;
  static final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown_device';
  }

  static Future<void> _registerDeviceToken() async {
    try {
      if (!_isSupportedPlatform) return;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      if (kDebugMode) print("📱 FCM Token retrieved: $token");

      if (token != null) {
        await saveDeviceToken(token, _activeServiceArea ?? 'Mahayag');
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error in _registerDeviceToken: $e");
    }
  }

  static Future<void> saveDeviceToken(String token, String barangay) async {
    try {
      final supabase = Supabase.instance.client;
      final deviceId = await _getDeviceId();

      final prefs = await SharedPreferences.getInstance();
      final residentId = prefs.getString("resident_user_id") ??
          prefs.getString("unique_device_id");

      await supabase.from('user_devices').upsert({
        'device_id': deviceId,
        'fcm_token': token,
        'barangay': barangay,
        if (residentId != null) 'resident_id': residentId,
      }, onConflict: 'device_id');

      if (kDebugMode) {
        print(
            "✅ Device token saved to Supabase for $barangay (device: $deviceId)");
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error saving device token: $e");
    }
  }

  static Future<void> cancelValidation(int id) async {
    if (!_isSupportedPlatform) return;
    await _localNotifications.cancel(id);
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (_isSupportedPlatform) {
      try {
        tz.initializeTimeZones(); // Initialize timezones
      } catch (e) {
        if (kDebugMode) print('Error initializing timezones: $e');
      }

      // Initialize local notifications immediately (Sync/Fast)
      try {
        const androidSettings =
            fln.AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = fln.DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const initSettings = fln.InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTap,
          onDidReceiveBackgroundNotificationResponse:
              _onNotificationTapBackground,
        );

        // Request permissions explicitly for Android 13+ (API 33+)
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidImplementation =
              _localNotifications.resolvePlatformSpecificImplementation<
                  fln.AndroidFlutterLocalNotificationsPlugin>();
          await androidImplementation?.requestNotificationsPermission();
        }

        if (kDebugMode) print('🔔 Local notifications initialized');
      } catch (e) {
        if (kDebugMode) print('Error initializing local notifications: $e');
      }

      // Load saved barangay/user ID to initialize listeners correctly
      final prefs = await SharedPreferences.getInstance();
      _activeServiceArea = prefs.getString("resident_barangay") ?? "Mahayag";
      _activeUserId = prefs.getString("resident_user_id");

      if (kDebugMode) {
        print('🔔 [NotificationService] Initializing with:');
        print('   - Barangay: $_activeServiceArea');
        print('   - Resident ID: $_activeUserId');
      }

      // Anonymous Realtime listener
      _setupSupabaseRealtimeListener();
    }
  }

  // Handle notification tap
  static void _onNotificationTap(fln.NotificationResponse response) {
    if (kDebugMode) print('🔔 Notification tapped: ${response.payload}');
    _navigateToDashboard();
  }

  // Handle background notification tap (must be a static method)
  @pragma('vm:entry-point')
  static void _onNotificationTapBackground(fln.NotificationResponse response) {
    // This runs in a separate isolate, so we can't navigate directly.
    if (kDebugMode) {
      print('🔔 Background notification tapped: ${response.payload}');
    }
  }

  static void _navigateToDashboard() {
    // Navigate to dashboard using the global key
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.residentDashboard, (route) => false);
    }
  }

  static String? _activeUserId;

  static void _setupSupabaseRealtimeListener() {
    if (_notificationChannel != null) {
      // If already subscribed but userId changed, we might need to recreate
      // For now, let's just allow it to be called once or handle updates
      _notificationChannel!.unsubscribe();
      _notificationChannel = null;
    }

    try {
      if (kDebugMode) {
        print(
            '🔌 Setting up Supabase Realtime Notifications (Barangay: $_activeServiceArea)...');
      }

      _notificationChannel = _supabase
          .channel('public:notifications:anonymous')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.notificationsTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'barangay',
              value: _activeServiceArea ?? 'Mahayag',
            ),
            callback: (payload) {
              _processNotificationPayload(payload);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.notificationsTable,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _activeUserId ?? '00000000-0000-0000-0000-000000000000',
            ),
            callback: (payload) {
              _processNotificationPayload(payload);
            },
          )
          .subscribe((status, error) {
        if (kDebugMode) {
          print('📡 Notification channel status: $status');
          if (error != null) print('❌ Realtime error: $error');
        }
      });

      if (kDebugMode) {
        print('✅ Supabase Realtime Notifications listener active');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error setting up Supabase Realtime: $e');
    }
  }

  static void _processNotificationPayload(payload) {
    if (kDebugMode) {
      print('📩 REALTIME ALERT RECEIVED!');
      print('   - Payload: $payload');
    }

    final data = payload.newRecord;
    if (data.isEmpty) {
      if (kDebugMode) print('   ⚠️ New record is empty. Ignoring.');
      return;
    }

    final title = data['title']?.toString() ?? 'EcoSched Update';
    final body = data['message']?.toString() ?? 'You have a new notification';

    if (kDebugMode) {
      print('🔔 [Notification] New alert received: $title');
      print('   - Message: $body');

      if (title.contains('Approved') || body.contains('approved')) {
        print(
            '✅ [ACCURACY CHECK] Resident Approval Verified in NotificationService!');
      }
    }

    // Show In-App SnackBar
    _showInAppAlert(title, body);

    // Also show local notification for better visibility
    showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }

  static void _showInAppAlert(String title, String message) {
    try {
      final context = AppRouter.navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(message),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to dashboard
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.residentDashboard, (route) => false);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error showing in-app alert: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isSupportedPlatform) return;

    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) return;

      if (kDebugMode) {
        print('🔔 NOTIFICATION SCHEDULED:');
        print('   - ID: $id');
        print('   - Title: $title');
        print('   - Time: $scheduledDate');
        print('   - Payload: $payload');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  static Future<void> createNotification({
    required String title,
    required String message,
    required String barangay,
  }) async {
    final supabase = Supabase.instance.client;

    await supabase.from("user_notifications").insert({
      "title": title,
      "message": message,
      "barangay": barangay,
    });
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isSupportedPlatform) return;

    if (kDebugMode) {
      print("🔔 [Notification] Showing Local alert: $title");
      if (title.contains('Approved')) {
        print("✅ [ACCURACY CHECK] Approval Local Notification Triggered!");
      }
    }

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'ecosched_alerts',
            'EcoSched Alerts',
            channelDescription: 'Important notifications and schedule updates',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing notification: $e');
      }
    }
  }

  /// Subscribe to notifications for a specific service area (barangay).
  /// This stores the active service area so notifications can be filtered accordingly.
  static String? _activeServiceArea;

  static void subscribeToServiceAreaTopic(String serviceArea,
      {String? userId}) {
    _activeServiceArea = serviceArea;
    if (userId != null) {
      _activeUserId = userId;
    }

    if (kDebugMode) {
      print(
          '🔔 Subscribed to service area: $serviceArea (Targeted ID: $_activeUserId)');
    }

    // Subscribe to Firebase Topic for broadcasts
    final topic = 'area_${serviceArea.toLowerCase().replaceAll(' ', '_')}';
    FirebaseMessaging.instance.subscribeToTopic(topic).then((_) {
      if (kDebugMode) print('🚀 Subscribed to FCM Topic: $topic');
    });

    // Reset/Setup Realtime listener with new filters
    _setupSupabaseRealtimeListener();

    // Register token AFTER barangay is known
    _registerDeviceToken();
  }
}
