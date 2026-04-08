import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:collector_app/core/services/auth_service.dart';
import '../config/supabase_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../routes/app_router.dart';
import 'package:collector_app/core/routes/app_routes.dart';
import '../localization/translations.dart';

class NotificationService {
  static final SupabaseClient _supabase = SupabaseConfig.client;
  static RealtimeChannel? _notificationChannel;
  static final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RemoteMessage? _launchedFromMessage;

  static void setLaunchedFromMessage(RemoteMessage message) {
    _launchedFromMessage = message;
  }

  static void handleFcmClick(RemoteMessage message) {
    _navigateToDashboard(message: message);
  }

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

  static StreamSubscription<AuthState>? _authSubscription;

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

        // Request permissions and create channel explicitly for Android 13+ (API 33+)
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidImplementation =
              _localNotifications.resolvePlatformSpecificImplementation<
                  fln.AndroidFlutterLocalNotificationsPlugin>();
          
          await androidImplementation?.requestNotificationsPermission();

          // Explicitly create the high-importance channel
          const androidChannel = fln.AndroidNotificationChannel(
            'ecosched_alerts',
            'EcoSched Alerts',
            description: 'Important notifications and schedule updates',
            importance: fln.Importance.max,
            playSound: true,
            enableVibration: true,
          );
          
          await androidImplementation?.createNotificationChannel(androidChannel);
        }

        if (kDebugMode) print('🔔 Local notifications initialized');
      } catch (e) {
        if (kDebugMode) print('Error initializing local notifications: $e');
      }

      // Initialize Auth Listener instead of direct Realtime listener
      _setupAuthListener();
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

  static void _navigateToDashboard({RemoteMessage? message}) {
    // If we have a launched message but no message passed, use it
    final targetMessage = message ?? _launchedFromMessage;
    if (targetMessage != null) {
      _launchedFromMessage = null; // Clear it so it doesn't trigger again
      if (kDebugMode) print('🔔 Handling Navigation for FCM: ${targetMessage.messageId}');
    }

    // Navigate to dashboard using the GlobalKey and AuthService
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      if (auth.isAuthCheckComplete && auth.isAuthenticated) {
        auth.goHome(context);
      } else {
        // If auth not ready, go to splash which will handle the redirect
        Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.splash, (route) => false);
      }
    }
  }

  static void _setupAuthListener() {
    _authSubscription?.cancel();

    // Check current session immediately (Safeguard)
    final initialSession = SupabaseConfig.client.auth.currentSession;
    if (initialSession != null) {
      if (kDebugMode) {
        print('🔐 Existing session found for: ${initialSession.user.id}');
      }
      _setupSupabaseRealtimeListener(initialSession.user.id);
    }

    _authSubscription =
        SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (kDebugMode) {
        print('🔐 Auth Event: $event, User: ${session?.user.id}');
      }

      if (session != null) {
        // User is logged in, setup listener
        _setupSupabaseRealtimeListener(session.user.id);
      } else {
        // User logged out, remove listener
        _unsubscribeRealtimeListener();
      }
    });
  }

  static void _unsubscribeRealtimeListener() {
    if (_notificationChannel != null) {
      if (kDebugMode) print('🔌 Unsubscribing from Realtime Notifications...');
      _supabase.removeChannel(_notificationChannel!);
      _notificationChannel = null;
    }
  }

  static void _setupSupabaseRealtimeListener(String userId) {
    if (_notificationChannel != null) return; // Already subscribed

    try {
      if (kDebugMode) {
        print(
            '🔌 Setting up Supabase Realtime Notifications for user: $userId...');
      }

      _notificationChannel = _supabase
          .channel(
              'user_notifications:$userId') // Unique channel per user session
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.notificationsTable,
            callback: (payload) {
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
              final recipientId = data['user_id']?.toString();

              if (kDebugMode) {
                print('   - Processing: $title');
                print('   - Recipient: $recipientId (Current: $userId)');
              }

              // Double check recipient (though filter should handle it)
              if (recipientId != userId) {
                if (kDebugMode) {
                  print('⚠️ Notification for wrong user ignored.');
                }
                return;
              }

              // ONLY show In-App SnackBar if app is active in the main isolate
              // BackgroundService handles the persistent system notification
              final bilingualTitle = Translations.getBilingualText(title);
              final bilingualBody = Translations.getBilingualText(body);
              _showInAppAlert(bilingualTitle, bilingualBody);
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
                final auth = Provider.of<AuthService>(context, listen: false);
                auth.goHome(context);
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

      final bilingualTitle = Translations.getBilingualText(title);
      final bilingualBody = Translations.getBilingualText(body);

      await _localNotifications.zonedSchedule(
        id,
        bilingualTitle,
        bilingualBody,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'ecosched_reminders',
            'EcoSched Reminders',
            channelDescription: 'Scheduled collection reminders',
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
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            fln.UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      if (kDebugMode) {
        print('🔔 NOTIFICATION SCHEDULED:');
        print('   - ID: $id');
        print('   - Title: $bilingualTitle');
        print('   - Time: $scheduledDate');
        print('   - Payload: $payload');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling notification: $e');
      }
    }
  }

  static Future<void> cancelValidation(int id) async {
    await _localNotifications.cancel(id);
  }

  static Future<void> clearAllNotifications() async {
    if (!_isSupportedPlatform) return;
    try {
      await _localNotifications.cancelAll();
      if (kDebugMode) print('🔔 All local notifications cleared');
    } catch (e) {
      if (kDebugMode) print('Error clearing notifications: $e');
    }
  }

  static Future<void> subscribeToServiceAreaTopic(String serviceArea) async {
    if (kDebugMode) {
      print('📍 Subscribed to Service Area: $serviceArea (Realtime)');
    }
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

    try {
      await _localNotifications.show(
        id,
        bilingualTitle,
        bilingualBody,
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
      if (kDebugMode) print('Error showing notification: $e');
    }
  }
}
