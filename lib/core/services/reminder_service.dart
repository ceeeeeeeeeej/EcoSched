import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      _fetchNotifications().then((_) {
        _startNotificationListener();
      });

      if (kDebugMode) {
        print(
            '🛠️ ReminderService: Service area: $serviceArea, UserID: $effectiveUserId');
      }
      
      // Trigger an immediate check for tomorrow's schedules when dependencies update
      scheduleMicrotask(_checkUpcomingCollections);
    }
  }

  void initialize() {
    if (kDebugMode) print('🛠️ ReminderService: Initializing timer...');
    
    // Check every hour to catch mid-day admin changes
    _reminderCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkUpcomingCollections(),
    );

    if (kDebugMode) print('🛠️ ReminderService: Timer started');

    scheduleMicrotask(_checkUpcomingCollections);
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
    
    final serviceArea = _currentServiceArea;
    if (serviceArea == null || serviceArea.isEmpty) return;

    if (kDebugMode) {
      print('📡 Starting Realtime Notifications Listener for Area: $serviceArea');
    }

    _notificationSubscription = _supabase
        .from(SupabaseConfig.notificationsTable)
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          // Filter locally to ensure case-insensitivity and handle targeted alerts
          final hasUpdate = data.any((doc) {
            final docArea = (doc['barangay']?.toString() ?? '').toLowerCase();
            final docUserId = doc['user_id']?.toString();
            
            final isAreaMatch = docArea == serviceArea.toLowerCase() || docArea == 'all';
            final isUserMatch = docUserId == _activeUserId;
            
            return isAreaMatch || isUserMatch;
          });

          if (hasUpdate) {
            if (kDebugMode) print('🔔 Realtime Update: Match found, refreshing list...');
            _fetchNotifications();
          }
        }, onError: (error) {
          if (kDebugMode) print('❌ Realtime Listener Error: $error');
        });
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

    // Check for tomorrow's collections (Only insert after 6:00 PM)
    if (now.hour >= 18) {
      final tomorrowPickups = pickupService.pickupsForDate(tomorrow);
      for (final pickup in tomorrowPickups) {
        await _processPickupReminder(
          pickup: pickup,
          serviceArea: serviceArea,
          title: '🗓️ Collection Tomorrow!',
          typeKey: 'tomorrow',
        );
      }
    }

    // [REMOVED] Check for collections in the next 2 hours (Truck Coming Soon)
    // As per user request, we are removing the 2-hour warning to reduce noise.
    /*
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
    */
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
    
    // Add "Please prepare your garbage" to the tomorrow reminder
    final String body = typeKey == 'tomorrow'
        ? 'Get ready! $name is set for ${_formatDate(date)} at $time. Please prepare your garbage.'
        : 'Get ready! $name is set for ${_formatDate(date)} at $time.';

    // Removed NotificationService.showNotification from here because 
    // PickupService already natively schedules the push notifications 
    // for exact times (including 6 PM day before). ReminderService 
    // will just insert these records into Supabase to populate the Alerts tab.

    // Insert into Supabase so it shows up on the Alert Screen
    try {
      final userId = _activeUserId;
      if (userId != null) {
        // --- DATABASE DEDUPLICATION ---
        // Use a unique key to prevent duplicate rows for the same event
        final dedupKey = 'reminder_${typeKey}_${serviceArea}_${_formatDate(date).replaceAll(' ', '_')}';
        
        final existing = await _supabase
            .from(SupabaseConfig.notificationsTable)
            .select('id')
            .eq('user_id', userId)
            .eq('metadata->>dedup_key', dedupKey)
            .limit(1);

        if (existing.isEmpty) {
          await _supabase.from(SupabaseConfig.notificationsTable).insert({
            'user_id': userId,
            'title': title,
            'message': body,
            'type': 'reminder',
            'priority': typeKey == 'soon' ? 'high' : 'medium',
            'is_read': false,
            'barangay': serviceArea,
            'metadata': {'dedup_key': dedupKey},
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

  /// DEBUG: Trigger a test notification immediately
  Future<void> triggerInstantTest() async {
    const title = '🔔 Instant Test';
    const message = 'Success! Local notifications are working while the app is active.';

    await NotificationService.showNotification(
      id: 999,
      title: title,
      body: message,
    );
    
    _addInternalReminder(title, message, 'info');
  }

  /// DEBUG: Trigger a test notification with a 30 second delay
  Future<void> triggerDelayedTest() async {
    const title = '⏰ 30s Delay Test';
    const message = 'Success! Local notifications worked in the background after 30 seconds.';
    
    final scheduledDate = DateTime.now().add(const Duration(seconds: 30));

    await NotificationService.scheduleNotification(
      id: 888,
      title: title,
      body: message,
      scheduledDate: scheduledDate,
    );
    
    _addInternalReminder('⏰ Delay Test Started', 'Notification scheduled for 30s from now. Please background the app to test.', 'info');
  }

  /// DEBUG: Trigger a test notification with a 10 minute delay
  Future<void> triggerTenMinuteTest() async {
    const title = '🕒 10m Delay Test';
    const message = 'Success! Local notifications worked in the background after 10 minutes.';
    
    final scheduledDate = DateTime.now().add(const Duration(minutes: 10));

    await NotificationService.scheduleNotification(
      id: 777,
      title: title,
      body: message,
      scheduledDate: scheduledDate,
    );
    
    _addInternalReminder('🕒 10m Test Started', 'Notification scheduled for 10 minutes from now. Great for testing deep sleep/Oppo background kills.', 'info');
  }

  void _addInternalReminder(String title, String message, String type) {
    _reminders.insert(0, {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
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
