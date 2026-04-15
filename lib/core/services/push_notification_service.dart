import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../utils/id_utils.dart';

import 'notification_service.dart';

class PushNotificationService {
  static final _supabase = Supabase.instance.client;
  static final _messaging = FirebaseMessaging.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINTS
  // ─────────────────────────────────────────────────────────────────────────

  /// Call once on app boot (after Firebase + Supabase init).
  /// Requests permission, gets/saves the token, and sets up refresh listener.
  static Future<void> registerDeviceForPush() async {
    try {
      debugPrint('🔔 [PushNotification] Starting device registration...');

      // 1. Request notification permissions (required iOS, good practice Android 13+)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        debugPrint('⚠️ [PushNotification] User declined notification permissions.');
        return;
      }

      // 2. Get the FCM token
      final String? fcmToken = await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ [PushNotification] Failed to get FCM token.');
        return;
      }

      debugPrint('✅ [PushNotification] FCM Token: $fcmToken');

      // 3. Cache the token locally for fast access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_fcm_token', fcmToken);

      // 4. Get the device ID (used for user_devices table)
      final String deviceId = await _getOrCreateDeviceId(prefs);

      // 5. Get and Normalize barangay
      String barangay = prefs.getString('resident_barangay') ?? 'unknown';
      if (barangay.toLowerCase().contains('victoria')) barangay = 'Victoria';
      if (barangay.toLowerCase().contains('dayo-an')) barangay = 'Dayo-an';

      // 6. Save to user_devices (always — even for anonymous users)
      await _saveToUserDevices(
        fcmToken: fcmToken,
        deviceId: deviceId,
        barangay: barangay,
      );

      // 7. Save to users table if a user is currently logged in
      await _saveToUsersTable(fcmToken);

      // 8. Set up listeners (runs for the lifetime of the app)
      _setupTokenRefreshListener();
      _setupForegroundMessageListener();

      debugPrint('🎉 [PushNotification] Device registration complete!');
    } catch (e, stackTrace) {
      debugPrint('❌ [PushNotification] Error during registration: $e');
      debugPrint('Stacktrace: $stackTrace');
    }
  }

  /// Call this immediately AFTER a user logs in / signs up.
  /// Picks the cached token (no extra FCM round-trip) and writes it to
  /// the `users` row for that user.
  static Future<void> saveFcmTokenForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to use the cached token; fall back to a fresh FCM fetch.
      String? fcmToken = prefs.getString('cached_fcm_token');
      fcmToken ??= await _messaging.getToken();

      if (fcmToken == null) {
        debugPrint('❌ [PushNotification] No FCM token available for user save.');
        return;
      }

      await _saveToUsersTable(fcmToken);
    } catch (e) {
      debugPrint('❌ [PushNotification] saveFcmTokenForCurrentUser error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Listens for Firebase token rotation and keeps Supabase up-to-date.
  static void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 [PushNotification] Token refreshed: $newToken');

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_fcm_token', newToken);

        final String deviceId = await _getOrCreateDeviceId(prefs);
        final String barangay =
            prefs.getString('resident_barangay') ?? 'unknown';

        await _saveToUserDevices(
          fcmToken: newToken,
          deviceId: deviceId,
          barangay: barangay,
        );

        await _saveToUsersTable(newToken);
      } catch (e) {
        debugPrint('❌ [PushNotification] Token refresh save error: $e');
      }
    });
  }

  /// Listens for messages that arrive while the app is in the foreground
  /// and manually triggers a local notification popup.
  static void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 [PushNotification] Foreground message received: ${message.messageId}');
      
      final notification = message.notification;
      if (notification != null) {
        // Trigger a local notification popup since Android doesn't show them 
        // automatically when the app is in the foreground.
        NotificationService.showNotification(
          id: message.hashCode,
          title: notification.title ?? 'EcoSched Alert',
          body: notification.body ?? 'New notification received',
          payload: message.data.toString(),
        );
      }
    });
  }

  /// Saves the FCM token to the `user_devices` table.
  /// Uses upsert on `device_id` to prevent duplicates.
  static Future<void> _saveToUserDevices({
    required String fcmToken,
    required String deviceId,
    required String barangay,
  }) async {
    try {
      await _supabase.from('user_devices').upsert({
        'device_id': deviceId,
        'resident_id': deviceId,
        'fcm_token': fcmToken,
        'barangay': barangay,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');

      debugPrint('✅ [PushNotification] Saved token to user_devices.');
    } catch (e) {
      debugPrint('❌ [PushNotification] user_devices save error: $e');
    }
  }

  /// Saves the FCM token to the `users` table for the currently logged-in user.
  /// Does nothing if no user session exists.
  static Future<void> _saveToUsersTable(String fcmToken) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        debugPrint('ℹ️ [PushNotification] No authenticated user — skipping users table update.');
        return;
      }

      await _supabase
          .from('users')
          .update({'fcm_token': fcmToken})
          .eq('id', user.id);

      debugPrint('✅ [PushNotification] Saved token to users table for ${user.id}');
    } catch (e) {
      debugPrint('❌ [PushNotification] users table save error: $e');
    }
  }

  /// Returns a stable synthetic UUID derived from the physical device ID.
  /// Persists the result in SharedPreferences so it survives app restarts.
  static Future<String> _getOrCreateDeviceId(SharedPreferences prefs) async {
    String? deviceId = prefs.getString('resident_user_id');
    if (deviceId != null) return deviceId;

    final deviceInfo = DeviceInfoPlugin();
    String baseId = 'unknown';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      baseId = info.id;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      baseId = info.identifierForVendor ?? 'unknown_ios';
    }

    deviceId = IdUtils.generateUuidFromSeed(baseId);
    await prefs.setString('resident_user_id', deviceId);
    await prefs.remove('unique_device_id'); // clean up old key
    return deviceId;
  }
}
