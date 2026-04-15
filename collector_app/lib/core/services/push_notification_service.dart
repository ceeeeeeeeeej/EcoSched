import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PushNotificationService {
  static final _supabase = Supabase.instance.client;
  static final _messaging = FirebaseMessaging.instance;

  /// Registers the device for push notifications and saves the token to Supabase for a collector.
  static Future<void> registerDeviceForPush(String collectorId) async {
    try {
      debugPrint(
          '🔔 [PushNotification] Starting device registration for collector $collectorId...');

      // 1. Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
            '⚠️ [PushNotification] User declined notification permissions.');
        return;
      }

      // 2. Get the Firebase Cloud Messaging (FCM) token
      final String? fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ [PushNotification] Failed to get FCM token.');
        return;
      }

      debugPrint('✅ [PushNotification] FCM Token retrieved: $fcmToken');

      // 3. Get Device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      }

      debugPrint('📱 [PushNotification] Device ID: $deviceId');

      // 4. Update the token in the Supabase 'user_devices' table
      // Note: We use 'resident_id' column as the general user ID link for the edge function
      // We also add a dummy 'barangay' since it might be required by the table structure
      await _supabase.from('user_devices').upsert({
        'device_id': deviceId,
        'fcm_token': fcmToken,
        'resident_id':
            collectorId, // Edge function uses this field to find the token
        'barangay': 'Collector',
      }, onConflict: 'device_id');

      debugPrint(
          '🎉 [PushNotification] Collector device successfully registered!');
    } catch (e, stackTrace) {
      debugPrint('❌ [PushNotification] Error during registration: $e');
      debugPrint('Stacktrace: $stackTrace');
    }
  }
}
