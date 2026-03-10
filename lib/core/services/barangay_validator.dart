import 'package:geolocator/geolocator.dart';
import '../config/barangay_locations.dart';

class BarangayValidator {
  static bool isInsideBarangay(Position position, String barangay) {
    final data = barangayLocations[barangay]!;

    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      data["lat"]!,
      data["lng"]!,
    );

    return distance <= data["radius"]!;
  }
}
