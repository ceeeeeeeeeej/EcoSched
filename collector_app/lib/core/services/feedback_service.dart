import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class FeedbackService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  static const String _table = SupabaseConfig.residentFeedbackTable;

  Future<void> submitFeedback({
    required String category,
    required String priority,
    required String title,
    required String message,
    required bool isAnonymous,
    String? residentId,
    String? residentName,
    String? residentEmail,
    String? serviceArea,
    String? barangay,
    String? purok,
  }) async {
    // Schema only has: id, user_id, feedback_text, rating, created_at
    // We must pack all other info into feedback_text

    final StringBuffer packedMessage = StringBuffer();
    packedMessage.writeln('Category: $category');
    packedMessage.writeln('Priority: $priority');
    packedMessage.writeln('Title: $title');
    packedMessage.writeln('Message: $message');

    if (!isAnonymous) {
      if (residentName != null) packedMessage.writeln('Name: $residentName');
      if (residentEmail != null) packedMessage.writeln('Email: $residentEmail');
    } else {
      packedMessage.writeln('Submitted Anonymously');
    }

    if (serviceArea != null) {
      packedMessage.writeln('Service Area: $serviceArea');
    }
    if (barangay != null) packedMessage.writeln('Barangay: $barangay');
    if (purok != null) packedMessage.writeln('Purok: $purok');

    // Map priority to rating (1-5)
    int rating = 1;
    if (priority.toLowerCase() == 'high') {
      rating = 5;
    } else if (priority.toLowerCase() == 'medium') rating = 3;

    // UUID validation helper
    bool isValidUUID(String? uuid) {
      if (uuid == null) return false;
      final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false);
      return uuidRegex.hasMatch(uuid);
    }

    final payload = <String, dynamic>{
      'user_id': (isAnonymous || !isValidUUID(residentId)) ? null : residentId,
      'feedback_text': packedMessage.toString(),
      'rating': rating,
      'created_at': DateTime.now().toIso8601String(),
    };
    // remove nulls
    payload.removeWhere((key, value) => value == null);

    try {
      await _supabase.from(_table).insert(payload);
    } catch (e) {
      if (kDebugMode) {
        print('FeedbackService Error: $e');
        print('Payload: $payload');
      }
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> watchFeedback({String? serviceArea}) {
    var query = _supabase
        .from(_table)
        .stream(primaryKey: ['id']).order('created_at', ascending: false);

    // Cannot filter by service_area easily as it's packed in text now.
    // So we just return all and let UI filter or just show all for admin.

    return query.map((data) => List<Map<String, dynamic>>.from(data));
  }
}
