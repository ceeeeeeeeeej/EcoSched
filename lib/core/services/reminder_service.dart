import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'pickup_service.dart';
import 'notification_service.dart';
import '../config/supabase_config.dart';
import '../localization/translations.dart';

class ReminderService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Timer? _reminderCheckTimer;
  final List<Map<String, dynamic>> _reminders = [];

  PickupService? _pickupService;
  String? _currentServiceArea;
  String? _activeUserId;

  final Set<String> _sentReminderKeys = {};
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _isSyncing = false;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;

  List<Map<String, dynamic>> get reminders => List.unmodifiable(_reminders);

  int get unreadCount =>
      _reminders.where((r) => (r['read'] as bool?) != true).length;

  void markAsRead(dynamic id) {
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;

    _reminders[index] = {
      ..._reminders[index],
      'read': true,
    };
    notifyListeners();

    // Persist to database if it's a persistent notification (UUID)
    if (id is String && id.length > 30) {
      _supabase
          .from(SupabaseConfig.notificationsTable)
          .update({'is_read': true})
          .eq('id', id)
          .then((_) => null);
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _reminders.length; i++) {
      if ((_reminders[i]['read'] as bool?) == true) continue;

      final id = _reminders[i]['id'];
      _reminders[i] = {
        ..._reminders[i],
        'read': true,
      };

      // Persist to database for historical notifications
      if (id is String && id.length > 30) {
        _supabase
            .from(SupabaseConfig.notificationsTable)
            .update({'is_read': true})
            .eq('id', id)
            .then((_) => null);
      }

      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void updateDependencies({
    required AuthService authService,
    required PickupService pickupService,
  }) {
    if (kDebugMode) print('🛠️ ReminderService: updateDependencies called');
    _pickupService = pickupService;

    final dynamic serviceAreaValue = authService.user?['serviceArea'];
    final serviceArea = serviceAreaValue?.toString().trim().toLowerCase();
    if (serviceArea == null || serviceArea.isEmpty) {
      _currentServiceArea = null;
      _cancelNotificationSubscription();
      _reminders.clear();
      notifyListeners();
      return;
    }

    final String? effectiveUserId = authService.isAuthenticated
        ? (authService.user?['uid'] as String?)
        : authService.residentId;

    if (_currentServiceArea != serviceArea ||
        _activeUserId != effectiveUserId) {
      _currentServiceArea = serviceArea;
      _activeUserId = effectiveUserId;
      _sentReminderKeys.clear();

      // 🚀 Await fetch BEFORE starting listener to prevent popups for existing items
      _fetchNotifications().then((_) {
        _startNotificationListener();
      });

      if (kDebugMode) {
        print(
            '🛠️ ReminderService: Service area: $serviceArea, UserID: $effectiveUserId');
      }
    }
  }

  void initialize() {
    _loadOfflineQueue();
    _reminderCheckTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) {
        _checkUpcomingCollections();
        _syncOfflineQueue();
      },
    );

    if (kDebugMode) print('🛠️ ReminderService: Timer started');

    scheduleMicrotask(() {
      _checkUpcomingCollections();
      _syncOfflineQueue();
    });
  }

  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString('ecosched_offline_reminders');
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _offlineQueue.clear();
        _offlineQueue.addAll(decoded.cast<Map<String, dynamic>>());
        if (kDebugMode)
          print('📂 Loaded ${_offlineQueue.length} pending offline reminders');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading offline queue: $e');
    }
  }

  Future<void> _saveOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'ecosched_offline_reminders', jsonEncode(_offlineQueue));
    } catch (e) {
      if (kDebugMode) print('❌ Error saving offline queue: $e');
    }
  }

  Future<void> _syncOfflineQueue() async {
    if (_isSyncing || _offlineQueue.isEmpty) return;
    _isSyncing = true;

    if (kDebugMode)
      print('🔄 Syncing ${_offlineQueue.length} offline reminders...');

    final List<Map<String, dynamic>> toRemove = [];

    try {
      for (final reminder in List.from(_offlineQueue)) {
        try {
          await _supabase
              .from(SupabaseConfig.notificationsTable)
              .insert(reminder);
          toRemove.add(reminder);
          if (kDebugMode) print('✅ Synced offline reminder: ${reminder['title']}');
        } catch (e) {
          // If it's a constraint error (already exists), remove it anyway
          if (e.toString().contains('duplicate key')) {
             toRemove.add(reminder);
          } else {
             if (kDebugMode) print('⚠️ Sync failed for one item, will retry later: $e');
             break; // Stop sync if network is likely still down
          }
        }
      }

      if (toRemove.isNotEmpty) {
        _offlineQueue.removeWhere((item) => toRemove.contains(item));
        await _saveOfflineQueue();
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _cancelNotificationSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    String str = value.toString();
    // If it doesn't have a timezone indicator, assume it's UTC and append 'Z'
    if (!str.contains('Z') && !str.contains('+') && str.contains('T')) {
      str += 'Z';
    }
    // Return local time (Philippine Time)
    return DateTime.tryParse(str)?.toLocal() ?? DateTime.now();
  }

  Future<void> _fetchNotifications() async {
    try {
      final userId = _activeUserId;
      final serviceArea = _currentServiceArea ?? 'all';

      List<Map<String, dynamic>> response = [];
      if (userId != null) {
        // Fetch personal notifications using effective ID (Auth ID or Synthetic UUID)
        response = await _supabase
            .from(SupabaseConfig.notificationsTable)
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(50);
      }

      // Fetch community announcements (broad version)
      final announcementsResponse = await _supabase
          .from(SupabaseConfig.announcementsTable)
          .select()
          .or('target_audience.ilike.$serviceArea,target_audience.eq.all')
          .order('created_at', ascending: false)
          .limit(50);

      // 🔔 Fetch Targeted Barangay Notifications (Step 10)
      final barangayResponse = await _supabase
          .from(SupabaseConfig.notificationsTable)
          .select()
          .eq('barangay', serviceArea) // Main filter
          .order('created_at', ascending: false)
          .limit(50);

      _reminders.clear();
      final Set<String> contentHashes = {};

      void addUniqueNotification(Map<String, dynamic> doc,
          {String type = 'info'}) {
        final id = doc['id'];
        final rawTitle = doc['title']?.toString() ?? 'Notification';
        final rawMessage = (doc['message'] ?? doc['content'])?.toString() ?? '';
        final createdAt = _parseTimestamp(doc['created_at']);

        // --- CONTENT DEDUPLICATION ---
        // Create a hash based on Title, Message, and Date (ignore seconds/millis)
        final dateKey = "${createdAt.year}-${createdAt.month}-${createdAt.day}";
        final contentHash = "${rawTitle.trim()}|${rawMessage.trim()}|$dateKey";

        if (contentHashes.contains(contentHash)) return;
        if (id != null && _reminders.any((r) => r['id'] == id)) return;

        contentHashes.add(contentHash);
        _reminders.add({
          'id': id,
          'title': Translations.getBilingualText(rawTitle),
          'message': Translations.getBilingualText(rawMessage),
          'type': type,
          'read': doc['is_read'] == true,
          'createdAt': createdAt,
        });
      }

      for (final doc in response) {
        final title = doc['title']?.toString() ?? '';
        if (title.toLowerCase().contains('pickup request')) continue;
        addUniqueNotification(doc, type: doc['type']?.toString() ?? 'info');
      }

      for (final doc in announcementsResponse) {
        addUniqueNotification(doc, type: 'announcement');
      }

      for (final doc in barangayResponse) {
        addUniqueNotification(doc, type: doc['type']?.toString() ?? 'alert');
      }

      // Sort combined
      _reminders.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching notifications: $e');
    }
  }

  void _startNotificationListener() {
    _cancelNotificationSubscription();
    final userId = _activeUserId;
    if (userId == null) return;

    _supabase
        .channel('public:notifications:user:$userId')
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
            final doc = payload.newRecord;
            if (doc.isEmpty) return;

            final id = doc['id'];
            final createdAt = _parseTimestamp(doc['created_at']);

            // Only alert for notifications within 5 minutes (handles clock drift between Supabase and Phone)
            final bool isRecent =
                DateTime.now().difference(createdAt).inSeconds.abs() < 300;

            final String rawTitle = doc['title']?.toString() ?? 'Notification';
            final String rawMessage = doc['message']?.toString() ?? '';
            
            // Content deduplication check
            final dateKey = "${createdAt.year}-${createdAt.month}-${createdAt.day}";
            final bool contentExists = _reminders.any((r) {
               final rCreatedAt = r['createdAt'] as DateTime;
               final rDateKey = "${rCreatedAt.year}-${rCreatedAt.month}-${rCreatedAt.day}";
               // Compare against bilingual versions or raw versions
               return r['title'] == Translations.getBilingualText(rawTitle) && 
                      r['message'] == Translations.getBilingualText(rawMessage) && 
                      rDateKey == dateKey;
            });

            if (!_reminders.any((r) => r['id'] == id) && !contentExists) {
              _reminders.insert(0, {
                'id': id,
                'title': Translations.getBilingualText(rawTitle),
                'message': Translations.getBilingualText(rawMessage),
                'type': doc['type']?.toString() ?? 'info',
                'read': doc['is_read'] == true,
                'createdAt': createdAt,
              });

              notifyListeners();

              // Show local notification ONLY for recent high-priority alerts
              if (isRecent && doc['type'] == 'alert') {
                NotificationService.showNotification(
                  id: id.hashCode & 0x7FFFFFFF,
                  title: doc['title'] ?? 'New Alert',
                  body: doc['message'] ?? 'You have a new notification',
                );
              }
            }
          },
        )
        .subscribe();

    // ALSO Listen for targeted Barangay Notifications (Realtime)
    _supabase
        .channel('public:notifications:barangay:$_currentServiceArea')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.notificationsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'barangay',
            value: _currentServiceArea!,
          ),
          callback: (payload) {
            final doc = payload.newRecord;
            if (doc.isNotEmpty) {
              final id = doc['id'];
              final createdAt = _parseTimestamp(doc['created_at']);
              final String rawTitle = doc['title']?.toString() ?? 'Barangay Alert';
              final String rawMessage = doc['message']?.toString() ?? '';

              // Content deduplication check
              final dateKey = "${createdAt.year}-${createdAt.month}-${createdAt.day}";
              final bool contentExists = _reminders.any((r) {
                 final rCreatedAt = r['createdAt'] as DateTime;
                 final rDateKey = "${rCreatedAt.year}-${rCreatedAt.month}-${rCreatedAt.day}";
                 return r['title'] == Translations.getBilingualText(rawTitle) && 
                        r['message'] == Translations.getBilingualText(rawMessage) && 
                        rDateKey == dateKey;
              });

              if (!_reminders.any((r) => r['id'] == id) && !contentExists) {
                _reminders.insert(0, {
                  'id': id,
                  'title': Translations.getBilingualText(rawTitle),
                  'message': Translations.getBilingualText(rawMessage),
                  'type': doc['type']?.toString() ?? 'alert',
                  'read': doc['is_read'] == true,
                  'createdAt': _parseTimestamp(doc['created_at']),
                });

                _reminders.sort((a, b) => (b['createdAt'] as DateTime)
                    .compareTo(a['createdAt'] as DateTime));
                notifyListeners();

                // ✅ In-app feed updated. Push notification is handled
                // centrally by NotificationService's realtime listener.
                // Do NOT call showNotification() here to avoid duplicates.
              }
            }
          },
        )
        .subscribe();

    // Also listen to announcements
    final serviceArea = _currentServiceArea ?? 'all';
    _supabase
        .channel('public:announcements')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: SupabaseConfig.announcementsTable,
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                final targetAudience = newRecord['target_audience'] as String?;
                if (targetAudience == 'all' || targetAudience == serviceArea) {
                  final id = newRecord['id'];
                  final createdAt = _parseTimestamp(newRecord['created_at']);
                  final String rawTitle = newRecord['title']?.toString() ?? 'Announcement';
                  final String rawMessage = (newRecord['content'] ?? newRecord['message'])?.toString() ?? '';

                  // Content deduplication check
                  final dateKey = "${createdAt.year}-${createdAt.month}-${createdAt.day}";
                  final bool contentExists = _reminders.any((r) {
                     final rCreatedAt = r['createdAt'] as DateTime;
                     final rDateKey = "${rCreatedAt.year}-${rCreatedAt.month}-${rCreatedAt.day}";
                     return r['title'] == Translations.getBilingualText(rawTitle) && 
                            r['message'] == Translations.getBilingualText(rawMessage) && 
                            rDateKey == dateKey;
                  });

                  if (!_reminders.any((r) => r['id'] == id) && !contentExists) {
                    _reminders.insert(0, {
                      'id': id,
                      'title': Translations.getBilingualText(rawTitle),
                      'message': Translations.getBilingualText(rawMessage),
                      'type': 'announcement',
                      'read': false,
                      'createdAt': _parseTimestamp(newRecord['created_at']),
                    });

                    // Sort combined
                    _reminders.sort((a, b) => (b['createdAt'] as DateTime)
                        .compareTo(a['createdAt'] as DateTime));
                    notifyListeners();

                    // Show local notification
                    NotificationService.showNotification(
                      id: id.hashCode & 0x7FFFFFFF,
                      title: newRecord['title'] ?? 'New Announcement',
                      body: newRecord['content'] ??
                          newRecord['message'] ??
                          'You have a new announcement',
                    );
                  }
                }
              }
            })
        .subscribe();
  }

  Future<void> _checkUpcomingCollections() async {
    if (kDebugMode) {
      print('🛠️ ReminderService: _checkUpcomingCollections called');
    }
    final now = DateTime.now();
    final inTwoHours = now.add(const Duration(hours: 2));

    final pickupService = _pickupService;
    final serviceArea = _currentServiceArea;
    if (pickupService == null || serviceArea == null || serviceArea.isEmpty) {
      return;
    }

    final allPickups = pickupService.scheduledPickups;

    // Check for tomorrow's collection at 18:00 (6:00 PM) → 📅 Collection Tomorrow
    if (now.hour == 18 && now.minute >= 0 && now.minute <= 3) {
      final tomorrowPickups = allPickups.where((p) {
        final date = p['date'] as DateTime?;
        if (date == null) return false;
        final tomorrow = now.add(const Duration(days: 1));
        return date.year == tomorrow.year &&
            date.month == tomorrow.month &&
            date.day == tomorrow.day;
      }).toList();
      for (final pickup in tomorrowPickups) {
        await _processPickupReminder(
          pickup: pickup,
          serviceArea: serviceArea,
          title: '📅 Collection Tomorrow',
          typeKey: 'day_before',
        );
      }
    }

    // Check for collections in ~1 hour → 🛣️ Put garbage out
    final oneHourPickups = allPickups.where((p) {
      final date = p['date'] as DateTime?;
      return date != null &&
          date.isAfter(now.add(const Duration(minutes: 45))) &&
          date.isBefore(now.add(const Duration(minutes: 75)));
    }).toList();
    for (final pickup in oneHourPickups) {
      await _processPickupReminder(
        pickup: pickup,
        serviceArea: serviceArea,
        title: '🛣️ Put your garbage in designated area',
        typeKey: '1hr',
      );
    }

    // Check for collections happening right now (within next 2 min) → ⏰ Collection Time
    final nowPickups = allPickups.where((p) {
      final date = p['date'] as DateTime?;
      return date != null &&
          date.isAfter(now.subtract(const Duration(minutes: 1))) &&
          date.isBefore(now.add(const Duration(minutes: 2)));
    }).toList();
    for (final pickup in nowPickups) {
      await _processPickupReminder(
        pickup: pickup,
        serviceArea: serviceArea,
        title: '⏰ Collection Time',
        typeKey: 'now',
      );
    }

  }

  Future<void> _processPickupReminder({
    required Map<String, dynamic> pickup,
    required String serviceArea,
    required String title,
    required String typeKey,
  }) async {
    final dynamic rawDate = pickup['date'];
    final DateTime? date = rawDate is DateTime ? rawDate : null;
    if (date == null) return;

    final String name = (pickup['type'] ?? 'Eco Collection').toString();
    final String time = _formatTime((pickup['time'] ?? '08:00').toString());
    final String body =
        'Get ready! $name is set for ${_formatDate(date)} at $time.';
    final String bodyBilingual =
        '$body\n(Andama ang inyong basura! Ang koleksyon sa $name naka-iskedyul sa ${_formatDate(date)} alas $time.)';

    final key =
        '${serviceArea.toLowerCase()}|${date.toIso8601String()}|$name|$typeKey';
    if (_sentReminderKeys.contains(key)) {
      return;
    }
    _sentReminderKeys.add(key);

    // Push notification is handled by the OS alarm scheduled in PickupService.
    // We only insert into Supabase here so it shows on the in-app Alerts screen.

    // Insert into Supabase so it shows up on the Alert Screen
    try {
      final userId = _activeUserId;
      if (userId != null) {
        final Map<String, dynamic> reminderData = {
          'user_id': userId,
          'title': Translations.getBilingualText(title),
          'message': bodyBilingual,
          'type': 'reminder',
          'status': 'unread',
          'created_at': DateTime.now().toIso8601String(),
          'barangay': serviceArea,
        };

        // Add to local feed immediately with temporary ID
        _reminders.insert(0, {
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'title': Translations.getBilingualText(title),
          'message': bodyBilingual,
          'type': 'reminder',
          'read': false,
          'createdAt': DateTime.now(),
        });
        notifyListeners();

        try {
          await _supabase
              .from(SupabaseConfig.notificationsTable)
              .insert(reminderData);
          if (kDebugMode) {
            print(
                '✅ [Database] Reminder Sync Success: "$title" for $serviceArea');
          }
        } catch (dbErr) {
          if (kDebugMode) {
            print('⚠️ [Database] Connection Issue - Queuing for offline sync: $dbErr');
          }
          // --- OFFLINE SYNC LOGIC ---
          _offlineQueue.add(reminderData);
          await _saveOfflineQueue();
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error processing automated reminder: $e');
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  /// Converts a raw time string (e.g. '08:00:00' or '08:00') or date to 12-hour AM/PM format.
  String _formatTime(dynamic rawTime) {
    if (rawTime is DateTime) {
      return DateFormat('h:mm a').format(rawTime);
    }
    
    final timeStr = rawTime.toString();
    try {
      // If it's a full ISO string
      if (timeStr.contains('T') || timeStr.contains('-')) {
        return DateFormat('h:mm a').format(DateTime.parse(timeStr));
      }
      
      // If it's just HH:mm:ss
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '8') ?? 8;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  /// DEBUG: Trigger a test notification immediately
  Future<void> triggerTestNotification() async {
    const title = '🔔 Test Notification';
    const message =
        'Success! Your device is correctly set up to receive EcoSched alerts.';

    // 1. Show local system notification
    await NotificationService.showNotification(
      id: 999,
      title: title,
      body: message,
    );

    // 2. Add to in-app list
    _reminders.insert(0, {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': 'info',
      'read': false,
      'createdAt': DateTime.now(),
    });

    notifyListeners();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _cancelNotificationSubscription();
    super.dispose();
  }
}
