import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecosched/core/services/notification_service.dart';
import '../config/supabase_config.dart';

class PickupService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final List<Map<String, dynamic>> _scheduledPickups = [];
  final Map<String, List<Map<String, dynamic>>> _fixedSchedules = {};
  final Set<String> _notifiedOnTheWayIds = {};
  final Set<String> _notifiedRescheduledIds = {};
  List<Map<String, dynamic>> _lastStreamedSchedules = [];
  bool _isLastCollector = false;

  List<Map<String, dynamic>> get scheduledPickups =>
      List.unmodifiable(_scheduledPickups);

  /// Returns a set of normalized dates (midnight) that have scheduled pickups.
  Set<DateTime> get scheduledDates => _scheduledPickups
      .map<DateTime>((pickup) => _normalizeDate(pickup['date'] as DateTime))
      .toSet();

  /// Helper used by calendar views to highlight days with a schedule.
  bool hasPickupOn(DateTime date) {
    final normalized = _normalizeDate(date);
    return scheduledDates.contains(normalized);
  }

  Map<String, dynamic>? _defaultFixedSchedule(String serviceAreaKey) {
    if (serviceAreaKey == 'victoria') {
      return {
        'area': 'victoria',
        'scheduleName': 'Victoria Eco Collection',
        'days': ['monday', 'tuesday'],
        'time': '08:00',
        'active': true,
      };
    }

    if (serviceAreaKey == 'dayo-an') {
      return {
        'area': 'dayo-an',
        'scheduleName': 'Dayo-an Eco Collection',
        'days': ['saturday'],
        'time': '08:00',
        'active': true,
      };
    }

    if (serviceAreaKey == 'mahayag') {
      return {
        'area': 'mahayag',
        'scheduleName': 'Mahayag Waste Collection',
        'days': [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ],
        'time': '08:00',
        'active': true,
      };
    }

    if (serviceAreaKey == 'visitors') {
      return {
        'area': 'visitors',
        'scheduleName': 'General Information',
        'days': [],
        'time': '--:--',
        'active': false,
      };
    }

    return null;
  }

  /// Retrieves all pickups assigned on the provided day.
  List<Map<String, dynamic>> pickupsForDate(DateTime date) {
    final normalized = _normalizeDate(date);
    return _scheduledPickups
        .where((pickup) =>
            _normalizeDate(pickup['date'] as DateTime) == normalized)
        .toList(growable: false);
  }

  /// Retrieves all future pickups (after today).
  List<Map<String, dynamic>> get upcomingPickups {
    final today = _normalizeDate(DateTime.now());
    return _scheduledPickups
        .where((pickup) =>
            _normalizeDate(pickup['date'] as DateTime).isAfter(today))
        .toList(growable: false);
  }

  Map<String, dynamic>? getNextCollection(String serviceArea) {
    final now = DateTime.now();
    final upcoming = _scheduledPickups.where((pickup) {
      final pickupArea = (pickup['address'] ?? '').toString().toLowerCase();
      final targetArea = serviceArea.toLowerCase();
      final pickupDate = pickup['date'] as DateTime;

      // Match area AND ensure it's in the future
      return (pickupArea.contains(targetArea) ||
              targetArea.contains(pickupArea)) &&
          pickupDate.isAfter(now);
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return upcoming.first;
  }

  StreamSubscription<List<Map<String, dynamic>>>? _scheduleSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _fixedScheduleSubscription;
  String? _currentServiceArea;

  Future<void> loadSchedulesForServiceArea(String serviceArea,
      {bool isCollector = false, bool forceReload = false}) async {
    final normalizedArea = serviceArea.trim().toLowerCase();

    if (!forceReload &&
        _currentServiceArea == normalizedArea &&
        _scheduleSubscription != null) {
      return;
    }

    await _scheduleSubscription?.cancel();
    await _fixedScheduleSubscription?.cancel();
    _currentServiceArea = normalizedArea;
    _isLastCollector = isCollector;

    // Clear stale data when switching areas
    _lastStreamedSchedules.clear();
    _scheduledPickups.clear();
    _notifiedOnTheWayIds.clear();
    _notifiedRescheduledIds.clear();
    notifyListeners();

    // Load fixed schedules first
    await _loadFixedSchedules();

    // Then load regular schedules
    _scheduleSubscription = _supabase
        .from(SupabaseConfig.collectionSchedulesTable)
        .stream(primaryKey: ['id'])
        .eq('zone',
            _currentServiceArea!) // Should match lowercase in DB if standardized
        .listen(
          (data) {
            if (kDebugMode) {
              print(
                  '📡 PickupService: Received ${data.length} schedules for $_currentServiceArea');
              if (data.isNotEmpty) {
                print('   - Sample zone in DB: ${data.first['zone']}');
                print(
                    '   - Sample scheduled_date: ${data.first['scheduled_date']}');
              }
            }
            _lastStreamedSchedules = data
                .map((doc) => _mapScheduleDoc(doc['id'].toString(), doc))
                .toList();

            _rebuildScheduledPickups(isCollector: isCollector);
          },
          onError: (e) {
            if (kDebugMode) {
              print('Failed to load schedules for $serviceArea: $e');
            }
          },
        );
  }

  Future<void> _loadFixedSchedules() async {
    _fixedScheduleSubscription = _supabase
        .from(SupabaseConfig.areaSchedulesTable)
        .stream(primaryKey: ['id']).listen(
      (data) {
        for (final doc in data) {
          final area = (doc['area'] ?? '').toString().toLowerCase();
          if (area.isNotEmpty) {
            final schedule = {
              'id': doc['id'],
              'area': doc['area'],
              'scheduleName': doc['schedule_name'],
              'days': doc['days'],
              'time': doc['time'],
              'active': doc['is_active'],
            };

            if (!_fixedSchedules.containsKey(area)) {
              _fixedSchedules[area] = [];
            }
            _fixedSchedules[area]!.add(schedule);
          }
        }
        _rebuildScheduledPickups(isCollector: _isLastCollector);
      },
      onError: (e) {
        if (kDebugMode) {
          print('Failed to load fixed schedules: $e');
        }
        // Even on error, rebuild to allow default/fallback schedules to show
        _rebuildScheduledPickups();
      },
    );
  }

  void _rebuildScheduledPickups({bool? isCollector}) {
    if (_currentServiceArea == null) return;

    final actualIsCollector = isCollector ?? _isLastCollector;
    final Map<String, Map<String, dynamic>> itemsMap = {};

    // 1. Add streamed schedules (highest priority)
    for (final doc in _lastStreamedSchedules) {
      final id = doc['id']?.toString() ?? 'unknown';
      itemsMap[id] = doc;
    }

    final excludedDates = <DateTime>{};
    for (final item in itemsMap.values) {
      final dynamic scheduled = item['date'];
      if (scheduled is DateTime) {
        excludedDates.add(_normalizeDate(scheduled));
      }

      final dynamic isRescheduled = item['isRescheduled'] == true;
      final dynamic original = item['originalDate'];
      if (isRescheduled && original is DateTime) {
        excludedDates.add(_normalizeDate(original));
      }
    }

    // 2. Add generated schedules from fixed schedules (excluding overrides)
    final generatedSchedules =
        _generateSchedulesFromFixed(_currentServiceArea!, excludedDates);

    for (final gen in generatedSchedules) {
      final id = gen['id']?.toString() ?? 'unknown';
      // Only add if not already present from database
      if (!itemsMap.containsKey(id)) {
        itemsMap[id] = gen;
      }
    }

    final sortedItems = itemsMap.values.toList()
      ..sort((a, b) {
        final da = a['date'];
        final db = b['date'];
        if (da is! DateTime || db is! DateTime) return 0;
        return da.compareTo(db);
      });

    _scheduledPickups
      ..clear()
      ..addAll(sortedItems);

    // Schedule reminders for upcoming pickups
    _scheduleReminders(isCollector: actualIsCollector);

    // Notify residents if collector is on the way
    if (!actualIsCollector) {
      for (final item in sortedItems) {
        final id = item['id'].toString();
        final status = item['status'].toString();
        if (status == 'on_the_way' && !_notifiedOnTheWayIds.contains(id)) {
          _notifiedOnTheWayIds.add(id);
          NotificationService.showNotification(
              id: id.hashCode & 0x7FFFFFFF,
              title: '🚛 Collector is Nearby!',
              body:
                  'Hold tight! The collector is on the way to ${item['address']}.');
        }

        // Notify residents of RESCHEDULES
        final isRescheduled = item['isRescheduled'] == true;
        if (isRescheduled && !_notifiedRescheduledIds.contains(id)) {
          _notifiedRescheduledIds.add(id);
          // Construct a friendly message
          final dateObj = item['date'] as DateTime;
          final dateStr = "${dateObj.month}/${dateObj.day} at ${item['time']}";

          // 1. Show Local Notification
          NotificationService.showNotification(
            id: (id.hashCode + 200) & 0x7FFFFFFF,
            title: '📅 Schedule Change',
            body:
                'Heads up! Collection for ${item['address']} is moved to $dateStr.',
          );

          // Note: We no longer persist this to the Database here because
          // the Admin Dashboard (schedules.js) already sends a real-time notification
          // when a schedule is updated, which is picked up by ReminderService.
        }
      }
    } else {
      // Logic for Collector (Reschedule Alerts)
      for (final item in sortedItems) {
        final id = item['id'].toString();
        final isRescheduled = item['isRescheduled'] == true;

        if (isRescheduled && !_notifiedRescheduledIds.contains(id)) {
          _notifiedRescheduledIds.add(id);
          NotificationService.showNotification(
            id: (id.hashCode + 100) &
                0x7FFFFFFF, // Offset ID to avoid collision
            title: '📅 Schedule Update',
            body:
                'Attention: ${item['address']} collection has been rescheduled.',
          );
        }
      }
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> _generateSchedulesFromFixed(
    String serviceArea,
    Set<DateTime> excludedDates,
  ) {
    final key = serviceArea.toLowerCase();
    final List<Map<String, dynamic>> fixedList = _fixedSchedules[key] ??
        (_defaultFixedSchedule(key) != null
            ? [_defaultFixedSchedule(key)!]
            : []);

    if (fixedList.isEmpty) return [];

    final schedules = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final fixed in fixedList) {
      // Ensure unique days to prevent redundant generation
      final Set<String> days = Set<String>.from(fixed['days'] ?? []);

      final String fixedTimeValue = (fixed['time'] ?? '08:00').toString();
      final parts = fixedTimeValue.split(':');
      final int fixedHour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
      final int fixedMinute =
          int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

      // Generate schedules for the next 4 weeks
      for (int week = 0; week < 4; week++) {
        for (final dayName in days) {
          final targetDay = _getDayOfWeek(dayName);
          if (targetDay == null) continue;

          // Find the next occurrence of this day compared to today (now)
          int daysUntil = targetDay - now.weekday;
          if (daysUntil < 0) daysUntil += 7;

          final scheduleDate = now.add(Duration(days: daysUntil + (week * 7)));

          // Skip if this date has an override (manual schedule or reschedule original)
          final normalizedDate = _normalizeDate(scheduleDate);
          final hasOverride = excludedDates.contains(normalizedDate);

          if (!hasOverride) {
            final dateKey = normalizedDate.toIso8601String().split('T').first;
            schedules.add({
              'id': 'fixed_${key}_$dateKey',
              'address': serviceArea,
              'type': fixed['scheduleName'] ?? 'Regular Collection',
              'time': fixedTimeValue,
              'date': DateTime(
                scheduleDate.year,
                scheduleDate.month,
                scheduleDate.day,
                fixedHour,
                fixedMinute,
              ),
              'status': 'Scheduled',
              'locationNote': 'Fixed schedule',
              'assignedBy': 'System',
              'isFixed': true,
            });
          }
        }
      }
    }

    return schedules;
  }

  int? _getDayOfWeek(String dayName) {
    final days = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return days[dayName.toLowerCase()];
  }

  Map<String, dynamic> _mapScheduleDoc(String id, Map<String, dynamic> data) {
    // Admin Dashboard uses 'scheduled_date', legacy might use 'collection_time'
    final dynamic rawDate = data['scheduled_date'] ?? data['collection_time'];
    DateTime date = DateTime.now();

    final dynamic rawOriginalDate = data['original_date'];
    DateTime? originalDate;

    if (rawDate is String) {
      date = DateTime.parse(rawDate).toLocal();
    } else if (rawDate is DateTime) {
      date = rawDate.toLocal();
    }

    if (rawOriginalDate is String) {
      originalDate = DateTime.parse(rawOriginalDate).toLocal();
    } else if (rawOriginalDate is DateTime) {
      originalDate = rawOriginalDate.toLocal();
    }

    // Extract time string from date
    String timeStr = '';
    if (rawDate != null) {
      if (rawDate is String) {
        final parts = rawDate.split('T');
        if (parts.length > 1) {
          timeStr = parts.last.substring(0, 5);
        }
      } else if (rawDate is DateTime) {
        timeStr =
            "${rawDate.hour.toString().padLeft(2, '0')}:${rawDate.minute.toString().padLeft(2, '0')}";
      }
    }

    return {
      'id': id,
      'address': (data['zone'] ?? 'Assigned Area').toString(),
      'type': 'Eco Collection',
      'time': timeStr.isNotEmpty ? timeStr : '08:00',
      'date': date,
      'status': (data['status'] ?? 'Scheduled').toString(),
      'locationNote': (data['description'] ?? '').toString(),
      'assignedBy': 'Admin',
      'isRescheduled': data['is_rescheduled'] ?? false,
      'originalDate': originalDate,
      'rescheduledReason': data['rescheduled_reason'] ?? '',
    };
  }

  DateTime _normalizeDate(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  void addPickup({
    required String address,
    required String wasteType,
    required DateTime date,
    required String timeSlot,
    required String locationNote,
  }) {
    _scheduledPickups.add({
      'address': address,
      'type': wasteType,
      'time': timeSlot,
      'date': date,
      'locationNote': locationNote,
      'createdAt': DateTime.now(),
    });
    notifyListeners();
  }

  Future<void> updateScheduleStatus(String scheduleId, String status) async {
    try {
      if (scheduleId.startsWith('fixed_')) {
        // Handle fixed schedule override - create a real document
        await _createOverrideForFixedSchedule(scheduleId, status);
      } else {
        await _supabase.from(SupabaseConfig.collectionSchedulesTable).update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', scheduleId);
      }

      // Refresh local state if needed (subscription usually handles this)
    } catch (e) {
      if (kDebugMode) {
        print('Error updating schedule status: $e');
      }
      rethrow;
    }
  }

  Future<void> _createOverrideForFixedSchedule(
      String fixedId, String status) async {
    // Logic to create a document in collection_schedules that overrides the fixed schedule
    // This is complex as we need the full objects. For now, we will log it.
    if (kDebugMode) {
      print(
          'Fixed schedule override not fully implemented for status update: $fixedId -> $status');
    }
  }

  void clearAll() {
    _scheduledPickups.clear();
    _lastStreamedSchedules.clear();
    _notifiedOnTheWayIds.clear();
    _notifiedRescheduledIds.clear();
    notifyListeners();
  }

  void reset() {
    _scheduleSubscription?.cancel();
    _fixedScheduleSubscription?.cancel();
    _scheduleSubscription = null;
    _fixedScheduleSubscription = null;
    _currentServiceArea = null;
    clearAll();
  }

  Future<void> _scheduleReminders({bool isCollector = false}) async {
    if (kDebugMode) {
      print(
          '🛠️ PickupService: _scheduleReminders called (isCollector: $isCollector)');
      print('   - Scheduled pickups count: ${_scheduledPickups.length}');
    }
    final now = DateTime.now();

    for (final pickup in _scheduledPickups) {
      final date = pickup['date'] as DateTime;
      final type = pickup['type'] as String;

      if (isCollector) {
        // Collector: 30 minutes before
        final reminderDate = date.subtract(const Duration(minutes: 30));
        if (reminderDate.isAfter(now)) {
          final id = ((date.millisecondsSinceEpoch ~/ 1000) + type.hashCode) &
              0x7FFFFFFF;
          await NotificationService.scheduleNotification(
            id: id,
            title: '🚛 Collection Starting Soon!',
            body:
                'You have a collection scheduled for ${pickup['address']} in 30 minutes.',
            scheduledDate: reminderDate,
            payload: 'schedule_$id',
          );
        }
      } else {
        // Resident: 6:00 PM the day before
        final dayBeforeDate = DateTime(date.year, date.month, date.day)
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 18)); // 6:00 PM

        if (dayBeforeDate.isAfter(now)) {
          final id =
              ((date.millisecondsSinceEpoch ~/ 1000) + type.hashCode + 1) &
                  0x7FFFFFFF;
          await NotificationService.scheduleNotification(
            id: id,
            title: '🗓️ Eco Collection Tomorrow',
            body:
                'Heads up! Your eco collection is scheduled for tomorrow at ${pickup['time']}.',
            scheduledDate: dayBeforeDate,
            payload: 'schedule_day_before_$id',
          );
        }

        // Resident: 2 hours before
        final hoursBeforeDate = date.subtract(const Duration(hours: 2));
        if (hoursBeforeDate.isAfter(now)) {
          final id =
              ((date.millisecondsSinceEpoch ~/ 1000) + type.hashCode + 2) &
                  0x7FFFFFFF;
          await NotificationService.scheduleNotification(
            id: id,
            title: '🚛 Truck En Route!',
            body: 'Collection in ${pickup['address']} scheduled in 2 hours.',
            scheduledDate: hoursBeforeDate,
            payload: 'schedule_hours_before_$id',
          );
        }
      }
    }
  }

  /// Fetches completed collections for the service area.
  Future<List<Map<String, dynamic>>> getCollectionHistory() async {
    try {
      if (_currentServiceArea == null) return [];

      final data = await _supabase
          .from(SupabaseConfig.collectionSchedulesTable)
          .select('*')
          .eq('zone', _currentServiceArea!)
          .eq('status', 'completed')
          .order('collection_time', ascending: false);

      return (data as List)
          .map((doc) => _mapScheduleDoc(doc['id'].toString(), doc))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching collection history: $e');
      }
      return [];
    }
  }

  /// Notifies admins and residents that a collector has started their session.
  Future<void> notifyCollectorStarted(String collectorName, String zone) async {
    try {
      // Find all admin users to notify
      final admins = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .filter('role', 'in', '("admin", "superadmin")');

      // Find all residents in the same zone to notify
      final residents = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('role', 'resident')
          .filter('barangay', 'ilike',
              '%$zone%'); // Allow partial matches (e.g., 'Dayo-An' vs 'dayo-an')

      final List<Map<String, dynamic>> allNotifications = [];
      final now = DateTime.now().toIso8601String();

      if (admins.isNotEmpty) {
        allNotifications.addAll(admins.map((admin) {
          return {
            'user_id': admin['id'],
            'title': 'Collection Started',
            'message':
                'Collector $collectorName has started collection in $zone.',
            'type': 'alert', // Matches schema type: info, warning, alert
            'read': false,
            'created_at': now,
          };
        }));
      }

      if (residents.isNotEmpty) {
        allNotifications.addAll(residents.map((resident) {
          return {
            'user_id': resident['id'],
            'title': 'Collection Started',
            'message':
                'Collector $collectorName has started waste collection in your area ($zone). Please prepare your bins.',
            'type': 'info',
            'read': false,
            'created_at': now,
          };
        }));
      }

      if (allNotifications.isNotEmpty) {
        await _supabase
            .from(SupabaseConfig.notificationsTable)
            .insert(allNotifications);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error notifying admin/residents: $e');
      }
    }
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    _fixedScheduleSubscription?.cancel();
    super.dispose();
  }
}
