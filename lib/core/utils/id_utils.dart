import 'dart:convert';
import 'package:crypto/crypto.dart';

class IdUtils {
  /// Generates a consistent synthetic UUID from a seed string (like a device ID).
  /// USES MD5 for stability across different runs and platforms.
  static String generateUuidFromSeed(String seed) {
    if (seed.isEmpty) return '00000000-0000-0000-0000-000000000000';

    // Generate MD5 hash of the seed string
    final bytes = utf8.encode(seed);
    final digest = md5.convert(bytes);
    final hash = digest.toString(); // 32 chars hex

    // Format as UUID: 8-4-4-4-12
    final p1 = hash.substring(0, 8);
    final p2 = hash.substring(8, 12);
    final p3 = hash.substring(12, 16);
    final p4 = hash.substring(16, 20);
    final p5 = hash.substring(20, 32);

    return '$p1-$p2-$p3-$p4-$p5';
  }
}
