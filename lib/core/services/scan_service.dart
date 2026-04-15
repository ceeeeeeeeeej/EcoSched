import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../config/supabase_config.dart';

class ScanService extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Uploads a captured scan image to Supabase Storage and returns the public URL.
  Future<String?> uploadScanImage(Uint8List imageBytes) async {
    try {
      if (kDebugMode) print('🖼️ [ScanService] Original size: ${imageBytes.length} bytes');

      // 1. Compress the image to avoid memory crashes on device
      Uint8List compressedBytes = await _compressImage(imageBytes);
      
      if (kDebugMode) print('🖼️ [ScanService] Compressed size: ${compressedBytes.length} bytes');

      final String fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'public/$fileName';

      await _supabase.storage
          .from(SupabaseConfig.scanImagesBucket)
          .uploadBinary(
            path,
            compressedBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // Get public URL
      final String imageUrl = _supabase.storage
          .from(SupabaseConfig.scanImagesBucket)
          .getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading scan image: $e');
      }
      
      // Check for common 'bucket not found' error
      if (e.toString().contains('bucket_not_found') || e.toString().contains('not found')) {
        throw Exception('Storage bucket "${SupabaseConfig.scanImagesBucket}" not found. Please create it in Supabase dashboard.');
      }
      
      rethrow;
    }
  }

  /// Helper to compress image bytes
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Decoding and resizing is memory intensive, so we do it carefully
    return await compute((Uint8List data) {
      img.Image? image = img.decodeImage(data);
      if (image == null) return data;

      // Resize to a maximum width of 1024px while maintaining aspect ratio
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      // Encode back to JPG with 80% quality
      return Uint8List.fromList(img.encodeJpg(image, quality: 80));
    }, bytes);
  }

  /// Saves a scan record to the database.
  Future<bool> saveScanRecord({
    required String imageUrl,
    required String label,
    required double confidence,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      await _supabase.from(SupabaseConfig.aiScansTable).insert({
        'user_id': user?.id, // Can be null for guests
        'image_url': imageUrl,
        'image_path': imageUrl.split('/').last, // Simple path extraction
        'label': label,
        'confidence': confidence,
        'metadata': metadata ?? {},
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving scan record: $e');
      }
      return false;
    }
  }

  /// Retrieves the scan history for the current user.
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final List<dynamic> data = await _supabase
          .from(SupabaseConfig.aiScansTable)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching scan history: $e');
      }
      return [];
    }
  }
}
