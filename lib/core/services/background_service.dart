import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../firebase_options.dart';
import '../config/supabase_config.dart';
import '../utils/id_utils.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static final supabase = Supabase.instance.client;

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
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase in background
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Background Firebase initialized");
    } catch (e) {
      debugPrint("❌ Error initializing Firebase in background: $e");
    }

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
      if (event != null && event['serviceArea'] != null) {
        final serviceArea = event['serviceArea'] as String;
        debugPrint('🔌 Background Isolate: Connecting for area: $serviceArea');

        await _setupSubscription(
            serviceArea, service, flutterLocalNotificationsPlugin);
      }
    });

    // Cleanup on start if we already have a session in prefs
    final prefs = await SharedPreferences.getInstance();
    final savedServiceArea = prefs.getString('bg_service_area');
    if (savedServiceArea != null) {
      await _setupSubscription(
          savedServiceArea, service, flutterLocalNotificationsPlugin);
    }
  }

  static RealtimeChannel? _personalChannel;
  static RealtimeChannel? _communityChannel;
  static RealtimeChannel? _notificationChannel;

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

  static Future<void> _setupSubscription(
      String serviceArea,
      ServiceInstance service,
      fln.FlutterLocalNotificationsPlugin notifications) async {
    // Register device token for push notifications
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final deviceId = await _getDeviceId();
        await supabase.from('user_devices').upsert({
          'device_id': deviceId,
          'device_token': token,
          'barangay': serviceArea,
        }, onConflict: 'device_id');
        debugPrint(
            "✅ Device token saved to Supabase for $serviceArea (device: $deviceId)");
      }
    } catch (e) {
      debugPrint("❌ Error registering device token: $e");
    }

    if (_personalChannel != null) {
      supabase.removeChannel(_personalChannel!);
    }
    if (_communityChannel != null) {
      supabase.removeChannel(_communityChannel!);
    }
    if (_notificationChannel != null) {
      supabase.removeChannel(_notificationChannel!);
    }

    // Barangay-scoped Notifications (replaces personal user_id channel)
    _personalChannel = supabase
        .channel('bg:notifications:$serviceArea')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'barangay',
            value: serviceArea,
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
            /* 
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
            */
          },
        )
        .subscribe();

    // Community announcements (filtered by target_audience)
    final actualServiceArea = serviceArea;
    _communityChannel = supabase
        .channel('bg:announcements:$serviceArea')
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
            /* 
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
            */
          },
        )
        .subscribe();

    // Barangay-specific Notifications
    _notificationChannel = supabase
        .channel('public:user_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'barangay',
            value: actualServiceArea,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isEmpty) return;

            final title = data['title']?.toString() ?? 'EcoSched';
            final message = data['message']?.toString() ?? 'New notification';

            service.invoke('onNotificationReceived', {
              'title': title,
              'body': message,
              'type': 'barangay_notification',
            });

            /*
            notifications.show(
              DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title,
              message,
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
            */
          },
        )
        .subscribe();
  }

  static void setSession({required String serviceArea}) async {
    final service = FlutterBackgroundService();
    service.invoke('setSession', {
      'serviceArea': serviceArea,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bg_service_area', serviceArea);
  }
}
