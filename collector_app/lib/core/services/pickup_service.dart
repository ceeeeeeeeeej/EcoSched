import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collector_app/core/services/notification_service.dart';
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
  StreamSubscription<List<Map<String, dynamic>>>? _specialCollectionSubscription;
  final List<Map<String, dynamic>> _lastStreamedSpecialCollections = [];
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
    await _specialCollectionSubscription?.cancel();
    _currentServiceArea = normalizedArea;
    _isLastCollector = isCollector;

    // Clear stale data when switching areas
    _lastStreamedSchedules.clear();
    _lastStreamedSpecialCollections.clear();
    _scheduledPickups.clear();
    _notifiedOnTheWayIds.clear();
    _notifiedRescheduledIds.clear();
    notifyListeners();

    // Load fixed schedules first (all zones)
    await _loadFixedSchedules();

    // Stream special collections (scheduled status only) — collectors see all
    _specialCollectionSubscription = _supabase
        .from(SupabaseConfig.specialCollectionsTable)
        .stream(primaryKey: ['id'])
        .listen(
      (data) {
        // Show any special collection that has a scheduled_date assigned by admin
        // and is not yet cancelled or completed
        final scheduled = data.where((doc) {
          final status = (doc['status'] ?? '').toString().toLowerCase();
          final hasDate = doc['scheduled_date'] != null &&
              doc['scheduled_date'].toString().isNotEmpty;
          final isActive = status != 'cancelled' &&
              status != 'completed' &&
              status != 'pending' &&
              status != 'pending_payment';
          return hasDate && isActive;
        }).toList();

        if (kDebugMode) {
          print('📡 PickupService: Received ${scheduled.length} special collections');
        }

        _lastStreamedSpecialCollections.clear();
        _lastStreamedSpecialCollections
            .addAll(scheduled.map((doc) => _mapSpecialCollectionDoc(doc)));
        _rebuildScheduledPickups(isCollector: isCollector);
      },
      onError: (e) {
        if (kDebugMode) print('Failed to load special collections: $e');
      },
    );

    // Collectors see ALL zones; residents only see their assigned zone
    final scheduleQuery = _supabase
        .from(SupabaseConfig.collectionSchedulesTable)
        .stream(primaryKey: ['id']);

    _scheduleSubscription = (isCollector
            ? scheduleQuery // no zone filter → all zones
            : scheduleQuery.eq('zone', normalizedArea))
        .listen(
      (data) {
        if (kDebugMode) {
          print('📡 PickupService: Received ${data.length} schedules'
              ' (collector=$isCollector, area=$normalizedArea)');
        }
        _lastStreamedSchedules = data
            .map((doc) => _mapScheduleDoc(doc['id'].toString(), doc))
            .toList();

        _rebuildScheduledPickups(isCollector: isCollector);
      },
      onError: (e) {
        if (kDebugMode) {
          print('Failed to load schedules: $e');
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
            if (!_fixedSchedules.containsKey(area)) {
              _fixedSchedules[area] = [];
            }
            _fixedSchedules[area]!.add({
              'id': doc['id'],
              'area': doc['area'],
              'scheduleName': doc['schedule_name'],
              'days': doc['days'],
              'time': doc['time'],
              'active': doc['is_active'],
            });
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

    // 1. Add streamed regular schedules (highest priority)
    for (final doc in _lastStreamedSchedules) {
      final id = doc['id']?.toString() ?? 'unknown';
      itemsMap[id] = doc;
    }

    // 2. Add special collections (prefixed to avoid ID collision)
    for (final doc in _lastStreamedSpecialCollections) {
      final id = 'special_${doc['id']}';
      itemsMap[id] = {...doc, 'id': id};
    }

    // 3. Build excluded-dates set from all collected items
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

    // 4. Add generated schedules from fixed schedules (excluding overrides)
    // Collectors get schedules for ALL known areas; residents only their area
    final areasToGenerate = _isLastCollector
        ? (_fixedSchedules.isNotEmpty
            ? _fixedSchedules.keys.toList()
            : ['victoria', 'dayo-an'])
        : [_currentServiceArea!];

    for (final area in areasToGenerate) {
      final generatedSchedules =
          _generateSchedulesFromFixed(area, excludedDates);
      for (final gen in generatedSchedules) {
        final id = gen['id']?.toString() ?? 'unknown';
        if (!itemsMap.containsKey(id)) {
          itemsMap[id] = gen;
        }
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
    final todayStart = _normalizeDate(DateTime.now());

    if (!actualIsCollector) {
      for (final item in sortedItems) {
        final id = item['id'].toString();
        final status = item['status'].toString();
        final itemDate = item['date'] as DateTime;
        final isOld = _normalizeDate(itemDate).isBefore(todayStart);
        
        if (!isOld && status == 'on_the_way' && !_notifiedOnTheWayIds.contains(id)) {
          _notifiedOnTheWayIds.add(id);
          NotificationService.showNotification(
              id: id.hashCode & 0x7FFFFFFF,
              title: '🚛 Collector is Nearby!',
              body:
                  'Hold tight! The collector is on the way to ${item['address']}.');
        }

        // Notify residents of RESCHEDULES
        final isRescheduled = item['isRescheduled'] == true;
        if (!isOld && isRescheduled && !_notifiedRescheduledIds.contains(id)) {
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
        final itemDate = item['date'] as DateTime;
        final isOld = _normalizeDate(itemDate).isBefore(todayStart);

        if (!isOld && isRescheduled && !_notifiedRescheduledIds.contains(id)) {
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
    
    List<Map<String, dynamic>> fixedList = _fixedSchedules[key] ?? [];
    if (fixedList.isEmpty) {
      final def = _defaultFixedSchedule(key);
      if (def != null) {
        fixedList = [def];
      }
    }

    if (fixedList.isEmpty) return [];

    final schedules = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final fixed in fixedList) {
      // Ensure unique days to prevent redundant generation
      final Set<String> days = Set<String>.from(fixed['days'] ?? []);

      final String fixedTimeValue = (fixed['time'] ?? '08:00').toString();
      final parts = fixedTimeValue.split(':');
      final int fixedHour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 8;
      final int fixedMinute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

      // Extract fixed ID if available
      final fixedId = fixed['id']?.toString() ?? key;

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
              'id': 'fixed_${fixedId}_$dateKey',
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

    // Extract time string from date — convert to PHT (UTC+8) and use 12-hour format
    String timeStr = '';
    if (rawDate != null) {
      DateTime localDate;
      if (rawDate is String) {
        localDate = DateTime.parse(rawDate).toUtc().add(const Duration(hours: 8));
      } else if (rawDate is DateTime) {
        localDate = rawDate.toUtc().add(const Duration(hours: 8));
      } else {
        localDate = DateTime.now().toUtc().add(const Duration(hours: 8));
      }
      // Format as 12-hour time (e.g., 7:00 AM / 7:00 PM)
      final hour = localDate.hour;
      final minute = localDate.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      timeStr = '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }

    final String description = (data['description'] ?? '').toString();
    final String name = (data['name'] ?? '').toString();
    
    // Check both name and description for "Special Collection"
    final bool isSpecial = name.contains('Special Collection') || 
                          description.contains('Special Collection') ||
                          name.toLowerCase().contains('special');

    String? residentName;
    String? pickupLocation;

    // Use robust Regex to parse Location: ... and Resident: ...
    final locRegex = RegExp(r'Location:\s*([^\n,.]*)', caseSensitive: false);
    final resRegex = RegExp(r'Resident:\s*([^\n,.]*)', caseSensitive: false);
    final prkRegex = RegExp(r'Purok:\s*([^\n,.]*)', caseSensitive: false);
    final strRegex = RegExp(r'Street:\s*([^\n,.]*)', caseSensitive: false);
    final brgRegex = RegExp(r'Barangay:\s*([^\n,.]*)', caseSensitive: false);
    final ageRegex = RegExp(r'Age:\s*([^\n,.]*)', caseSensitive: false);

    final locMatch = locRegex.firstMatch(description);
    final resMatch = resRegex.firstMatch(description);
    final prkMatch = prkRegex.firstMatch(description);
    final strMatch = strRegex.firstMatch(description);
    final brgMatch = brgRegex.firstMatch(description);
    final ageMatch = ageRegex.firstMatch(description);

    if (locMatch != null) pickupLocation = locMatch.group(1)?.trim();
    if (resMatch != null) residentName = resMatch.group(1)?.trim();

    // Prioritize explicit columns if they exist in the data
    if (data['resident_name'] != null && data['resident_name'].toString().isNotEmpty) {
      residentName = data['resident_name'].toString();
    }
    if (data['pickup_location'] != null && data['pickup_location'].toString().isNotEmpty) {
      pickupLocation = data['pickup_location'].toString();
    }
    final String? purok = prkMatch?.group(1)?.trim();
    final String? street = strMatch?.group(1)?.trim();
    final String? residentBarangay = brgMatch?.group(1)?.trim();
    final String? residentAge = ageMatch?.group(1)?.trim();

    return {
      'id': id,
      'address': (data['zone'] ?? 'Assigned Area').toString(),
      'type': isSpecial ? (name.isNotEmpty ? name : 'Special Collection') : 'Eco Collection',
      'time': timeStr.isNotEmpty ? timeStr : '08:00',
      'date': date,
      'status': (data['status'] ?? 'Scheduled').toString(),
      'locationNote': description,
      'residentName': residentName,
      'pickupLocation': pickupLocation,
      'purok': purok,
      'street': street,
      'residentBarangay': residentBarangay,
      'residentAge': residentAge,
      'title': name,
      'assignedBy': 'Admin',
      'isSpecial': isSpecial,
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
    try {
      // Find the pickup details from our local list
      final pickup = _scheduledPickups.firstWhere(
        (p) => p['id'] == fixedId,
        orElse: () => {},
      );

      if (pickup.isEmpty) {
        if (kDebugMode) {
          print('Fixed schedule override failed: Pickup matching $fixedId not found');
        }
        return;
      }

      final date = pickup['date'] as DateTime;
      final zone = pickup['address'] as String;

      // Create a persistent record in the collection_schedules table
      // This "promotes" the fixed schedule to a real database entry
      await _supabase.from(SupabaseConfig.collectionSchedulesTable).insert({
        'zone': zone,
        'status': status,
        'scheduled_date': date.toIso8601String(),
        'collection_time': date.toIso8601String(), // Required NOT NULL column
        'description': pickup['locationNote'] ?? 'Fixed schedule override',
        'is_rescheduled': false,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        print('Successfully created override for $fixedId at $zone with status $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating fixed schedule override: $e');
      }
      rethrow;
    }
  }

  void clearAll() {
    _scheduledPickups.clear();
    _lastStreamedSchedules.clear();
    _lastStreamedSpecialCollections.clear();
    _notifiedOnTheWayIds.clear();
    _notifiedRescheduledIds.clear();
    notifyListeners();
  }

  void reset() {
    _scheduleSubscription?.cancel();
    _fixedScheduleSubscription?.cancel();
    _specialCollectionSubscription?.cancel();
    _scheduleSubscription = null;
    _fixedScheduleSubscription = null;
    _specialCollectionSubscription = null;
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
            title: '♻️ Collection Tomorrow',
            body:
                'Heads up! Your waste collection in ${pickup['address']} is scheduled for tomorrow at ${pickup['time']}. prepare your garbage',
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
            title: '🛣️ Put your garbage in designated area',
            body: 'Your collection in ${pickup['address']} is scheduled in 2 hours. Get ready!',
            scheduledDate: hoursBeforeDate,
            payload: 'schedule_hours_before_$id',
          );
        }

        // Resident: At exact schedule time
        if (date.isAfter(now)) {
          final id =
              ((date.millisecondsSinceEpoch ~/ 1000) + type.hashCode + 3) &
                  0x7FFFFFFF;
          await NotificationService.scheduleNotification(
            id: id,
            title: '⏰ Collection Time',
            body: "It's already time! The collector will notify you when they start their route.",
            scheduledDate: date,
            payload: 'schedule_exact_time_$id',
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
      final now = DateTime.now();
      final todayStr = _normalizeDate(now).toIso8601String().split('T').first;

      // 1. Find all admin users to notify
      final admins = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .filter('role', 'in', '("admin", "superadmin")');

      // 2. Find residents with a schedule today in this zone
      // Check both DB-based schedules AND our local list (which includes fixed ones)
      final hasAnyScheduleToday = _scheduledPickups.any((p) => 
        p['address']?.toString().toLowerCase() == zone.toLowerCase() &&
        _normalizeDate(p['date'] as DateTime) == _normalizeDate(now)
      );

      // A. Check for special collections scheduled for today in this zone
      final specialCollections = await _supabase
          .from(SupabaseConfig.specialCollectionsTable)
          .select('resident_id')
          .eq('status', 'scheduled')
          .gte('scheduled_date', todayStr)
          .lte('scheduled_date', '$todayStr 23:59:59');

      Set<String> recipientIds = {};

      // If there's any schedule for the zone today (fixed or manual), notify ALL residents in that zone
      if (hasAnyScheduleToday) {
        final residentsInZone = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('id')
            .eq('role', 'resident')
            .filter('barangay', 'ilike', '%$zone%');
        recipientIds.addAll(residentsInZone.map((r) => r['id'].toString()));
      }

      // Also notify residents who have special collections today (even if no general schedule)
      recipientIds.addAll(
          specialCollections.map((s) => s['resident_id'].toString()));

      final List<Map<String, dynamic>> allNotifications = [];
      final timestamp = now.toIso8601String();

      // Notifications for Admins
      if (admins.isNotEmpty) {
        for (var admin in admins) {
          final adminId = admin['id'].toString();
          allNotifications.add({
            'user_id': adminId,
            'title': 'Collection Started',
            'message':
                'Collector $collectorName has started collection in $zone.',
            'type': 'alert',
            'is_read': false,
            'barangay': zone,
            'created_at': timestamp,
          });
          
          // Send Push to Admin
          _sendPushNotification(
            userId: adminId,
            title: 'Collection Started 🚛',
            body: 'Collector $collectorName has started collection in $zone.',
          );
        }
      }

      // Notifications for Residents with Schedules
      if (recipientIds.isNotEmpty) {
        final todayDateString = now.toIso8601String().split('T').first;
        for (var residentId in recipientIds) {
          // --- CLEANUP DUPLICATES ---
          // Remove any "Starting Now" alerts from today to prevent history clutter
          try {
            await _supabase
                .from(SupabaseConfig.notificationsTable)
                .delete()
                .eq('user_id', residentId)
                .eq('barangay', zone)
                .ilike('title', '%Starting Now%')
                .gte('created_at', '${todayDateString}T00:00:00Z');
          } catch (e) {
            // Ignore delete errors during cleanup
          }

          allNotifications.add({
            'user_id': residentId,
            'title': 'Collector is Incoming! 🚚',
            'message':
                'Stay alert! Collector $collectorName is on the way to $zone. Your collection is starting soon!',
            'type': 'info',
            'is_read': false,
            'barangay': zone,
            'created_at': timestamp,
          });

          // Send Push to Resident
          _sendPushNotification(
            userId: residentId,
            title: 'Collector is Incoming! 🚛',
            body: 'The truck is on the way to $zone! Collector $collectorName has started the route.',
          );
        }
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

  /// Helper to trigger FCM push notification via Supabase Edge Function
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      // In Dart/Supabase Flutter, we use functions.invoke
      await _supabase.functions.invoke(
        'send-push-v2',
        headers: {
            'apikey': SupabaseConfig.supabaseAnonKey
        },
        body: {
          'resident_id': userId,
          'title': title,
          'body': body,
        },
      );
      if (kDebugMode) {
        print('🚀 Push triggered for $userId: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error triggering push for $userId: $e');
      }
    }
  }

  /// Maps a row from `special_collections` table into the same shape
  /// used by [_mapScheduleDoc] so RouteCard can render it correctly.
  Map<String, dynamic> _mapSpecialCollectionDoc(Map<String, dynamic> data) {
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

    // Resolve scheduled date — admin stores date as "2026-03-29" and time in metadata
    final rawDate = data['scheduled_date'];
    final metaTime = metadata['scheduledTime']?.toString() ?? '';
    DateTime date = DateTime.now();
    if (rawDate is String && rawDate.isNotEmpty) {
      try {
        if (rawDate.contains('T') || rawDate.contains(' ')) {
          // Full ISO timestamp
          date = DateTime.parse(rawDate).toLocal();
        } else {
          // Date-only string like "2026-03-29" — combine with scheduled time
          final timeParts = metaTime.split(':');
          final h = int.tryParse(timeParts.isNotEmpty ? timeParts[0] : '') ?? 8;
          final m = int.tryParse(timeParts.length > 1 ? timeParts[1] : '') ?? 0;
          final dateParts = rawDate.split('-');
          final y = int.tryParse(dateParts.isNotEmpty ? dateParts[0] : '') ?? DateTime.now().year;
          final mo = int.tryParse(dateParts.length > 1 ? dateParts[1] : '') ?? 1;
          final d = int.tryParse(dateParts.length > 2 ? dateParts[2] : '') ?? 1;
          date = DateTime(y, mo, d, h, m);
        }
      } catch (_) {
        date = DateTime.now();
      }
    }

    // Build a friendly time string
    String timeStr = metaTime;
    if (timeStr.isEmpty) {
      final pht = date.toUtc().add(const Duration(hours: 8));
      final h = pht.hour;
      final m = pht.minute;
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      timeStr = '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
    }

    final residentName = data['resident_name']?.toString() ??
        metadata['resident_name']?.toString() ?? 'Resident';
    final barangay = data['resident_barangay']?.toString() ??
        metadata['resident_barangay']?.toString() ?? 'Unknown Area';
    final purok = data['resident_purok']?.toString() ??
        metadata['resident_purok']?.toString();
    final pickupLocation = data['pickup_location']?.toString();
    final wasteType = data['waste_type']?.toString() ?? 'Special Collection';
    final quantity = data['estimated_quantity']?.toString();
    // Message can live in special_instructions, message, or metadata
    final instructions = _firstNonEmpty([
      data['special_instructions']?.toString(),
      data['message']?.toString(),
      metadata['residentMessage']?.toString(),
      metadata['message']?.toString(),
    ]);

    return {
      'id': data['id'].toString(),
      'address': barangay,
      'type': 'Special Collection',
      'time': timeStr.isNotEmpty ? timeStr : '08:00',
      'date': date,
      'status': 'Scheduled',
      'isSpecial': true,
      'isFixed': false,
      'isRescheduled': false,
      'residentName': residentName,
      'residentBarangay': barangay,
      'purok': purok,
      'pickupLocation': pickupLocation,
      'wasteType': wasteType,
      'estimatedQuantity': quantity,
      'specialInstructions': instructions,
      'locationNote': [
        if (residentName.isNotEmpty) 'Resident: $residentName',
        if (purok != null) 'Purok: $purok',
        if (pickupLocation != null) 'Location: $pickupLocation',
        if (quantity != null) 'Quantity: $quantity',
        if (instructions != null && instructions.isNotEmpty) 'Notes: $instructions',
      ].join('\n'),
      'assignedBy': 'Admin',
    };
  }

  /// Returns the first non-null, non-empty string from [candidates].
  String? _firstNonEmpty(List<String?> candidates) {
    for (final s in candidates) {
      if (s != null && s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    _fixedScheduleSubscription?.cancel();
    _specialCollectionSubscription?.cancel();
    super.dispose();
  }
}
