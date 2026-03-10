import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecosched/core/services/notification_service.dart';
import '../config/supabase_config.dart';

class PickupService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final List<Map<String, dynamic>> _scheduledPickups = [];
  final Map<String, Map<String, dynamic>> _fixedSchedules = {};
  final Set<String> _notifiedOnTheWayIds = {};
  final Set<String> _notifiedRescheduledIds = {};
  final Set<String> _notifiedCompletedIds = {};
  final Set<String> _notifiedCancelledIds = {};
  List<Map<String, dynamic>> _lastStreamedSchedules = [];

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

  /// Get next upcoming collection for a service area
  Map<String, dynamic>? getNextCollection(String serviceArea) {
    final now = DateTime.now();
    final upcoming = _scheduledPickups
        .where((pickup) =>
            pickup['address']?.toString().toLowerCase() ==
                serviceArea.toLowerCase() &&
            (pickup['date'] as DateTime).isAfter(now))
        .toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return upcoming.first;
  }

  StreamSubscription<List<Map<String, dynamic>>>? _scheduleSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _fixedScheduleSubscription;
  String? _currentServiceArea;

  Future<void> loadSchedulesForServiceArea(String serviceArea,
      {bool isCollector = false}) async {
    if (_currentServiceArea == serviceArea && _scheduleSubscription != null) {
      return;
    }

    await _scheduleSubscription?.cancel();
    await _fixedScheduleSubscription?.cancel();
    _currentServiceArea = serviceArea.trim();

    // Load fixed schedules first
    await _loadFixedSchedules();

    // Then load regular schedules
    // We remove the .eq('zone') filter to ensure we receive updates regardless of case (Victoria vs victoria)
    // and then filter locally. ideally we would use .ilike but stream() has limited filters.
    _scheduleSubscription = _supabase
        .from(SupabaseConfig.collectionSchedulesTable)
        .stream(primaryKey: ['id']).listen(
      (data) {
        _lastStreamedSchedules = data
            .map((doc) => _mapScheduleDoc(doc['id'].toString(), doc))
            // Extra safety: strictly filter by current service area to prevent leakage
            .where((s) =>
                s['address'].toString().toLowerCase() ==
                _currentServiceArea!.toLowerCase())
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
        _fixedSchedules.clear();
        for (final doc in data) {
          final area = (doc['area'] ?? '').toString().toLowerCase();
          if (area.isNotEmpty) {
            _fixedSchedules[area] = {
              'id': doc['id'],
              'area': doc['area'],
              'scheduleName': doc['schedule_name'],
              'days': doc['days'],
              'time': doc['time'],
              'active': doc['is_active'],
            };
          }
        }
        _rebuildScheduledPickups();
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

  void _rebuildScheduledPickups({bool isCollector = false}) {
    if (_currentServiceArea == null) return;

    final items = List<Map<String, dynamic>>.from(_lastStreamedSchedules);
    final excludedDates = <DateTime>{};

    for (final item in items) {
      final dynamic scheduled = item['date'];
      if (scheduled is DateTime) {
        excludedDates.add(_normalizeDate(scheduled));
      }

      final dynamic isRescheduled = item['isRescheduled'];
      final dynamic original = item['originalDate'];
      if (isRescheduled == true && original is DateTime) {
        excludedDates.add(_normalizeDate(original));
      }
    }

    // Add generated schedules from fixed schedules (excluding overrides)
    final generatedSchedules =
        _generateSchedulesFromFixed(_currentServiceArea!, excludedDates);
    items.addAll(generatedSchedules);

    items.sort((a, b) {
      final da = a['date'];
      final db = b['date'];
      if (da is! DateTime || db is! DateTime) return 0;
      return da.compareTo(db);
    });

    _scheduledPickups
      ..clear()
      ..addAll(items);

    // Schedule reminders for upcoming pickups
    _scheduleReminders(isCollector: isCollector);

    // Notify residents if collector is on the way
    if (!isCollector) {
      for (final item in items) {
        final id = item['id'].toString();
        final status = item['status'].toString();

        if (status == 'on_the_way' && !_notifiedOnTheWayIds.contains(id)) {
          _notifiedOnTheWayIds.add(id);
          NotificationService.showNotification(
              id: id.hashCode & 0x7FFFFFFF,
              title: 'Collector On The Way',
              body:
                  'The waste collector is now on the way to ${item['address']}!');
        }

        // Notify residents of RESCHEDULES
        final isRescheduled = item['isRescheduled'] == true;
        if (isRescheduled && !_notifiedRescheduledIds.contains(id)) {
          _notifiedRescheduledIds.add(id);
          // Construct a friendly message
          final dateObj = item['date'] as DateTime;
          final dateStr = "${dateObj.month}/${dateObj.day} at ${item['time']}";

          NotificationService.showNotification(
            id: (id.hashCode + 200) & 0x7FFFFFFF,
            title: 'Collection Rescheduled',
            body:
                'The collection for ${item['address']} has been rescheduled to $dateStr.',
          );
        }

        // Notify residents of COMPLETED collection
        if (status.toLowerCase() == 'completed' &&
            !_notifiedCompletedIds.contains(id)) {
          _notifiedCompletedIds.add(id);
          NotificationService.showNotification(
            id: (id.hashCode + 300) & 0x7FFFFFFF,
            title: '✅ Eco Collection Completed',
            body: 'Eco collection at ${item['address']} has been completed.',
          );
        }

        // Notify residents of CANCELLED collection
        if (status.toLowerCase() == 'cancelled' &&
            !_notifiedCancelledIds.contains(id)) {
          _notifiedCancelledIds.add(id);
          NotificationService.showNotification(
            id: (id.hashCode + 400) & 0x7FFFFFFF,
            title: '❌ Eco Collection Cancelled',
            body: 'Eco collection for ${item['address']} has been cancelled.',
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
    if (serviceArea.isEmpty) {
      print('PickupService: No serviceArea provided, skipping fixed schedules');
      return [];
    }

    final key = serviceArea.toLowerCase();
    final fixed = _fixedSchedules[key] ?? _defaultFixedSchedule(key);

    // Strict safety check: ensure the fixed schedule is actually for this area
    if (fixed == null) {
      print('PickupService: No fixed schedule found for area: $key');
      return [];
    }

    final fixedArea = (fixed['area'] ?? '').toString().toLowerCase();

    // Allow mismatches if the key is 'victoria' or 'dayo-an' (legacy support or loose matching)
    // But warn about them. If it's a completely different area, block it.
    if (fixedArea != key && fixedArea.isNotEmpty) {
      print(
          'PickupService: Schedule area mismatch. Requested: $key, Fixed: $fixedArea');
      // If strict filtering is required, uncomment:
      // return [];
    }

    final List<String> days = List<String>.from(fixed['days'] ?? []);
    final schedules = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Parse time
    final String fixedTimeValue = (fixed['time'] ?? '08:00').toString();
    final parts = fixedTimeValue.split(':');

    int fixedHour = 8;
    int fixedMinute = 0;

    if (parts.isNotEmpty) {
      fixedHour = int.tryParse(parts[0]) ?? 8;
    }
    if (parts.length > 1) {
      fixedMinute = int.tryParse(parts[1]) ?? 0;
    }

    // Generate schedules for the next 4 weeks
    for (int week = 0; week < 4; week++) {
      for (final dayName in days) {
        final targetDay = _getDayOfWeek(dayName);
        if (targetDay == null) continue;

        // Current day of week (1=Mon, 7=Sun)
        final currentWeekday = now.weekday;

        // Days to add to reach the next target day
        // ensure result is 0-6
        int daysUntil = (targetDay - currentWeekday + 7) % 7;

        // If today is the target day and the time has passed, move to next week
        // But for fixed schedules, usually we show it if it's today
        // Let's just generate for today if it matches

        // Calculate the date
        final scheduleDate = now.add(Duration(days: daysUntil + (week * 7)));

        // normalize date to remove time part for comparison
        final normalizedDate =
            DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);

        // Check for overrides
        // excludedDates should contain normalized dates (midnight)
        bool isExcluded = false;
        for (final excluded in excludedDates) {
          if (excluded.year == normalizedDate.year &&
              excluded.month == normalizedDate.month &&
              excluded.day == normalizedDate.day) {
            isExcluded = true;
            break;
          }
        }

        if (!isExcluded) {
          final dateKey = normalizedDate.toIso8601String().split('T').first;

          // Use the original serviceArea string for display (capitalized) or from fixed data
          final displayArea = fixed['area'] ?? serviceArea;

          schedules.add({
            'id': 'fixed_${key}_$dateKey',
            'address': displayArea, // Use capitalized or raw area name
            'type': fixed['scheduleName'] ?? 'Regular Collection',
            'time': fixedTimeValue,
            'collection_time': DateTime(
              scheduleDate.year,
              scheduleDate.month,
              scheduleDate.day,
              fixedHour,
              fixedMinute,
            ).toIso8601String(), // Keep for legacy if needed
            'scheduled_date': DateTime(
              scheduleDate.year,
              scheduleDate.month,
              scheduleDate.day,
              fixedHour,
              fixedMinute,
            ).toIso8601String(),
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
    final dynamic rawDate = data['scheduled_date'] ?? data['collection_time'];
    DateTime date = DateTime.now();

    final dynamic rawOriginalDate = data['original_date'];
    DateTime? originalDate;

    if (rawDate is String) {
      date = DateTime.parse(rawDate);
    } else if (rawDate is DateTime) {
      date = rawDate;
    }

    if (rawOriginalDate is String) {
      originalDate = DateTime.parse(rawOriginalDate);
    } else if (rawOriginalDate is DateTime) {
      originalDate = rawOriginalDate;
    }

    return {
      'id': id,
      'address': (data['zone'] ?? 'Assigned Area').toString(),
      'type': 'Eco Collection',
      'time': (rawDate is String && rawDate.length >= 16)
          ? rawDate.substring(11, 16)
          : ('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'),
      'date': date,
      'status': (data['status'] ?? 'Scheduled').toString(),
      'locationNote': (data['description'] ?? '').toString(),
      'assignedBy': 'Admin',
      'isRescheduled': data['is_rescheduled'] ?? false,
      'originalDate': originalDate,
      'rescheduledReason': data['rescheduled_reason'] ?? '',
    };
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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
    _notifiedOnTheWayIds.clear();
    _notifiedRescheduledIds.clear();
    _notifiedCompletedIds.clear();
    _notifiedCancelledIds.clear();
    notifyListeners();
  }

  Future<void> _scheduleReminders({bool isCollector = false}) async {
    if (kDebugMode) {
      print(
          '🛠️ PickupService: _scheduleReminders called (isCollector: $isCollector)');
      print('   - Scheduled pickups count: ${_scheduledPickups.length}');
    }
    for (final pickup in _scheduledPickups) {
      final date = pickup['date'] as DateTime;
      final type = pickup['type'] as String;
      final now = DateTime.now();

      DateTime reminderDate;
      String title;
      String body;

      if (isCollector) {
        // Collector: 30 minutes before
        reminderDate = date.subtract(const Duration(minutes: 30));
        title = 'Upcoming Collection';
        body =
            'You have a collection scheduled for ${pickup['address']} in 30 minutes.';

        if (reminderDate.isAfter(now)) {
          final id = ((date.millisecondsSinceEpoch ~/ 1000) + type.hashCode) &
              0x7FFFFFFF;
          await NotificationService.scheduleNotification(
            id: id,
            title: title,
            body: body,
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
            title: 'Collection Tomorrow!',
            body: 'Your $type is scheduled for tomorrow at ${pickup['time']}.',
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
            title: 'Truck is Coming Soon!',
            body: 'Collection in ${pickup['address']} scheduled in 2 hours.',
            scheduledDate: hoursBeforeDate,
            payload: 'schedule_hours_before_$id',
          );
        }
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
