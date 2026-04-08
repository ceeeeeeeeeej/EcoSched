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

  Future<void> loadSpecialCollectionsForResident(String residentId) async {
    if (_currentResidentId == residentId && _collectionsSubscription != null) {
      return;
    }

    await _collectionsSubscription?.cancel();
    _currentResidentId = residentId;

    _collectionsSubscription = _supabase
        .from(SupabaseConfig.specialCollectionsTable)
        .stream(primaryKey: ['id'])
        .eq('resident_id', residentId)
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _specialCollections.clear();
            _specialCollections.addAll(
              data.map((doc) {
                // Extract metadata for fields not in schema columns
                final metadata = doc['metadata'] as Map<String, dynamic>? ?? {};
                return _mapDocToModel(doc, metadata);
              }).toList(),
            );
            notifyListeners();
          },
          onError: (e) {
            if (kDebugMode) {
              print('Failed to load special collections for $residentId: $e');
            }
            // Allow empty list on error
            _specialCollections.clear();
            notifyListeners();
          },
        );
  }

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
      // Pack extra fields into metadata JSON
      final metadata = {
        'resident_name': residentName,
        'resident_email': residentEmail,
        'resident_phone': residentPhone,
        'resident_location': residentLocation,
        'resident_barangay': residentBarangay,
        'resident_purok': residentPurok,
        'estimated_size': estimatedSize,
      };

      final response =
          await _supabase.from(SupabaseConfig.specialCollectionsTable).insert({
        'resident_id': residentId,
        // Optional: if columns exist, they will be filled. If not, they are in metadata.
        // We will TRY to fill columns if they exist in schema (e.g. waste_type)
        'waste_type': wasteType,
        'estimated_quantity': '$estimatedQuantity ($estimatedSize)',
        'preferred_date': preferredDate.toIso8601String(),
        'preferred_time': preferredTime,
        'pickup_location': pickupLocation,
        'special_instructions': specialInstructions,
        'status': 'pending_payment',
        'metadata': metadata, // Storing extras here
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        final newDoc = response[0];
        // build a model object similar to mapping used elsewhere
        final metadata = newDoc['metadata'] as Map<String, dynamic>? ?? {};
        final entry = _mapDocToModel(newDoc, metadata);
        // add to top of list and notify listeners
        _specialCollections.insert(0, entry);
        notifyListeners();
        return {'success': true, 'id': newDoc['id'].toString()};
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

  Future<bool> submitPaymentReference({
    required String collectionId,
    required String paymentReference,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.specialCollectionsTable).update({
        'payment_reference': paymentReference,
        'status': 'payment_submitted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', collectionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelRequest({
    required String collectionId,
    String reason = '',
  }) async {
    try {
      await _supabase.from(SupabaseConfig.specialCollectionsTable).update({
        'status': 'cancelled',
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', collectionId);
      return true;
    } catch (e) {
      return false;
    }
  }
  // ---------------------------------------------------------------------------
  // ADMIN & COLLECTOR METHODS
  // ---------------------------------------------------------------------------

  /// Load ALL special collection requests (for Admin/Collector)
  Future<void> loadAllRequests() async {
    // If we are already listening to a specific resident, cancel that first
    // to avoid mixing data streams.
    await _collectionsSubscription?.cancel();
    _currentResidentId = null;

    _collectionsSubscription = _supabase
        .from(SupabaseConfig.specialCollectionsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
          (data) {
            _specialCollections.clear();
            _specialCollections.addAll(
              data.map((doc) {
                final metadata = doc['metadata'] as Map<String, dynamic>? ?? {};
                return _mapDocToModel(doc, metadata);
              }).toList(),
            );
            notifyListeners();
          },
          onError: (e) {
            if (kDebugMode) {
              print('Failed to load ALL special collections: $e');
            }
            _specialCollections.clear();
            notifyListeners();
          },
        );
  }

  /// Update the status of a request (e.g., 'verified', 'completed')
  Future<bool> updateStatus({
    required String collectionId,
    required String newStatus,
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reason != null && reason.isNotEmpty) {
        // If it's a cancellation or rejection, store the reason in metadata
        // We need to fetch current metadata first to avoid overwriting other fields
        // But for simplicity/speed in this migration, we'll try to just update the specific field if possible
        // OR we can rely on Supabase to merge if we use a jsonb update, but Supabase Dart
        // might replace the whole JSON object.
        // Safer approach: Fetch, Update, Push.
        final doc = await _supabase
            .from(SupabaseConfig.specialCollectionsTable)
            .select('metadata')
            .eq('id', collectionId)
            .single();

        final currentMetadata = doc['metadata'] as Map<String, dynamic>? ?? {};
        currentMetadata['statusReason'] = reason;
        updates['metadata'] = currentMetadata;
      }

      await _supabase
          .from(SupabaseConfig.specialCollectionsTable)
          .update(updates)
          .eq('id', collectionId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating status: $e');
      }
      return false;
    }
  }

  /// Update the schedule (Date & Time)
  Future<bool> updateSchedule({
    required String collectionId,
    required DateTime scheduledDate,
    required String scheduledTime,
  }) async {
    try {
      await _supabase.from(SupabaseConfig.specialCollectionsTable).update({
        'scheduled_date': scheduledDate.toIso8601String(),
        // Store time in metadata if no column exists, or we could add a column.
        // Based on previous analysis, we used 'scheduled_date' column.
        // We'll store the time string in metadata for display.
        // Fetch current metadata first
        'status': 'scheduled', // Auto-update status to scheduled
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', collectionId);

      // We also need to update metadata for the specific time string
      final doc = await _supabase
          .from(SupabaseConfig.specialCollectionsTable)
          .select('metadata')
          .eq('id', collectionId)
          .single();

      final currentMetadata = doc['metadata'] as Map<String, dynamic>? ?? {};
      currentMetadata['scheduledTime'] = scheduledTime;

      await _supabase
          .from(SupabaseConfig.specialCollectionsTable)
          .update({'metadata': currentMetadata}).eq('id', collectionId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating schedule: $e');
      }
      return false;
    }
  }

  // Helper to map DB document to our internal model
  Map<String, dynamic> _mapDocToModel(
      Map<String, dynamic> doc, Map<String, dynamic> metadata) {
    return {
      'id': doc['id'].toString(),
      ...doc,
      'residentId': doc['resident_id'],
      'residentName': doc['resident_name'] ?? metadata['resident_name'],
      'residentEmail': doc['resident_email'] ?? metadata['resident_email'],
      'residentPhone': doc['resident_phone'] ?? metadata['resident_phone'],
      'residentLocation':
          doc['resident_location'] ?? metadata['resident_location'],
      'residentBarangay':
          doc['resident_barangay'] ?? metadata['resident_barangay'],
      'residentPurok': doc['resident_purok'] ?? metadata['resident_purok'],
      'wasteType': doc['waste_type'],
      'estimatedQuantity': doc['estimated_quantity'],
      'preferredDate': doc['preferred_date'] != null
          ? DateTime.parse(doc['preferred_date'])
          : null,
      'preferredTime': doc['preferred_time'],
      'pickupLocation': doc['pickup_location'],
      'specialInstructions': doc['special_instructions'],
      'paymentReference': doc['payment_reference'],
      'paymentAmount': doc['payment_amount'],
      'status': doc['status'],
      'scheduledDate': doc['scheduled_date'] != null
          ? DateTime.parse(doc['scheduled_date'])
          : null,
      // Retrieve scheduled time from metadata if available
      'scheduledTime': metadata['scheduledTime'],
      'createdAt':
          doc['created_at'] != null ? DateTime.parse(doc['created_at']) : null,
      'updatedAt':
          doc['updated_at'] != null ? DateTime.parse(doc['updated_at']) : null,
      'metadata': metadata,
    };
  }
}
