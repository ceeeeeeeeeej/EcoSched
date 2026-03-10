import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

class SpecialCollectionService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  final List<Map<String, dynamic>> _specialCollections = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  List<Map<String, dynamic>> get specialCollections =>
      List.unmodifiable(_specialCollections);

  /// Load resident requests (Filtered by Device ID)
  Future<void> loadSpecialCollections() async {
    await _subscription?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final residentId = prefs.getString("resident_user_id") ??
        prefs.getString("unique_device_id") ??
        '';

    _subscription = _supabase
        .from('special_collections')
        .stream(primaryKey: ['id'])
        .eq('resident_id', residentId) // Filter by standardized resident_id
        .order('created_at', ascending: false)
        .listen((data) {
          _specialCollections.clear();

          _specialCollections.addAll(data.map((doc) {
            final status = doc['status']?.toString();
            if (kDebugMode && status == 'approved') {
              print(
                  '✅ [ACCURACY CHECK] Special Request ${doc['id']} is now APPROVED!');
            }
            return {
              'id': doc['id'],
              'residentName': doc['resident_name'],
              'residentBarangay': doc['resident_barangay'],
              'residentPurok': doc['resident_purok'],
              'wasteType': doc['waste_type'],
              'estimatedQuantity': doc['estimated_quantity'],
              'pickupLocation': doc['pickup_location'],
              'message': doc['message'],
              'status': doc['status'],
              'scheduledDate': doc['scheduled_date'] != null
                  ? DateTime.parse(doc['scheduled_date'])
                  : null,
              'scheduledTime':
                  (doc['metadata'] as Map<String, dynamic>?)?['scheduledTime'],
              'createdAt': DateTime.parse(doc['created_at']),
            };
          }));

          notifyListeners();
        });
  }

  /// Create new request
  Future<Map<String, dynamic>> requestSpecialCollection({
    required String residentName,
    required String residentBarangay,
    required String residentPurok,
    required String wasteType,
    required String estimatedQuantity,
    required String pickupLocation,
    String? message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final residentId = prefs.getString("resident_user_id") ??
          prefs.getString("unique_device_id");

      await _supabase.from('special_collections').insert({
        'resident_name': residentName,
        'resident_barangay': residentBarangay,
        'resident_purok': residentPurok,
        'waste_type': wasteType,
        'estimated_quantity': estimatedQuantity,
        'pickup_location': pickupLocation,
        'message': message,
        'status': 'pending',
        'resident_id': residentId, // Use standardized resident_id
        'created_at': DateTime.now().toIso8601String(),
      });

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cancel request
  Future<bool> cancelRequest({
    required String collectionId,
  }) async {
    try {
      await _supabase
          .from('special_collections')
          .update({'status': 'cancelled'}).eq('id', collectionId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Admin load all requests
  Future<void> loadAllRequests() async {
    await _subscription?.cancel();

    _subscription = _supabase
        .from('special_collections')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((data) {
          if (kDebugMode) print('📩 Supabase Stream Data: $data');
          _specialCollections.clear();

          _specialCollections.addAll(data.map((doc) {
            return {
              'id': doc['id'],
              'residentName': doc['resident_name'],
              'residentBarangay': doc['resident_barangay'],
              'residentPurok': doc['resident_purok'],
              'wasteType': doc['waste_type'],
              'estimatedQuantity': doc['estimated_quantity'],
              'pickupLocation': doc['pickup_location'],
              'message': doc['message'],
              'status': doc['status'],
              'scheduledDate': doc['scheduled_date'] != null
                  ? DateTime.tryParse(doc['scheduled_date'].toString())
                  : null,
              'createdAt': doc['created_at'] != null
                  ? DateTime.tryParse(doc['created_at'].toString())
                  : DateTime.now(),
            };
          }).toList());

          notifyListeners();
        });
  }

  /// Admin update status
  Future<bool> updateStatus({
    required String collectionId,
    required String newStatus,
  }) async {
    try {
      await _supabase
          .from('special_collections')
          .update({'status': newStatus}).eq('id', collectionId);

      return true;
    } catch (e) {
      return false;
    }
  }
}
