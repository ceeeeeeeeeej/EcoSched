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
    // _pickupService = pickupService; // Local collection check logic disabled

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

    if (kDebugMode) print('🛠️ ReminderService: Initialized');
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
              print('Error listening for reschedules: $e');
            }
            _rescheduleBaselineReady = true;
          },
        );
  }

  Future<void> sendRescheduleNotification({
    required String collectionName,
    required DateTime originalDate,
    required DateTime newDate,
    required String reason,
  }) async {
    const title = 'Collection Rescheduled';
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

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _cancelRescheduleSubscription();
    super.dispose();
  }
}
