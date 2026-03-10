class IdUtils {
  /// Generates a consistent synthetic UUID from a seed string (like a device ID).
  /// This helps satisfy Supabase's UUID type requirement for guest users.
  static String generateUuidFromSeed(String seed) {
    if (seed.isEmpty) return '00000000-0000-0000-0000-000000000000';

    // Basic hash to get a consistent string of hex chars
    final hash = seed.hashCode.abs().toString().padRight(32, '0');
    final p1 = hash.substring(0, 8);
    final p2 = hash.substring(8, 12);
    final p3 = hash.substring(12, 16);
    final p4 = hash.substring(16, 20);
    final p5 = hash.substring(20, 32);

    return '$p1-$p2-$p3-$p4-$p5';
  }
}
