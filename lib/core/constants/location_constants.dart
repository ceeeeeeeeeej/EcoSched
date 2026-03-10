class LatLngBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  const LatLngBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  bool contains(double latitude, double longitude) {
    return latitude >= minLatitude &&
        latitude <= maxLatitude &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }
}

class LocationConstants {
  static const LatLngBounds victoriaBounds = LatLngBounds(
    minLatitude: 9.0000,
    maxLatitude: 9.0700,
    minLongitude: 126.1800,
    maxLongitude: 126.2400,
  );

  static const LatLngBounds dayoanBounds = LatLngBounds(
    minLatitude: 8.9900,
    maxLatitude: 9.0500,
    minLongitude: 126.1500,
    maxLongitude: 126.1800, // Reduced from 126.2100 to eliminate overlap
  );

  static const LatLngBounds mahayagBounds = LatLngBounds(
    minLatitude: 8.8800,
    maxLatitude: 8.9800,
    minLongitude: 125.9300,
    maxLongitude: 126.0400,
  );

  static bool isWithinBarangay(String barangay, double lat, double lng) {
    final b = barangay.toLowerCase();
    if (b.contains('victoria')) {
      return victoriaBounds.contains(lat, lng);
    } else if (b.contains('dayo-an') ||
        b.contains('dayo-ay') ||
        b.contains('dayuan')) {
      return dayoanBounds.contains(lat, lng);
    } else if (b.contains('mahayag')) {
      return mahayagBounds.contains(lat, lng);
    }
    return false;
  }
}
