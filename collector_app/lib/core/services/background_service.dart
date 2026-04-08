import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Setup local notifications for the background service itself (Android requirement)
    const fln.AndroidNotificationChannel channel =
        fln.AndroidNotificationChannel(
      'ecosched_background_service',
      'EcoSched Background Service',
      description: 'Maintains connection for real-time notifications',
      importance: fln.Importance.low,
    );

    const fln.AndroidNotificationChannel alertChannel =
        fln.AndroidNotificationChannel(
      'ecosched_alerts',
      'EcoSched Alerts',
      description: 'Important notifications and schedule updates',
      importance: fln.Importance.max,
    );

    final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        fln.FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'ecosched_background_service',
        initialNotificationTitle: 'EcoSched is active',
        initialNotificationContent: 'Monitoring for collection updates',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase in this isolate
    await SupabaseConfig.initialize();

    final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        fln.FlutterLocalNotificationsPlugin();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const fln.DarwinInitializationSettings initializationSettingsIOS =
        fln.DarwinInitializationSettings();
    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Listen for session updates from main isolate
    service.on('setSession').listen((event) async {
      if (event != null && event['userId'] != null) {
        final userId = event['userId'] as String;
        final serviceArea = event['serviceArea'] as String?;
        debugPrint(
            '🔌 Background Isolate: Connecting for user $userId (Area: $serviceArea)');
        _setupSubscription(
            userId, serviceArea, service, flutterLocalNotificationsPlugin);
      }
    });

    // Cleanup on start if we already have a session in prefs
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('bg_user_id');
    final savedServiceArea = prefs.getString('bg_service_area');
    if (savedUserId != null) {
      _setupSubscription(savedUserId, savedServiceArea, service,
          flutterLocalNotificationsPlugin);
    }
  }

  static RealtimeChannel? _personalChannel;
  static RealtimeChannel? _communityChannel;

  static void _setupSubscription(
      String userId,
      String? serviceArea,
      ServiceInstance service,
      fln.FlutterLocalNotificationsPlugin notifications) {
    if (_personalChannel != null) {
      SupabaseConfig.client.removeChannel(_personalChannel!);
    }
    if (_communityChannel != null) {
      SupabaseConfig.client.removeChannel(_communityChannel!);
    }

    // Personal Notifications
    _personalChannel = SupabaseConfig.client
        .channel('bg:notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isEmpty) return;

            final title = data['title']?.toString() ?? 'EcoSched Update';
            final body =
                data['message']?.toString() ?? 'You have a new notification';
            final type = data['type']?.toString();

            // Send back to UI if running
            service.invoke('onNotificationReceived', {
              'title': title,
              'body': body,
              'type': type,
            });

            // Show persistent push notification
            notifications.show(
              DateTime.now().millisecond,
              title,
              body,
              const fln.NotificationDetails(
                android: fln.AndroidNotificationDetails(
                  'ecosched_alerts',
                  'EcoSched Alerts',
                  channelDescription:
                      'Important notifications and schedule updates',
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
            );
          },
        )
        .subscribe();

    // Community announcements (filtered by target_audience)
    final actualServiceArea = serviceArea ?? 'all';
    _communityChannel = SupabaseConfig.client
        .channel('bg:announcements:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.announcementsTable,
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isEmpty) return;

            final targetAudience = data['target_audience']?.toString();

            // Filter out announcements not meant for this area
            if (targetAudience != 'all' &&
                targetAudience != actualServiceArea) {
              return;
            }

            final title = data['title']?.toString() ?? 'New Announcement';
            final body = data['content']?.toString() ??
                data['message']?.toString() ??
                'You have a new announcement';

            service.invoke('onNotificationReceived', {
              'title': title,
              'body': body,
              'type': 'announcement',
            });

            // Show persistent push notification
            notifications.show(
              DateTime.now().millisecond,
              title,
              body,
              const fln.NotificationDetails(
                android: fln.AndroidNotificationDetails(
                  'ecosched_alerts',
                  'EcoSched Alerts',
                  channelDescription:
                      'Important notifications and schedule updates',
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
            );
          },
        )
        .subscribe();
  }

  static void setSession(String? userId, {String? serviceArea}) async {
    final service = FlutterBackgroundService();
    if (userId != null) {
      service.invoke('setSession', {
        'userId': userId,
        'serviceArea': serviceArea,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_user_id', userId);
      if (serviceArea != null) {
        await prefs.setString('bg_service_area', serviceArea);
      } else {
        await prefs.remove('bg_service_area');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bg_user_id');
      await prefs.remove('bg_service_area');
    }
  }
}
