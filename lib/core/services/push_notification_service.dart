import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/id_utils.dart';

class PushNotificationService {
  static final _supabase = Supabase.instance.client;
  static final _messaging = FirebaseMessaging.instance;

  /// Registers the device for push notifications and saves the token to Supabase.
  static Future<void> registerDeviceForPush() async {
    try {
      debugPrint('🔔 [PushNotification] Starting device registration...');

      // 1. Request notification permissions (Required for iOS, good practice for Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint(
            '⚠️ [PushNotification] User declined notification permissions.');
        return; // Exit early if permission is denied
      }

      // 2. Get the Firebase Cloud Messaging (FCM) token
      final String? fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ [PushNotification] Failed to get FCM token.');
        return;
      }

      debugPrint('✅ [PushNotification] FCM Token retrieved: $fcmToken');

      // 3. Get the resident ID (synthetic UUID derived from device ID)
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString("resident_user_id");

      if (deviceId == null) {
        final deviceInfo = DeviceInfoPlugin();
        String baseId = 'unknown';

        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          baseId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          baseId = iosInfo.identifierForVendor ?? 'unknown_ios';
        }

        // Generate consistent synthetic UUID from the base device ID
        deviceId = IdUtils.generateUuidFromSeed(baseId);
        await prefs.setString("resident_user_id", deviceId);

        // Cleanup old key if it exists
        await prefs.remove("unique_device_id");
      }

      debugPrint('📱 [PushNotification] Device ID: $deviceId');

      // 4. Retrieve the user's barangay (assuming it's saved locally)
      final String barangay = prefs.getString("resident_barangay") ??
          "Mahayag"; // Default to Mahayag if none found

      debugPrint('📍 [PushNotification] User Barangay: $barangay');

      // 5. Save/Update the token in the Supabase 'user_devices' table
      // Using .upsert() prevents duplicates. It updates the row if the device_id already exists.
      final String? residentId = prefs.getString("resident_user_id") ??
          prefs.getString("unique_device_id");

      await _supabase.from('user_devices').upsert({
        'fcm_token': fcmToken,
        'barangay': barangay,
        'device_id': deviceId,
        if (residentId != null) 'resident_id': residentId,
      }, onConflict: 'device_id');

      debugPrint(
          '🎉 [PushNotification] Device successfully registered in Supabase!');
    } catch (e, stackTrace) {
      // 6. Error Handling
      debugPrint('❌ [PushNotification] Error during registration: $e');
      debugPrint('Stacktrace: $stackTrace');
    }
  }
}
