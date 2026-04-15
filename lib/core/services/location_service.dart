class LocationService {
  /// GPS functionality removed. Returns a placeholder or does nothing.
  static Future<void> getCurrentLocation() async {
    return;
  }
}

class BarangayValidator {
  /// Location validation removed. Always returns true in Zero-GPS mode.
  static bool isInsideBarangay(dynamic position, String barangay) {
    return true;
  }
}
