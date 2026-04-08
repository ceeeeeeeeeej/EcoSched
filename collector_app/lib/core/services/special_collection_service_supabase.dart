import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SpecialCollectionService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final List<Map<String, dynamic>> _specialCollections = [];
  StreamSubscription<List<Map<String, dynamic>>>? _collectionsSubscription;
  String? _currentResidentId;

  List<Map<String, dynamic>> get specialCollections =>
      List.unmodifiable(_specialCollections);

  /// Get special collections for a specific resident
  Future<void> loadSpecialCollectionsForResident(String residentId) async {
    if (_currentResidentId == residentId && _collectionsSubscription != null) {
      return;
    }

    await _collectionsSubscription?.cancel();
    _currentResidentId = residentId;

    _collectionsSubscription = _supabase
        .from(SupabaseConfig.specialCollectionsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', residentId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _specialCollections.clear();
            _specialCollections.addAll(
              data.map((doc) {
                return {
                  'id': doc['id'].toString(),
                  ...doc,
                  'createdAt': doc['created_at'] != null
                      ? DateTime.parse(doc['created_at'])
                      : null,
                  'updatedAt': doc['updated_at'] != null
                      ? DateTime.parse(doc['updated_at'])
                      : null,
                  'preferredDate': doc['preferred_date'] != null
                      ? DateTime.parse(doc['preferred_date'])
                      : null,
                  'scheduledDate': doc['collection_date'] != null
                      ? DateTime.parse(doc['collection_date'])
                      : null,
                };
              }).toList(),
            );
            notifyListeners();
          },
          onError: (e) {
            if (kDebugMode) {
              print('Failed to load special collections for $residentId: $e');
            }
            _specialCollections.clear();
            notifyListeners();
          },
        );
  }

  /// Request a new special collection
  Future<Map<String, dynamic>> requestSpecialCollection({
    required String residentId,
    required String residentName,
    required String residentEmail,
    required String residentPhone,
    required String residentLocation,
    required String residentBarangay,
    required String residentPurok,
    required String wasteType,
    required String estimatedQuantity,
    required String estimatedSize,
    required DateTime preferredDate,
    required String preferredTime,
    required String pickupLocation,
    String specialInstructions = '',
  }) async {
    try {
      final response =
          await _supabase.from(SupabaseConfig.specialCollectionsTable).insert({
        'user_id': residentId,
        'title': 'Special Collection Request',
        'description':
            'Waste type: $wasteType, Quantity: $estimatedQuantity, Size: $estimatedSize',
        'zone': residentBarangay,
        'collection_date': preferredDate.toIso8601String(),
        'status': 'pending_payment',
        'metadata': {
          'residentName': residentName,
          'residentEmail': residentEmail,
          'residentPhone': residentPhone,
          'residentLocation': residentLocation,
          'residentBarangay': residentBarangay,
          'residentPurok': residentPurok,
          'wasteType': wasteType,
          'estimatedQuantity': estimatedQuantity,
          'estimatedSize': estimatedSize,
          'preferredTime': preferredTime,
          'pickupLocation': pickupLocation,
          'specialInstructions': specialInstructions,
          'paymentReference': '',
          'paymentProofUrl': '',
          'paymentAmount': 0,
          'paymentVerifiedBy': '',
          'scheduledTime': '',
          'cancellationReason': '',
        },
      }).select();

      if (response.isNotEmpty) {
        return {'success': true, 'id': response[0]['id'].toString()};
      } else {
        return {
          'success': false,
          'error': 'Failed to create special collection'
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting special collection: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Submit payment reference
  Future<bool> submitPaymentReference({
    required String collectionId,
    required String paymentReference,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.specialCollectionsTable).update({
        'metadata': {
          'paymentReference': paymentReference,
        },
        'status': 'payment_submitted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', collectionId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting payment reference: $e');
      }
      return false;
    }
  }

  /// Cancel a special collection request
  Future<bool> cancelRequest({
    required String collectionId,
    String reason = '',
  }) async {
    try {
      await _supabase.from(SupabaseConfig.specialCollectionsTable).update({
        'status': 'cancelled',
        'metadata': {
          'cancellationReason': reason,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', collectionId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling special collection: $e');
      }
      return false;
    }
  }

  /// Get count by status
  int getCountByStatus(String status) {
    return _specialCollections
        .where((collection) => collection['status'] == status)
        .length;
  }

  /// Get pending payment count
  int get pendingPaymentCount => getCountByStatus('pending_payment');

  /// Get active requests count (pending_payment + payment_submitted + verified + scheduled)
  int get activeRequestsCount => _specialCollections
      .where((collection) =>
          collection['status'] == 'pending_payment' ||
          collection['status'] == 'payment_submitted' ||
          collection['status'] == 'verified' ||
          collection['status'] == 'scheduled')
      .length;

  @override
  void dispose() {
    _collectionsSubscription?.cancel();
    super.dispose();
  }

  void clearAll() {
    _specialCollections.clear();
    notifyListeners();
  }
}
