import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'pickup_service.dart';
import 'notification_service.dart';
import '../config/supabase_config.dart';

class ReminderService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Timer? _reminderCheckTimer;
  final List<Map<String, dynamic>> _reminders = [];

  PickupService? _pickupService;
  String? _currentServiceArea;
  String? _activeUserId;

  final Set<String> _sentReminderKeys = {};
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
    final serviceArea = serviceAreaValue?.toString().trim();
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
      _fetchNotifications();
      _startNotificationListener();

      if (kDebugMode) {
        print(
            '🛠️ ReminderService: Service area: $serviceArea, UserID: $effectiveUserId');
      }

      // Run an immediate check once schedules are loaded for this service area.
      scheduleMicrotask(_checkUpcomingCollections);
    }
  }

  void initialize() {
    if (kDebugMode) print('🛠️ ReminderService: Initializing timer...');
    // Start periodic check for upcoming collections (every hour)
    _reminderCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkUpcomingCollections(),
    );

    if (kDebugMode) print('🛠️ ReminderService: Timer started');

    // Also do an initial check on startup.
    scheduleMicrotask(_checkUpcomingCollections);
  }

  void _cancelNotificationSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
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
          .or('target_audience.eq.$serviceArea,target_audience.eq.all')
          .order('created_at', ascending: false)
          .limit(50);

      // 🔔 Fetch Targeted Barangay Notifications (Step 10)
      final barangayResponse = await _supabase
          .from(SupabaseConfig.notificationsTable)
          .select()
          .eq('barangay', serviceArea)
          .order('created_at', ascending: false)
          .limit(50);

      _reminders.clear();
      for (final doc in response) {
        String? createdAtStr = doc['created_at']?.toString();
        if (createdAtStr != null &&
            !createdAtStr.contains('Z') &&
            !createdAtStr.contains('+')) {
          createdAtStr += 'Z';
        }

        _reminders.add({
          'id': doc['id'],
          'title': doc['title']?.toString() ?? 'Notification',
          'message': doc['message']?.toString() ?? '',
          'type': doc['type']?.toString() ?? 'info',
          'read': doc['is_read'] == true,
          'createdAt': createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now(),
        });
      }

      for (final doc in announcementsResponse) {
        String? createdAtStr = doc['created_at']?.toString();
        if (createdAtStr != null &&
            !createdAtStr.contains('Z') &&
            !createdAtStr.contains('+')) {
          createdAtStr += 'Z';
        }

        _reminders.add({
          'id': doc['id'],
          'title': doc['title']?.toString() ?? 'Announcement',
          'message': (doc['content'] ?? doc['message'])?.toString() ?? '',
          'type': 'announcement',
          'read': false,
          'createdAt': createdAtStr != null
              ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
              : DateTime.now(),
        });
      }

      for (final doc in barangayResponse) {
        final id = doc['id'];
        if (id != null && !_reminders.any((r) => r['id'] == id)) {
          String? createdAtStr = doc['created_at']?.toString();
          if (createdAtStr != null &&
              !createdAtStr.contains('Z') &&
              !createdAtStr.contains('+')) {
            createdAtStr += 'Z';
          }

          _reminders.add({
            'id': id,
            'title': doc['title']?.toString() ?? 'Barangay Alert',
            'message': doc['message']?.toString() ?? '',
            'type': doc['type']?.toString() ?? 'alert',
            'read': doc['is_read'] == true,
            'createdAt': createdAtStr != null
                ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                : DateTime.now(),
          });
        }
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
    if (userId != null) {
      _notificationSubscription = _supabase
          .from(SupabaseConfig.notificationsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (data) {
              bool changed = false;
              for (final doc in data) {
                final id = doc['id'];
                final exists = _reminders.any((r) => r['id'] == id);

                if (!exists) {
                  String? createdAtStr = doc['created_at']?.toString();
                  if (createdAtStr != null &&
                      !createdAtStr.contains('Z') &&
                      !createdAtStr.contains('+')) {
                    createdAtStr += 'Z';
                  }

                  final createdAt = createdAtStr != null
                      ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                      : DateTime.now();

                  _reminders.insert(0, {
                    'id': id,
                    'title': doc['title']?.toString() ?? 'Notification',
                    'message': doc['message']?.toString() ?? '',
                    'type': doc['type']?.toString() ?? 'info',
                    'read': doc['is_read'] == true,
                    'createdAt': createdAt,
                  });
                  changed = true;

                  // Show local notification for new alerts (e.g. Rescheduled)
                  if (doc['type'] == 'alert' &&
                      (doc['is_read'] == null || doc['is_read'] == false) &&
                      DateTime.now().difference(createdAt).inMinutes < 5) {
                    NotificationService.showNotification(
                      id: id.hashCode & 0x7FFFFFFF,
                      title: doc['title'] ?? 'New Alert',
                      body: doc['message'] ?? 'You have a new notification',
                    );
                  }
                }
              }

              if (changed) {
                _reminders.sort((a, b) => (b['createdAt'] as DateTime)
                    .compareTo(a['createdAt'] as DateTime));
                notifyListeners();
              }
            },
            onError: (e) {
              if (kDebugMode) print('❌ Error listening to notifications: $e');
            },
          );
    }

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
              if (!_reminders.any((r) => r['id'] == id)) {
                String? createdAtStr = doc['created_at']?.toString();
                if (createdAtStr != null &&
                    !createdAtStr.contains('Z') &&
                    !createdAtStr.contains('+')) {
                  createdAtStr += 'Z';
                }

                _reminders.insert(0, {
                  'id': id,
                  'title': doc['title']?.toString() ?? 'Barangay Alert',
                  'message': doc['message']?.toString() ?? '',
                  'type': doc['type']?.toString() ?? 'alert',
                  'read': doc['is_read'] == true,
                  'createdAt': createdAtStr != null
                      ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                      : DateTime.now(),
                });

                _reminders.sort((a, b) => (b['createdAt'] as DateTime)
                    .compareTo(a['createdAt'] as DateTime));
                notifyListeners();

                // Show local notification
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
                  final exists = _reminders.any((r) => r['id'] == id);

                  if (!exists) {
                    String? createdAtStr = newRecord['created_at']?.toString();
                    if (createdAtStr != null && !createdAtStr.endsWith('Z'))
                      createdAtStr += 'Z';

                    _reminders.insert(0, {
                      'id': id,
                      'title': newRecord['title']?.toString() ?? 'Announcement',
                      'message': (newRecord['content'] ?? newRecord['message'])
                              ?.toString() ??
                          '',
                      'type': 'announcement',
                      'read': false,
                      'createdAt': createdAtStr != null
                          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
                          : DateTime.now(),
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
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final inTwoHours = now.add(const Duration(hours: 2));

    final pickupService = _pickupService;
    final serviceArea = _currentServiceArea;
    if (pickupService == null || serviceArea == null || serviceArea.isEmpty) {
      if (kDebugMode) {
        print('🛠️ ReminderService: Missing dependencies or service area');
        print('   - PickupService null: ${pickupService == null}');
        print('   - Service Area: $serviceArea');
      }
      return;
    }

    // Check for tomorrow's collections
    final tomorrowPickups = pickupService.pickupsForDate(tomorrow);
    for (final pickup in tomorrowPickups) {
      await _processPickupReminder(
        pickup: pickup,
        serviceArea: serviceArea,
        title: '🗓️ Collection Tomorrow!',
        typeKey: 'tomorrow',
      );
    }

    // Check for collections in the next 2 hours
    final allPickups = pickupService.scheduledPickups;
    final soonPickups = allPickups.where((p) {
      final date = p['date'] as DateTime?;
      return date != null && date.isAfter(now) && date.isBefore(inTwoHours);
    }).toList();

    for (final pickup in soonPickups) {
      await _processPickupReminder(
        pickup: pickup,
        serviceArea: serviceArea,
        title: '🚛 Truck Coming Soon!',
        typeKey: 'soon',
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
    final String time = (pickup['time'] ?? '08:00').toString();

    final key =
        '${serviceArea.toLowerCase()}|${date.toIso8601String()}|$name|$typeKey';
    if (_sentReminderKeys.contains(key)) {
      return;
    }
    _sentReminderKeys.add(key);

    // Generate notification content
    final String title = typeKey == 'soon'
        ? '🚛 Truck Coming Soon!'
        : '🗓️ Collection Tomorrow!';
    final String body =
        'Get ready! $name is set for ${_formatDate(date)} at $time.';

    // Show local push notification
    if (typeKey == 'soon' || typeKey == 'tomorrow') {
      await NotificationService.showNotification(
        id: (date.millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF,
        title: title,
        body: body,
      );
    }

    // Insert into Supabase so it shows up on the Alert Screen
    try {
      final userId = _activeUserId;
      if (userId != null) {
        // Check if a similar notification already exists to prevent spam
        final existing = _reminders.any((r) =>
            r['title'] == title &&
            r['message'] == body &&
            r['type'] == 'reminder');

        if (!existing) {
          await _supabase.from(SupabaseConfig.notificationsTable).insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'type': 'reminder',
            'priority': typeKey == 'soon' ? 'high' : 'medium',
            'is_read': false,
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error inserting automated reminder: $e');
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

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _cancelNotificationSubscription();
    super.dispose();
  }
}
