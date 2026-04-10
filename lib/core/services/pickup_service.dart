import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecosched/core/services/notification_service.dart';
import '../config/supabase_config.dart';
import '../localization/translations.dart';

class PickupService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final List<Map<String, dynamic>> _scheduledPickups = [];
  final Map<String, List<Map<String, dynamic>>> _fixedSchedules = {};
  final Set<String> _notifiedOnTheWayIds = {};
  final Set<String> _notifiedRescheduledIds = {};
  final Set<String> _notifiedStartedZonesToday = {};
  final Set<String> _processedScheduleIds = {}; // Track IDs to detect NEW assignments
  List<Map<String, dynamic>> _lastStreamedSchedules = [];
  bool _isLastCollector = false;
  bool _remindersScheduled = false; // Flag to prevent duplicate scheduling in same cycle

  List<Map<String, dynamic>> get scheduledPickups =>
      List.unmodifiable(_scheduledPickups);

  String? get currentServiceArea => _currentServiceArea;

  /// Returns a set of normalized dates (midnight) that have scheduled pickups.
  Set<DateTime> get scheduledDates => _scheduledPickups
      .map<DateTime>((pickup) => _normalizeDate(pickup['date'] as DateTime))
      .toSet();

  /// Helper used by calendar views to highlight days with a schedule.
  bool hasPickupOn(DateTime date) {
    final normalized = _normalizeDate(date);
    return scheduledDates.contains(normalized);
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
    final todayNormalized = _normalizeDate(now);

    final upcoming = _scheduledPickups.where((pickup) {
      final pickupArea = (pickup['address'] ?? '').toString().toLowerCase();
      final String effectiveArea = serviceArea.toString().trim().toLowerCase();
      final pickupDate = pickup['date'] as DateTime;
      final pickupDateNormalized = _normalizeDate(pickupDate);

      // Match area
      final bool areaMatch = pickupArea.contains(effectiveArea) ||
          effectiveArea.contains(pickupArea);

      // Include if it's strictly in the future OR if it's any time TODAY
      final bool isFutureOrToday =
          pickupDate.isAfter(now) || pickupDateNormalized == todayNormalized;

      return areaMatch && isFutureOrToday;
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return upcoming.first;
  }

  StreamSubscription<List<Map<String, dynamic>>>? _scheduleSubscription;
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
    // Only clear trackers if the barangay ACTUALLY changed
    if (_currentServiceArea != normalizedArea) {
      _notifiedOnTheWayIds.clear();
      _notifiedRescheduledIds.clear();
    }

    _currentServiceArea = normalizedArea;
    _isLastCollector = isCollector;

    // Clear stale data when switching areas
    _lastStreamedSchedules.clear();
    _scheduledPickups.clear();
    notifyListeners();

    // Load fixed schedules first
    await _loadFixedSchedules();

    // Then load regular schedules
    _scheduleSubscription = _supabase
        .from(SupabaseConfig.collectionSchedulesTable)
        .stream(primaryKey: ['id'])
        // Removed zone filter to allow multi-area notifications
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

        // [INSTANT ASSIGNMENT ALERT] Notify if a brand new schedule is detected
        for (final schedule in _lastStreamedSchedules) {
          final id = schedule['id'].toString();
          if (!_processedScheduleIds.contains(id)) {
            _processedScheduleIds.add(id);
            _handleNewScheduleAlert(schedule);
          }
        }

        _rebuildScheduledPickups(isCollector: isCollector);
      },
      onError: (e) {
        if (kDebugMode) {
          print('Failed to load schedules for $serviceArea: $e');
        }
      },
    );
  }

  void _handleNewScheduleAlert(Map<String, dynamic> schedule) {
    final area = (schedule['address'] ?? '').toString().toLowerCase();
    final current = _currentServiceArea?.toLowerCase();
    if (current == null || !area.contains(current)) return;

    // Only notify for literal scheduled items (not historical ones)
    if (schedule['status']?.toString().toLowerCase() != 'scheduled') return;

    final date = schedule['date'] as DateTime;
    final formattedDate = DateFormat('EEEE, MMM d').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);

    // Show instant notification
    NotificationService.showNotification(
      id: schedule['id'].hashCode & 0x7FFFFFFF,
      title: 'New Collection Scheduled | Bag-ong Eskedyul',
      body:
          'A new collection has been set for $current on $formattedDate at $formattedTime. \n\n Adunay bag-ong pagkolekta sa $current.',
    );
  }

  Future<void> _loadFixedSchedules() async {
    try {
      if (kDebugMode) {
        print(
            '📡 PickupService: Attempting to fetch fixed schedules via SELECT...');
      }

      final data =
          await _supabase.from(SupabaseConfig.areaSchedulesTable).select('*');

      if (kDebugMode) {
        print('📡 PickupService: Successfully connected to Supabase.');
        print(
            '📡 PickupService: Found ${data.length} total records in area_schedules table.');
        if (data.isNotEmpty) {
          print('📡 PickupService: Sample record from DB: ${data.first}');
        }
      }

      _fixedSchedules.clear();
      for (final doc in data) {
        final area = (doc['area'] ?? '').toString().trim().toLowerCase();
        if (kDebugMode) {
          print(
              '   - Fixed Schedule: ID=${doc['id']}, Area=$area, Active=${doc['is_active']}');
        }
        if (area.isNotEmpty) {
          final schedule = {
            'id': doc['id'],
            'area': doc['area'],
            'scheduleName': doc['schedule_name'] ?? doc['scheduleName'],
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ PickupService: Error fetching fixed schedules: $e');
      }
    }
  }

  void _rebuildScheduledPickups({bool? isCollector}) {
    if (_currentServiceArea == null) return;

    final actualIsCollector = isCollector ?? _isLastCollector;
    final Map<String, Map<String, dynamic>> itemsMap = {};

    // 1. Add streamed schedules (highest priority)
    final String currentArea = _currentServiceArea?.toLowerCase().trim() ?? '';
    for (final doc in _lastStreamedSchedules) {
      // For residents, strictly filter to their own area
      // For collectors, we keep all streamed items in the current zone stream
      if (!_isLastCollector && currentArea.isNotEmpty) {
        final String docArea = (doc['address'] ?? '').toString().toLowerCase().trim();
        if (!docArea.contains(currentArea) && !currentArea.contains(docArea)) {
          continue; // Skip this schedule as it belongs to another barangay
        }
      }
      
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

    // Notify residents if scheduled items changed (Wait: _scheduleReminders already does this)
    // We removed the old direct NotificationService loop here to prevent flooding
    notifyListeners();
  }

  List<Map<String, dynamic>> _generateSchedulesFromFixed(
    String serviceArea,
    Set<DateTime> excludedDates,
  ) {
    final searchKey = serviceArea.trim().toLowerCase();

    // Improved matching: find all fixed schedules that match the service area string
    final List<Map<String, dynamic>> fixedList = [];
    _fixedSchedules.forEach((areaKey, list) {
      if (searchKey.contains(areaKey) || areaKey.contains(searchKey)) {
        for (final s in list) {
          // Add the areaKey to each item so we can use it for ID generation later
          fixedList.add({...s, 'area_key': areaKey});
        }
      }
    });

    if (fixedList.isEmpty) {
      if (kDebugMode) {
        print(
            '📡 PickupService: No fixed schedules found in memory for search key: "$searchKey"');
        print(
            '📡 PickupService: Current keys in memory: ${_fixedSchedules.keys.toList()}');
      }
      return [];
    }

    return _generateSchedulesFromList(fixedList, excludedDates, searchKey);
  }

  List<Map<String, dynamic>> _generateSchedulesFromList(
    List<Map<String, dynamic>> fixedList,
    Set<DateTime> excludedDates,
    String searchKey,
  ) {
    final schedules = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (final fixed in fixedList) {
      final areaKey = fixed['area_key']?.toString() ?? 'Area';
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
            // Include time in ID to allow multiple schedules on the same day
            final timeKey = fixedTimeValue.replaceAll(':', '');
            schedules.add({
              'id': 'fixed_${areaKey}_${dateKey}_$timeKey',
              'address': areaKey,
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

    // Extract time string from local date (Proper Local Time)
    String timeStr = '';
    if (rawDate != null) {
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      timeStr =
          "${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $ampm";
    }

    final String description = (data['description'] ?? '').toString();
    final String nameField = (data['name'] ?? '').toString();
    String? residentName;
    String? pickupLocation;
    String? residentAge;
    String? specialNotes;
    String? wasteType;
    String? estimatedQuantityFromDesc;

    // Extract waste type from the 'name' column: 'Special Collection: {wasteType}'
    if (nameField.toLowerCase().startsWith('special collection:')) {
      wasteType = nameField
          .replaceFirst(
              RegExp(r'special collection:\s*', caseSensitive: false), '')
          .trim();
    }

    // Parse description: 'Location: {addr}, Resident: {name}, Age: {age}, Quantity: {qty}, Message: {msg}'
    if (description.contains('Location:') &&
        description.contains('Resident:')) {
      try {
        final locPart =
            description.split('Location:').last.split(', Resident:').first;
        final afterResident = description.split('Resident:').last;
        pickupLocation = locPart.trim();

        // Extract Name
        if (afterResident.contains(', Age:')) {
          residentName = afterResident.split(', Age:').first.trim();
          final afterAge = afterResident.split(', Age:').last;

          // Extract Age
          if (afterAge.contains(', Quantity:')) {
            residentAge = afterAge.split(', Quantity:').first.trim();
            final afterQty = afterAge.split(', Quantity:').last;
            if (afterQty.contains(', Message:')) {
              // We have quantity AND message
            } else {
              residentAge = afterAge.split(',').first.trim();
            }
          } else if (afterAge.contains(', Message:')) {
            residentAge = afterAge.split(', Message:').first.trim();
          } else {
            residentAge = afterAge.split(',').first.trim();
          }
        } else if (afterResident.contains(', Message:')) {
          residentName = afterResident.split(', Message:').first.trim();
        } else {
          residentName = afterResident.split(',').first.trim();
        }

        // Extract Quantity
        if (description.contains(', Quantity:')) {
          final afterQty = description.split(', Quantity:').last;
          final qtyRaw = afterQty.contains(', Message:')
              ? afterQty.split(', Message:').first.trim()
              : afterQty.split(',').first.trim();
          if (qtyRaw.isNotEmpty) estimatedQuantityFromDesc = qtyRaw;
        }

        // Extract Message
        if (description.contains(', Message:')) {
          specialNotes = description.split(', Message:').last.trim();
        }
      } catch (e) {
        if (kDebugMode) print('Error parsing special collection details: $e');
      }
    }

    // Append zone/barangay to location so it shows "loc, street, Barangay"
    final String zone = (data['zone'] ?? '').toString();
    final String fullLocation =
        (pickupLocation != null && pickupLocation.isNotEmpty && zone.isNotEmpty)
            ? '$pickupLocation, $zone'
            : (pickupLocation ?? zone);

    return {
      'id': id,
      'address': zone.isNotEmpty ? zone : 'Assigned Area',
      'type': 'Eco Collection',
      'isSpecialCollection': nameField.toLowerCase().contains('special') ||
          description.toLowerCase().contains('special'),
      'description': description,
      'wasteType': wasteType,
      'estimatedQuantity':
          estimatedQuantityFromDesc ?? data['estimated_quantity']?.toString(),
      'specialNotes': specialNotes ?? data['special_instructions']?.toString(),
      'residentName': residentName,
      'residentAge': residentAge,
      'pickupLocation': fullLocation,
      'time': timeStr.isNotEmpty ? timeStr : '08:00',
      'date': date,
      'status': (data['status'] ?? 'Scheduled').toString(),
      'locationNote': description,
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
    _scheduleSubscription = null;
    _currentServiceArea = null;
    clearAll();
  }

  Future<void> _scheduleReminders({bool isCollector = false}) async {
    if (_remindersScheduled) {
      if (kDebugMode) print('⏳ PickupService: _scheduleReminders skipped (already in progress)');
      return;
    }
    _remindersScheduled = true;

    if (kDebugMode) {
      print(
          '🛠️ PickupService: _scheduleReminders called (isCollector: $isCollector)');
      print('   - Scheduled pickups count: ${_scheduledPickups.length}');
    }

    // 1. Clear ALL existing scheduled notifications to avoid duplicates/stale alerts
    // (This ensures when we rebuild, we don't have old reminders for deleted/changed schedules)
    await NotificationService.cancelAllScheduledNotifications();

    final now = DateTime.now();
    // --- ULTIMATE PRE-REMINDER DEDUPLICATION (CONSTANT IDENTITY) ---
    // If we have 100 duplicate entries, process only ONE per 4-hour window per area.
    // --- ULTIMATE PRE-REMINDER DEDUPLICATION (TRUE AREA STABILIZATION) ---
    // If we have "Victoria", "Victoria St", "Victoria Area", process only ONE.
    final Map<String, Map<String, dynamic>> dedupedMap = {};
    for (final pickup in _scheduledPickups) {
      final String rawAddress = (pickup['address'] ?? 'Unknown').toString();
      final DateTime date = pickup['date'] as DateTime;

      // Normalize Address: Extract the main Barangay name
      // (Handles "Victoria, High Street" -> "victoria")
      final String baseArea = rawAddress.split(',')[0].toLowerCase().trim();

      // Calculate a 4-hour slot ID (0-3, 4-7, 8-11, etc.)
      final int fourHourSlot = date.hour ~/ 4;
      final slotKey = "${date.year}_${date.month}_${date.day}_$fourHourSlot";
      final String key = "${baseArea}_$slotKey";

      final existing = dedupedMap[key];
      if (existing == null) {
        dedupedMap[key] = pickup;
      } else {
        // Prioritize 'on_the_way' status over 'Scheduled'
        final String newStatus =
            pickup['status']?.toString().toLowerCase() ?? '';
        final String oldStatus =
            existing['status']?.toString().toLowerCase() ?? '';
        if (newStatus == 'on_the_way' && oldStatus != 'on_the_way') {
          dedupedMap[key] = pickup;
        }
      }
    }

    for (final pickup in dedupedMap.values) {
      final String originalAddress =
          (pickup['address'] ?? 'Unknown').toString();
      final String baseArea = originalAddress.split(',')[0].trim();
      final DateTime date = pickup['date'] as DateTime;
      final String timeStr = pickup['time']?.toString() ?? '8:00';

      // --- RESIDENT REMINDERS ---

      final String baseAreaLower = baseArea.toLowerCase();
      final bool isHomeBarangay = _currentServiceArea != null &&
          baseAreaLower.contains(_currentServiceArea!.toLowerCase());

      // 4-Hour Stable ID: Forces Android to stack notifications for this slot
      final int fourHourSlot = date.hour ~/ 4;
      final slotKey = "${date.year}_${date.month}_${date.day}_$fourHourSlot";
      final String contentKey = "${baseAreaLower}_$slotKey";

      // STABLE ID: Based ONLY on Barangay Name and Time Slot.
      // This is the absolute guarantee that your phone will only show one row!
      final int stableId = (contentKey.hashCode & 0x7FFFFFFF);

      if (isCollector) {
        // --- COLLECTOR REMINDERS ---
        // 1. 30 minutes before
        final reminderDate = date.subtract(const Duration(minutes: 30));
        if (reminderDate.isAfter(now)) {
          await NotificationService.scheduleNotification(
            id: stableId + 10,
            title:
                Translations.getBilingualText('🚛 Collection Starting Soon!'),
            body: Translations.getBilingualText(
                'You have a collection scheduled for $baseArea in 30 minutes.'),
            scheduledDate: reminderDate,
            payload: 'collector_schedule_$stableId',
          );
        }
      } else {
        // --- SCHEDULING LOGIC ---
        // 1. Instant Alert / "On the way"
        final bool isToday = _normalizeDate(date) == _normalizeDate(now);
        final bool statusActive =
            pickup['status']?.toString().toLowerCase() == 'on_the_way' &&
                isToday;
        // Allow a 5-minute window for "instant" alerts if time is very close
        final bool timeActive = date.isAfter(now) &&
            date.difference(now).inMinutes <= 30 &&
            isToday;

        if ((statusActive || timeActive) &&
            !_notifiedOnTheWayIds.contains(contentKey)) {
          _notifiedOnTheWayIds.add(contentKey);
          final String title =
              isHomeBarangay ? '🚛 Truck Coming Now!' : '🚛 Collector On Route';
          final String body = isHomeBarangay
              ? 'Get ready! Waste Pickup is starting in $baseArea very soon.'
              : 'The collector is on the way to $baseArea!';

          if (kDebugMode) print('📢 [ALARM] Triggering INSTANT alert for $baseArea');
          await NotificationService.showNotification(
            id: stableId + 100,
            title: title,
            body: body,
            payload: 'immediate_schedule_$stableId',
          );
        }

        // --- STOP HERE FOR NEIGHBORING BARANGAYS ---
        // As requested, only "On the way" notifications are sent for neighboring areas.
        if (!isHomeBarangay) continue;

        // 3. 1 Hour Before Reminder
        final DateTime oneHourBefore = date.subtract(const Duration(hours: 1));
        if (oneHourBefore.isAfter(now)) {
          if (kDebugMode) print('📢 [ALARM READY] "1 Hour Before" for $baseArea at $oneHourBefore (ID: ${stableId + 300})');
          await NotificationService.scheduleNotification(
            id: stableId + 300,
            title: '🛣️ Put Your Garbage Out',
            body: 'Your collection in $baseArea is in 1 hour. Kindly place your garbage in the designated area.\n(Ang koleksyon sa basura sa $baseArea magsugod sulod sa 1 ka oras. Palihug ibutang ang inyong basura sa designated area.)',
            scheduledDate: oneHourBefore,
            payload: 'soon_$stableId',
          );
        }

        // 4. Day Before Reminder (6:00 PM)
        final DateTime dayBefore = DateTime(date.year, date.month, date.day - 1, 18, 0);
        if (dayBefore.isAfter(now)) {
          if (kDebugMode) print('📢 [ALARM READY] "Day Before" for $baseArea at $dayBefore (ID: ${stableId + 500})');
          await NotificationService.scheduleNotification(
            id: stableId + 500,
            title: '📅 Collection Tomorrow',
            body: 'Heads up! Your eco collection in $baseArea is scheduled for tomorrow at $timeStr. Please prepare your garbage in advance.\n(Pahibalo! Ang koleksyon sa basura sa $baseArea naka-schedule ugma alas $timeStr. Palihug andama daan ang inyong basura.)',
            scheduledDate: dayBefore,
            payload: 'tomorrow_$stableId',
          );
        }

        // 5. Exact Time Reminder
        // Use a 30-second grace period for instant feedback
        final DateTime graceThreshold = now.subtract(const Duration(seconds: 30));
        if (date.isAfter(graceThreshold)) {
          if (kDebugMode) print('📢 [ALARM READY] "Exact Time" for $baseArea at $date (ID: ${stableId + 400})');
          await NotificationService.scheduleNotification(
            id: stableId + 400,
            title: '⏰ Collection Time',
            body: 'The collection truck is expected to arrive in $baseArea shortly. Please ensure your garbage is ready for pickup.\n(Ang trak sa koleksyon gilauman nga moabot sa $baseArea sa dili madugay. Palihug siguroha nga andam na ang inyong basura.)',
            scheduledDate: date,
            payload: 'exact_schedule_$stableId',
          );
        }
      }
    }
    _remindersScheduled = false;
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
      final String todayKey =
          "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}_$zone";
      if (_notifiedStartedZonesToday.contains(todayKey)) {
        if (kDebugMode)
          print('ℹ️ Notification for $zone already sent today. Skipping.');
        return;
      }
      _notifiedStartedZonesToday.add(todayKey);

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
          .filter('barangay', 'ilike', '%$zone%');

      final List<Map<String, dynamic>> allNotifications = [];
      final now = DateTime.now().toIso8601String();
      final todayDate = DateTime.now().toIso8601String().split('T').first;

      if (admins.isNotEmpty) {
        allNotifications.addAll(admins.map((admin) {
          return {
            'user_id': admin['id'],
            'title': 'Collection Started',
            'message':
                'Collector $collectorName has started collection in $zone.',
            'type': 'alert',
            'read': false,
            'created_at': now,
            'barangay': zone,
          };
        }));
      }

      if (residents.isNotEmpty) {
        for (var resident in residents) {
          final residentId = resident['id'];

          // --- CLEANUP DUPLICATES ---
          // Delete any generic "Starting Now" alerts from today for this user
          // so they only see the "Incoming" one.
          await _supabase
              .from(SupabaseConfig.notificationsTable)
              .delete()
              .eq('user_id', residentId)
              .eq('barangay', zone)
              .ilike('title', '%Starting Now%')
              .gte('created_at', '${todayDate}T00:00:00Z');

          allNotifications.add({
            'user_id': residentId,
            'title': 'Collector is Incoming! 🚚',
            'message':
                'Stay alert! Collector $collectorName is on the way to $zone. Your collection is starting soon!',
            'type': 'info',
            'read': false,
            'created_at': now,
            'barangay': zone,
          });
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

  @override
  void dispose() {
    _scheduleSubscription?.cancel();
    super.dispose();
  }
}
