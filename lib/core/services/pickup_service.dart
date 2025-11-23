import 'package:flutter/foundation.dart';

class PickupService extends ChangeNotifier {
  final List<Map<String, dynamic>> _scheduledPickups = [];

  List<Map<String, dynamic>> get scheduledPickups =>
      List.unmodifiable(_scheduledPickups);

  void addPickup({
    required String address,
    required String wasteType,
    required DateTime date,
    required String timeSlot,
    required String locationNote,
  }) {
    _scheduledPickups.add({
      'address': address,
      'type': wasteType,
      'time': timeSlot,
      'date': date,
      'locationNote': locationNote,
      'createdAt': DateTime.now(),
    });
    notifyListeners();
  }

  void clearAll() {
    _scheduledPickups.clear();
    notifyListeners();
  }
}
