import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../routes/app_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../localization/translations.dart';
import '../utils/id_utils.dart';

class NotificationService {
  static SupabaseClient get _supabase => SupabaseConfig.client;
  static RealtimeChannel? _notificationChannel;
  static final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _processedNotificationIds = {};
  static DateTime? _lastProcessedTimestamp;

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
    String baseId = 'unknown';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      baseId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      baseId = iosInfo.identifierForVendor ?? 'unknown_ios';
    }

    return IdUtils.generateUuidFromSeed(baseId);
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

  static Future<void> cancelAllScheduledNotifications() async {
    if (!_isSupportedPlatform) return;
    await _localNotifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    if (!_isSupportedPlatform) return;
    await _localNotifications.cancel(id);
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
        tz_data.initializeTimeZones(); // Initialize timezones
        tz.setLocalLocation(
            tz.getLocation('Asia/Manila')); // Standardize to Ph time
      } catch (e) {
        if (kDebugMode) print('Error initializing timezones: $e');
      }

      // Initialize local notifications immediately (Sync/Fast)
      try {
        const androidSettings =
            fln.AndroidInitializationSettings('@drawable/ic_notification');
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

        // Request permissions and create channel explicitly for Android 13+ (API 33+)
        final androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                fln.AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted =
            await androidImplementation?.requestNotificationsPermission();
        final bool? exactAlarmsGranted =
            await androidImplementation?.requestExactAlarmsPermission();

        if (kDebugMode) {
          print('🔔 [NotificationService] System Permissions:');
          print('   - Notifications: ${granted ?? 'unknown'}');
          print('   - Exact Alarms: ${exactAlarmsGranted ?? 'unknown'}');
        }

        // Explicitly create the high-importance channel for Instant Alerts
        final androidChannel = fln.AndroidNotificationChannel(
          'ecosched_alerts',
          'EcoSched Alerts',
          description: 'Important notifications and schedule updates',
          importance: fln.Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        );

        await androidImplementation?.createNotificationChannel(androidChannel);

        // CRITICAL: Reminders channel for scheduled alarms
        final remindersChannel = fln.AndroidNotificationChannel(
          'ecosched_reminders',
          'EcoSched Reminders',
          description: 'Scheduled reminders for waste collection',
          importance: fln.Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 400, 100, 400]),
        );
        await androidImplementation?.createNotificationChannel(remindersChannel);

        if (kDebugMode) print('🔔 Local notifications initialized');
      } catch (e) {
        if (kDebugMode) print('❌ Error initializing local notifications: $e');
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
    _navigateToDashboard(response.payload ?? '');
  }

  // Handle background notification tap (must be a static method)
  @pragma('vm:entry-point')
  static void _onNotificationTapBackground(fln.NotificationResponse response) {
    // This runs in a separate isolate, so we can't navigate directly.
    if (kDebugMode) {
      print('🔔 Background notification tapped: ${response.payload}');
    }
  }

  static void _navigateToDashboard(String title) {
    // Navigate to dashboard using the global key
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      final titleLower = title.toLowerCase();

      int targetNavIndex = 0;
      if (titleLower.contains('special collection')) {
        targetNavIndex = 3;
      } else if (titleLower.contains('feedback')) {
        targetNavIndex = 1;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.residentDashboard,
        (route) => false,
        arguments: {'initialNavIndex': targetNavIndex},
      );
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
              final data = payload.newRecord;
              final id = data['id']?.toString() ??
                  'unknown_${DateTime.now().millisecondsSinceEpoch}';

              // 🚫 DEDUPLICATION: If we already processed this ID in this session, skip it.
              if (_processedNotificationIds.contains(id)) return;

              // 🚫 FLOOD CONTROL: Ignore "old" notifications that might be re-sent by Supabase
              // upon reconnection if they are more than 2 minutes old.
              final createdAtStr = data['created_at']?.toString();
              if (createdAtStr != null) {
                final createdAt = DateTime.tryParse(createdAtStr);
                if (createdAt != null) {
                  final now = DateTime.now();
                  final diff = now.difference(createdAt).inMinutes.abs();

                  // If we just connected and the message is over 2 min old, it's likely a backlog.
                  if (diff > 2 && _processedNotificationIds.isEmpty) {
                    _processedNotificationIds
                        .add(id); // Mark it as seen so we don't check again
                    return;
                  }
                }
              }

              _processedNotificationIds.add(id);
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
              final data = payload.newRecord;
              final id = data['id']?.toString() ??
                  'unknown_${DateTime.now().millisecondsSinceEpoch}';

              // Same deduplication for personal alerts
              if (_processedNotificationIds.contains(id)) return;
              _processedNotificationIds.add(id);

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

    final rawTitle = data['title']?.toString() ?? 'EcoSched Update';
    final rawBody = data['message']?.toString() ?? 'You have a new notification';

    final title = Translations.getBilingualText(rawTitle);
    final body = Translations.getBilingualText(rawBody);
    final targetUserId = data['user_id']?.toString();

    // 🛡️ SECURITY FILTER: If a user_id is present, but it's NOT ours, ignore it.
    // This prevents "leaks" where one user sees another's (or a collector's) notification.
    if (targetUserId != null && targetUserId != _activeUserId) {
      if (kDebugMode) {
        print(
            '🛡️ [Notification] Ignoring notification targeted to $targetUserId');
      }
      return;
    }

    if (kDebugMode) {
      print('🔔 [Notification] New alert received: $title');
      print('   - Message: $body');

      if (title.contains('Approved') || body.contains('approved')) {
        print(
            '✅ [ACCURACY CHECK] Resident Approval Verified in NotificationService!');
      }
    }

    // Show In-App SnackBar
    final bilingualTitle = Translations.getBilingualText(title);
    final bilingualBody = Translations.getBilingualText(body);
    _showInAppAlert(bilingualTitle, bilingualBody);

    // Also show local notification for better visibility
    showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: title,
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
                _navigateToDashboard(title);
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
    final bilingualTitle = Translations.getBilingualText(title);
    final bilingualBody = Translations.getBilingualText(body);

    if (!_isSupportedPlatform) return;

    try {
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        if (kDebugMode)
          print(
              '⚠️ [Notification] Scheduled skip: $scheduledDate is in the past.');
        return;
      }

      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);

      if (kDebugMode) {
        print('🔔 [Notification] Scheduling alert:');
        print('   - ID: $id');
        print('   - Title: $bilingualTitle');
        print('   - Target: $scheduledTZDate');
      }

      // Try exact alarm first, fall back to inexact if permission is denied
      try {
        if (kDebugMode) print('⏳ [ALARM] Attempting to register EXACT alarm at $scheduledTZDate...');
        await _localNotifications.zonedSchedule(
          id,
          bilingualTitle,
          bilingualBody,
          scheduledTZDate,
          fln.NotificationDetails(
            android: fln.AndroidNotificationDetails(
              'ecosched_reminders',
              'EcoSched Reminders',
              channelDescription: 'Scheduled reminders for waste collection',
              importance: fln.Importance.max,
              priority: fln.Priority.high,
              icon: '@drawable/ic_notification',
              largeIcon: const fln.DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
              playSound: true,
              enableVibration: true,
              fullScreenIntent: true, // Wake up screen
            ),
            iOS: const fln.DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              fln.UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload ?? title,
        );
        if (kDebugMode) print('✅ [ALARM SUCCESS] Exact alarm registered for: $scheduledTZDate (ID: $id)');
      } catch (exactErr) {
        // Exact alarm failed (permission denied) — fall back to inexact so it still fires
        if (kDebugMode) print('⚠️ [ALARM FALLBACK] Exact alarm failed ($exactErr), falling back to inexact...');
        await _localNotifications.zonedSchedule(
          id,
          bilingualTitle,
          bilingualBody,
          scheduledTZDate,
          fln.NotificationDetails(
            android: fln.AndroidNotificationDetails(
              'ecosched_reminders',
              'EcoSched Reminders',
              channelDescription: 'Scheduled reminders for waste collection',
              importance: fln.Importance.max,
              priority: fln.Priority.high,
              icon: '@drawable/ic_notification',
              largeIcon: const fln.DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
              playSound: true,
            ),
            iOS: const fln.DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: fln.AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              fln.UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload ?? title,
        );
        if (kDebugMode) print('✅ [ALARM SUCCESS] Inexact alarm registered for: $scheduledTZDate (ID: $id)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ALARM CRITICAL] Error scheduling notification: $e');
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
    final bilingualTitle = Translations.getBilingualText(title);
    final bilingualBody = Translations.getBilingualText(body);

    if (!_isSupportedPlatform) return;

    if (kDebugMode) {
      print("🔔 [Notification] Triggering IMMEDIATE alert: $title");
      print("🔥 NOTIFICATION TRIGGERED (System Display Requested)");
      if (title.contains('Approved')) {
        print("✅ [ACCURACY CHECK] Approval Local Notification Triggered!");
      }
    }

    try {
      await _localNotifications.show(
        id,
        bilingualTitle,
        bilingualBody,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'ecosched_alerts',
            'EcoSched Alerts',
            channelDescription: 'Important notifications and schedule updates',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@drawable/ic_notification',
            largeIcon: const fln.DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
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

  static Future<void> showLocalNotificationFromRemote(
      RemoteMessage message) async {
    if (!_isSupportedPlatform) return;

    final data = message.data;
    final String title =
        data['title'] ?? message.notification?.title ?? 'EcoSched Update';
    final String body =
        data['body'] ?? message.notification?.body ?? 'You have a new alert';

    // Use the message ID or a consistent hash for deduplication
    final int id = message.messageId.hashCode;

    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: title,
    );
  }
}
