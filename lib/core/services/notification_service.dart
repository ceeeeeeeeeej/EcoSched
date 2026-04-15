import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import '../localization/translations.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  // Track last scheduled time for each ID to prevent reset loops
  static final Map<int, DateTime> _activeSchedules = {};

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      try {
        final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        if (kDebugMode) print('⚠️ Timezone detection failed, falling back to Manila: $e');
        tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (kDebugMode) print('🔔 Notification tapped: ${details.payload}');
        },
      );

      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        // Create high importance channel
        const channel = AndroidNotificationChannel(
          'ecosched_alerts',
          'EcoSched Alerts',
          description: 'Notifications for waste collection',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin?.createNotificationChannel(channel);
      }

      _initialized = true;
      if (kDebugMode) print('🔔 NotificationService Initialized');
    } catch (e) {
      if (kDebugMode) print('❌ NotificationService Initialization Error: $e');
    }
  }

  /// Request all necessary permissions for Oppo/Android 12+
  static Future<void> requestPermissions() async {
    if (!Platform.isAndroid) return;

    // 1. Notification Permission (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // 2. Exact Alarm (Android 12+)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      final bool? granted = await androidPlugin?.requestExactAlarmsPermission();
      if (kDebugMode) print('⏰ Exact Alarm Permission: $granted');
    } catch (e) {
      if (kDebugMode) print('⏰ Exact Alarm Permission Error: $e');
    }

    // 3. Battery Optimization (Oppo/Xiaomi Crucial)
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _localNotifications.show(
        id,
        Translations.getBilingualText(title),
        Translations.getBilingualText(body),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ecosched_alerts',
            'EcoSched Alerts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error showing notification: $e');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      if (kDebugMode) print('⚠️ Skipping schedule: $scheduledDate is in the past');
      return;
    }

    // --- SCHEDULING GUARD ---
    // If this ID is already scheduled for roughly the same time, don't re-schedule.
    // This prevents the "Timer Reset Loop" on Oppo/Android.
    final existingDate = _activeSchedules[id];
    if (existingDate != null) {
      final difference = existingDate.difference(scheduledDate).abs();
      if (difference.inSeconds < 5) {
        if (kDebugMode) {
          print('ℹ️ Notification ID $id already scheduled for $existingDate. Skipping redundant update.');
        }
        return;
      }
    }
    
    _activeSchedules[id] = scheduledDate;

    try {
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
      
      await _localNotifications.zonedSchedule(
        id,
        Translations.getBilingualText(title),
        Translations.getBilingualText(body),
        scheduledTZDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ecosched_reminders',
            'EcoSched Reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      if (kDebugMode) {
        print('✅ Notification Scheduled: ID $id at $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error scheduling notification: $e');
      
      // Fallback to inexact if exact fails
      try {
        await _localNotifications.zonedSchedule(
          id,
          Translations.getBilingualText(title),
          Translations.getBilingualText(body),
          tz.TZDateTime.from(scheduledDate, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'ecosched_alerts',
              'EcoSched Alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        if (kDebugMode) print('❌ Final scheduling fallback failed: $e2');
      }
    }
  }

  static Future<void> cancelAllScheduledNotifications() async {
    await _localNotifications.cancelAll();
    _activeSchedules.clear();
    if (kDebugMode) print('🧹 All scheduled notifications cancelled');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}
