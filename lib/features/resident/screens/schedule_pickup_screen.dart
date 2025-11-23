import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pickup_service.dart';

class SchedulePickupScreen extends StatefulWidget {
  const SchedulePickupScreen({super.key});

  @override
  State<SchedulePickupScreen> createState() => _SchedulePickupScreenState();
}

class _SchedulePickupScreenState extends State<SchedulePickupScreen> {
  String _selectedWasteType = 'General Waste';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '9:00 AM';
  String _selectedLocation = 'Front Door';
  // String _notes = ''; // Unused for now

  final List<String> _wasteTypes = [
    'General Waste',
    'Recycling',
    'Organic Waste',
    'Hazardous Waste',
  ];

  final List<String> _timeSlots = [
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  final List<String> _locations = [
    'Front Door',
    'Back Door',
    'Garage',
    'Side Entrance',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Pickup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.textInverse,
      ),
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassmorphicContainer(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Your Pickup',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your preferred date, time, and waste type',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  'Waste Type',
                  Icons.delete_outline,
                  _buildWasteTypeSelector(),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Pickup Date',
                  Icons.calendar_today,
                  _buildDateSelector(),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Pickup Time',
                  Icons.access_time,
                  _buildTimeSelector(),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Pickup Location',
                  Icons.location_on,
                  _buildLocationSelector(),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Additional Notes',
                  Icons.note,
                  _buildNotesField(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _schedulePickup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                    ),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Schedule Pickup'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return GlassmorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildWasteTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wasteTypes.map((type) {
        final bool selected = _selectedWasteType == type;
        return ChoiceChip(
          label: Text(type),
          selected: selected,
          onSelected: (_) => setState(() => _selectedWasteType = type),
          selectedColor: AppTheme.primaryGreen,
          labelStyle: TextStyle(
            color: selected ? AppTheme.textInverse : AppTheme.textDark,
          ),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            Text(
              _formatDate(_selectedDate),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeSlots.map((slot) {
        final bool selected = _selectedTime == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: selected,
          onSelected: (_) => setState(() => _selectedTime = slot),
          selectedColor: AppTheme.primaryGreen,
          labelStyle: TextStyle(
            color: selected ? AppTheme.textInverse : AppTheme.textDark,
          ),
          backgroundColor: Colors.grey[200],
        );
      }).toList(),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      children: _locations.map((location) {
        return RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: location,
          groupValue: _selectedLocation,
          onChanged: (value) => setState(() => _selectedLocation = value!),
          activeColor: AppTheme.primaryGreen,
          title: Text(
            location,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Any special instructions or notes...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _schedulePickup() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final pickupService = Provider.of<PickupService>(context, listen: false);

    // Derive a human-readable address from resident data and selected location
    String address = _selectedLocation;
    final user = auth.user;
    if (user != null) {
      final String? currentLocation = user['currentLocation'] as String?;
      final String? storedLocation = user['location'] as String?;
      final String? barangay = user['barangay'] as String?;
      final String? purok = user['purok'] as String?;

      if (currentLocation != null && currentLocation.isNotEmpty) {
        address = currentLocation;
      } else if (storedLocation != null && storedLocation.isNotEmpty) {
        address = storedLocation;
      } else if (barangay != null && purok != null) {
        address = '$purok, $barangay ($_selectedLocation)';
      } else {
        address = '$_selectedLocation (Resident)';
      }
    }

    pickupService.addPickup(
      address: address,
      wasteType: _selectedWasteType,
      date: _selectedDate,
      timeSlot: _selectedTime,
      locationNote: _selectedLocation,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pickup Scheduled!'),
          content: Text(
            'Your ${_selectedWasteType.toLowerCase()} pickup has been scheduled for ${_formatDate(_selectedDate)} at $_selectedTime.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
