import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'pickup_service.dart';
import '../config/supabase_config.dart';

class ReminderService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final fln.FlutterLocalNotificationsPlugin _notifications =
      fln.FlutterLocalNotificationsPlugin();

  Timer? _reminderCheckTimer;
  final List<Map<String, dynamic>> _reminders = [];

  PickupService? _pickupService;
  String? _currentServiceArea;

  final Set<String> _sentReminderKeys = {};
  StreamSubscription<List<Map<String, dynamic>>>? _rescheduleSubscription;
  bool _rescheduleBaselineReady = false;
  final Map<String, int> _rescheduleLastUpdatedSeconds = {};

  List<Map<String, dynamic>> get reminders => List.unmodifiable(_reminders);

  int get unreadCount =>
      _reminders.where((r) => (r['read'] as bool?) != true).length;

  void markAsRead(int id) {
    final index = _reminders.indexWhere((r) => r['id'] == id);
    if (index == -1) return;
    _reminders[index] = {
      ..._reminders[index],
      'read': true,
    };
    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _reminders.length; i++) {
      if ((_reminders[i]['read'] as bool?) == true) continue;
      _reminders[i] = {
        ..._reminders[i],
        'read': true,
      };
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
      _cancelRescheduleSubscription();
      return;
    }

    if (_currentServiceArea != serviceArea) {
      _currentServiceArea = serviceArea;
      _sentReminderKeys.clear();
      _rescheduleBaselineReady = false;
      _rescheduleLastUpdatedSeconds.clear();
      _startRescheduleListener(serviceArea);

      // Run an immediate check once schedules are loaded for this service area.
      scheduleMicrotask(_checkUpcomingCollections);
    }
  }

  Future<void> initialize() async {
    if (kDebugMode) print('🛠️ ReminderService: Initializing...');
    // Initialize local notifications
    const androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = fln.DarwinInitializationSettings();
    const initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // Start periodic check for upcoming collections (every hour)
    _reminderCheckTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkUpcomingCollections(),
    );

    if (kDebugMode) print('🛠️ ReminderService: Initialized and timer started');

    // Also do an initial check on startup.
    scheduleMicrotask(_checkUpcomingCollections);
  }

  void _cancelRescheduleSubscription() {
    _rescheduleSubscription?.cancel();
    _rescheduleSubscription = null;
  }

  void _startRescheduleListener(String serviceArea) {
    _cancelRescheduleSubscription();

    _rescheduleSubscription = _supabase
        .from(SupabaseConfig.collectionSchedulesTable)
        .stream(primaryKey: ['id'])
        .eq('zone', serviceArea)
        .eq('is_rescheduled', true)
        .listen(
          (data) async {
            if (!_rescheduleBaselineReady) {
              for (final doc in data) {
                final updatedAt = doc['updated_at'];
                if (updatedAt is String) {
                  final parsedDate = DateTime.parse(updatedAt);
                  _rescheduleLastUpdatedSeconds[doc['id'].toString()] =
                      parsedDate.millisecondsSinceEpoch ~/ 1000;
                }
              }
              _rescheduleBaselineReady = true;
              return;
            }

            for (final doc in data) {
              final updatedAt = doc['updated_at'];
              final int updatedSeconds = updatedAt is String
                  ? DateTime.parse(updatedAt).millisecondsSinceEpoch ~/ 1000
                  : 0;

              final previousSeconds =
                  _rescheduleLastUpdatedSeconds[doc['id'].toString()];
              if (previousSeconds != null &&
                  previousSeconds == updatedSeconds) {
                continue;
              }

              _rescheduleLastUpdatedSeconds[doc['id'].toString()] =
                  updatedSeconds;

              final rawOriginal = doc['original_date'];
              final rawNew = doc['collection_time'];
              final String reason =
                  (doc['rescheduled_reason'] ?? '').toString();
              final String name =
                  (doc['type'] == null || (doc['type'] as String).isEmpty)
                      ? 'Eco Collection'
                      : doc['type'] as String;

              final DateTime? originalDate =
                  rawOriginal is String ? DateTime.tryParse(rawOriginal) : null;

              final DateTime? newDate =
                  rawNew is String ? DateTime.tryParse(rawNew) : null;

              if (originalDate == null || newDate == null) {
                continue;
              }

              await sendRescheduleNotification(
                collectionName: name,
                originalDate: originalDate,
                newDate: newDate,
                reason: reason.isEmpty ? 'Schedule updated' : reason,
              );
            }
          },
          onError: (e) {
            if (kDebugMode) {
              // ignore: avoid_print
              print('Error listening for reschedules: $e');
            }
            _rescheduleBaselineReady = true;
          },
        );
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
        title: 'Collection Tomorrow!',
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
        title: 'Truck coming soon!',
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

    await _sendReminderNotification(
      serviceArea: serviceArea,
      collectionName: name,
      date: date,
      time: time,
      title: title,
      showPopup: false, // Popups are handled by PickupService scheduling
    );
  }

  Future<void> _sendReminderNotification({
    required String serviceArea,
    required String collectionName,
    required DateTime date,
    required String time,
    String? title,
    bool showPopup = true,
  }) async {
    final displayTitle = title ?? 'Collection Tomorrow!';
    final message =
        '$collectionName scheduled for ${_formatDate(date)} at $time';

    // Check for duplicates in the current list
    final bool alreadyExists = _reminders.any((r) =>
        r['title'] == displayTitle &&
        r['message'] == message &&
        r['type'] == 'info' &&
        _isSameDay(r['createdAt'] as DateTime, DateTime.now()));

    if (alreadyExists) {
      if (kDebugMode) print('Duplicate reminder prevented: $displayTitle');
      return;
    }

    _reminders.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': displayTitle,
      'message': message,
      'type': 'info',
      'read': false,
      'createdAt': DateTime.now(),
      'serviceArea': serviceArea,
    });
    notifyListeners();
  }

  Future<void> sendRescheduleNotification({
    required String collectionName,
    required DateTime originalDate,
    required DateTime newDate,
    required String reason,
  }) async {
    final title = 'Collection Rescheduled';
    final message =
        '$collectionName moved from ${_formatDate(originalDate)} to ${_formatDate(newDate)}. Reason: $reason';

    _reminders.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'message': message,
      'type': 'warning',
      'read': false,
      'createdAt': DateTime.now(),
    });
    notifyListeners();
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// DEBUG: Trigger a test reminder immediately
  Future<void> triggerTestReminder() async {
    final now = DateTime.now();
    await _sendReminderNotification(
      serviceArea: _currentServiceArea ?? 'Test Area',
      collectionName: 'Test Collection',
      date: now,
      time: 'Now',
      title: 'Debug: Test Reminder',
      showPopup: true,
    );
    if (kDebugMode) {
      print('🛠️ DEBUG: Test reminder triggered.');
    }
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _cancelRescheduleSubscription();
    super.dispose();
  }
}

extension on SupabaseStreamBuilder {
  eq(String s, bool bool) {}
}
