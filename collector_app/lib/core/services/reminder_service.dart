import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'pickup_service.dart';
import 'notification_service.dart';
import '../config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/translations.dart';

class ReminderService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Timer? _reminderCheckTimer;
  final List<Map<String, dynamic>> _reminders = [];

  String? _currentServiceArea;

  final Set<String> _sentReminderKeys = {};
  StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
  Set<String> _localReadIds = {};
  Set<String> _localNotifiedIds = {};

  List<Map<String, dynamic>> get reminders => List.unmodifiable(_reminders);

  int get unreadCount =>
      _reminders.where((r) => (r['read'] as bool?) != true).length;

  void markAsRead(dynamic id) async {
    final idStr = id.toString();
    final index = _reminders.indexWhere((r) => r['id'].toString() == idStr);
    if (index == -1) return;

    _reminders[index] = {
      ..._reminders[index],
      'read': true,
    };
    notifyListeners();

    _localReadIds.add(idStr);
    await _saveLocalReadIds();

    // Persist to database if it's a persistent notification (UUID)
    if (idStr.length > 30) {
      _supabase
          .from(SupabaseConfig.notificationsTable)
          .update({'is_read': true})
          .eq('id', idStr)
          .then((_) => null)
          .catchError((e) {
        if (kDebugMode) print('Supabase update failed, relying on local state: $e');
      });
    }
  }

  void markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _reminders.length; i++) {
      if ((_reminders[i]['read'] as bool?) == true) continue;

      final id = _reminders[i]['id'];
      _reminders[i] = {
        ..._reminders[i],
        'read': true,
      };

      final idStr = id.toString();
      _localReadIds.add(idStr);
      
      // Persist to database for historical notifications
      if (idStr.length > 30) {
        _supabase
            .from(SupabaseConfig.notificationsTable)
            .update({'is_read': true})
            .eq('id', idStr)
            .then((_) => null)
            .catchError((e) {
          if (kDebugMode) print('Supabase update failed: $e');
        });
      }

      changed = true;
    }
    await _saveLocalReadIds();
    
    if (changed) {
      notifyListeners();
    }
  }

  void clearSystemTray() {
    NotificationService.clearAllNotifications();
  }

  Future<void> _loadLocalReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localReadIds = (prefs.getStringList('local_read_notifications') ?? []).toSet();
    } catch (e) {
      if (kDebugMode) print('Error loading local read state: $e');
    }
  }

  Future<void> _saveLocalReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_read_notifications', _localReadIds.toList());
    } catch (e) {
      if (kDebugMode) print('Error saving local read state: $e');
    }
  }

  Future<void> _loadLocalNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _localNotifiedIds = (prefs.getStringList('local_notified_notifications') ?? []).toSet();
    } catch (e) {
      if (kDebugMode) print('Error loading local notified state: $e');
    }
  }

  Future<void> _saveLocalNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_notified_notifications', _localNotifiedIds.toList());
    } catch (e) {
      if (kDebugMode) print('Error saving local notified state: $e');
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
      _cancelNotificationSubscription();
      _reminders.clear();
      notifyListeners();
      return;
    }

    if (_currentServiceArea != serviceArea) {
      _currentServiceArea = serviceArea;
      _sentReminderKeys.clear();
      _fetchNotifications();
      _startNotificationListener();

      if (kDebugMode) {
        print('🛠️ ReminderService: Service area changed to $serviceArea');
      }
    }
  }

  void initialize() {
    if (kDebugMode) print('🛠️ ReminderService: Initializing system...');
    // Timer-based local collection checks have been disabled in favor of Supabase Cron.
  }

  void _cancelNotificationSubscription() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    String str = value.toString();
    if (!str.contains('Z') && !str.contains('+') && str.contains('T')) {
      str += 'Z';
    }
    return DateTime.tryParse(str)?.toUtc() ?? DateTime.now();
  }

  Future<void> _fetchNotifications() async {
    try {
      await _loadLocalReadIds();
      await _loadLocalNotifiedIds();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final serviceArea = _currentServiceArea ?? 'all';

      // Fetch personal notifications
      final response = await _supabase
          .from(SupabaseConfig.notificationsTable)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      // Fetch community announcements
      final announcementsResponse = await _supabase
          .from(SupabaseConfig.announcementsTable)
          .select()
          .or('target_audience.eq.$serviceArea,target_audience.eq.all')
          .order('created_at', ascending: false)
          .limit(50);

      _reminders.clear();
      for (final doc in response) {
        final idStr = doc['id'].toString();
        final title = doc['title']?.toString() ?? '';
        
        bool isAdminOnly = title.toLowerCase().contains('pickup request') && 
                          !title.toLowerCase().contains('special collection');
        
        if (isAdminOnly && !title.toUpperCase().contains('NEW SPECIAL COLLECTION')) {
          continue;
        }

        _reminders.add({
          'id': doc['id'],
          'title': Translations.getBilingualText(doc['title']?.toString() ?? 'Notification'),
          'message': Translations.getBilingualText(doc['message']?.toString() ?? ''),
          'type': doc['type'],
          'read': _localReadIds.contains(idStr) ? true : (doc['is_read'] ?? false),
          'createdAt': _parseTimestamp(doc['created_at']),
        });
      }

      for (final doc in announcementsResponse) {
        _reminders.add({
          'id': doc['id'],
          'title': Translations.getBilingualText(doc['title']?.toString() ?? 'Announcement'),
          'message': Translations.getBilingualText((doc['content'] ?? doc['message'])?.toString() ?? ''),
          'type': 'announcement',
          'read': _localReadIds.contains(doc['id'].toString()), 
          'createdAt': _parseTimestamp(doc['created_at']),
        });
      }

      _reminders.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching notifications: $e');
    }
  }

  void _startNotificationListener() {
    _cancelNotificationSubscription();
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _notificationSubscription = _supabase
        .from(SupabaseConfig.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen(
          (data) {
            bool changed = false;
            for (final doc in data) {
              final idStr = doc['id'].toString();
              final title = doc['title']?.toString() ?? '';
              bool isAdminOnly = title.toLowerCase().contains('pickup request') && 
                                !title.toLowerCase().contains('special collection');
              
              if (isAdminOnly && !title.toUpperCase().contains('NEW SPECIAL COLLECTION')) {
                continue;
              }
              
              final existsIndex = _reminders.indexWhere((r) => r['id'].toString() == idStr);

              if (existsIndex != -1) {
                final bool localIsRead = _reminders[existsIndex]['read'] == true || _localReadIds.contains(idStr);
                final bool newIsRead = doc['is_read'] == true;
                
                _reminders[existsIndex] = {
                  ..._reminders[existsIndex],
                  'title': Translations.getBilingualText(doc['title']?.toString() ?? 'Notification'),
                  'message': Translations.getBilingualText(doc['message']?.toString() ?? ''),
                  'type': doc['type'],
                  'read': localIsRead || newIsRead,
                };
                changed = true;
                continue;
              }

              _reminders.insert(0, {
                'id': doc['id'],
                'title': Translations.getBilingualText(doc['title']?.toString() ?? 'Notification'),
                'message': Translations.getBilingualText(doc['message']?.toString() ?? ''),
                'type': doc['type'],
                'read': _localReadIds.contains(idStr) ? true : (doc['is_read'] ?? false),
                'createdAt': _parseTimestamp(doc['created_at']),
              });
              changed = true;

              final createdAt = _parseTimestamp(doc['created_at']);
              final bool isUrgentType = doc['type'] == 'alert' || 
                                     doc['type'] == 'special_collection' || 
                                     doc['type'] == 'pickup_request';

              if (isUrgentType &&
                  (doc['is_read'] == null || doc['is_read'] == false) &&
                  !_localNotifiedIds.contains(idStr) &&
                  DateTime.now().difference(createdAt).abs().inMinutes < 60) {
                
                _localNotifiedIds.add(idStr);
                _saveLocalNotifiedIds();

                NotificationService.showNotification(
                  id: doc['id'].hashCode & 0x7FFFFFFF,
                  title: doc['title'] ?? 'New Alert',
                  body: doc['message'] ?? 'You have a new notification',
                );
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
                    _localNotifiedIds.add(id.toString());
                    _saveLocalNotifiedIds();

                    _reminders.insert(0, {
                      'id': id,
                      'title': Translations.getBilingualText(newRecord['title']?.toString() ?? 'Announcement'),
                      'message': Translations.getBilingualText((newRecord['content'] ?? newRecord['message'])?.toString() ?? ''),
                      'type': 'announcement',
                      'read': false,
                      'createdAt': _parseTimestamp(newRecord['created_at']),
                    });

                    _reminders.sort((a, b) => (b['createdAt'] as DateTime)
                        .compareTo(a['createdAt'] as DateTime));
                    notifyListeners();

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

  void setPickupService(PickupService service) {
    // This method remains for compatibility with Provider architecture, but logic is disabled.
    notifyListeners();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    _cancelNotificationSubscription();
    super.dispose();
  }
}
