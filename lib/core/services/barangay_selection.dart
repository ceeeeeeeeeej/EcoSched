import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ecosched/core/services/location_service.dart';
import 'package:ecosched/core/services/barangay_validator.dart';
import 'package:ecosched/core/services/push_notification_service.dart';
import '../../features/resident/screens/welcome_animation_screen.dart';

class BarangaySelection extends StatefulWidget {
  const BarangaySelection({super.key});

  @override
  State<BarangaySelection> createState() => _BarangaySelectionState();
}

class _BarangaySelectionState extends State<BarangaySelection> {
  final supabase = Supabase.instance.client;

  String? selectedBarangay;
  bool isLoading = false;

  final List<String> barangays = [
    "victoria",
    "dayo-an",
  ];

  Future<void> verifyAndSave() async {
    if (selectedBarangay == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      /// 1️⃣ Get user location
      Position position = await LocationService.getCurrentLocation();

      /// 2️⃣ Validate barangay
      bool allowed = BarangayValidator.isInsideBarangay(
        position,
        selectedBarangay!,
      );

      if (!allowed) {
        setState(() {
          isLoading = false;
        });

        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Access Denied"),
            content: Text("You are not inside the selected barangay."),
          ),
        );

        return;
      }

      /// 3️⃣ Save barangay locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        "resident_barangay",
        selectedBarangay!,
      );

      /// 4️⃣ Register Device via PushNotificationService
      await PushNotificationService.registerDeviceForPush();

      /// 7️⃣ Navigate to home
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WelcomeAnimationScreen(
            barangay: selectedBarangay!,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Barangay"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Dropdown
            DropdownButtonFormField<String>(
              hint: const Text("Choose Barangay"),
              value: selectedBarangay,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: barangays.map((barangay) {
                return DropdownMenuItem(
                  value: barangay,
                  child: Text(barangay.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBarangay = value;
                });
              },
            ),

            const SizedBox(height: 30),

            /// Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : verifyAndSave,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Continue"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
