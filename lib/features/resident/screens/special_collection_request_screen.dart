import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/special_collection_service.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/premium_app_bar.dart';

class SpecialCollectionRequestScreen extends StatefulWidget {
  const SpecialCollectionRequestScreen({super.key});

  @override
  State<SpecialCollectionRequestScreen> createState() =>
      _SpecialCollectionRequestScreenState();
}

class _SpecialCollectionRequestScreenState
    extends State<SpecialCollectionRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedWasteType = 'General Waste';
  String _selectedQuantity = 'Small (1-2 bags)';

  final TextEditingController _residentNameController = TextEditingController();
  final TextEditingController _pickupLocationController =
      TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> _wasteTypes = [
    'General Waste',
    'Recycling',
    'Organic Waste',
    'Hazardous Waste',
    'Bulk Items',
  ];

  final List<String> _quantities = [
    'Small (1-2 bags)',
    'Medium (3-5 bags)',
    'Large (6-10 bags)',
    'Extra Large (10+ bags)',
    'Others',
  ];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill location if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.user;
    if (user != null) {
      // Remove auto-prefill for name as per user request to show placeholder
      _residentNameController.text = '';

      // Prefill Location
      final String? currentLocation = user['currentLocation'] as String?;
      final String? storedLocation = user['location'] as String?;
      final String? barangay = user['barangay'] as String?;
      final String? purok = user['purok'] as String?;

      List<String> addressParts = [];
      if (currentLocation != null && currentLocation.isNotEmpty) {
        addressParts.add(currentLocation);
      } else {
        if (storedLocation != null && storedLocation.isNotEmpty) {
          addressParts.add(storedLocation);
        }
        if (purok != null && purok.isNotEmpty) {
          addressParts.add(purok);
        }
        if (barangay != null && barangay.isNotEmpty) {
          addressParts.add(barangay);
        }
      }

      final location = addressParts.join(', ');

      if (location.isNotEmpty) {
        // Remove auto-prefill for location to match resident name behavior
        _pickupLocationController.text = '';
      }
    }
  }

  void _useRegisteredLocation() {
    _prefillUserData();
  }

  @override
  void dispose() {
    _residentNameController.dispose();
    _pickupLocationController.dispose();
    _messageController.dispose();
    _contactNumberController.dispose();
    _streetController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PremiumAppBar(
        title: Text('Special Pickup Request'),
      ),
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Resident Information',
                    Icons.person_rounded,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Name'),
                        const SizedBox(height: 8),
                        _buildResidentNameField(),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Age'),
                        const SizedBox(height: 8),
                        _buildAgeField(),
                        const SizedBox(height: 16),
                        _buildFieldLabel('Street name'),
                        const SizedBox(height: 8),
                        _buildStreetField(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Waste Category',
                    Icons.category_rounded,
                    _buildWasteTypeSelector(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Approximate Quantity',
                    Icons.inventory_2_rounded,
                    _buildQuantitySelector(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Pickup Location',
                    Icons.location_on_rounded,
                    _buildPickupLocationField(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Message (Optional)',
                    Icons.message_rounded,
                    _buildMessageField(),
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResidentNameField() {
    return TextFormField(
      controller: _residentNameController,
      decoration: InputDecoration(
        hintText: '',
        filled: true,
        fillColor: AppTheme.primary.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Resident name is required';
        }
        return null;
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark.withOpacity(0.7),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return GlassmorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: selected ? AppTheme.textInverse : AppTheme.textLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          backgroundColor: AppTheme.primary.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        );
      }).toList(),
    );
  }

  Widget _buildQuantitySelector() {
    return Column(
      children: _quantities.map((quantity) {
        return RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: quantity,
          groupValue: _selectedQuantity,
          onChanged: (value) => setState(() => _selectedQuantity = value!),
          activeColor: AppTheme.primary,
          title: Text(
            quantity,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textDark,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickupLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _pickupLocationController,
          readOnly: false,
          decoration: InputDecoration(
            hintText: '',
            filled: true,
            fillColor: AppTheme.primary.withOpacity(0.05),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Pickup location is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _useRegisteredLocation,
            icon: Icon(Icons.my_location, size: 16, color: AppTheme.primary),
            label: Text(
              'Use My Registered Address',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactNumberField() {
    return TextFormField(
      controller: _contactNumberController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'e.g., 09123456789',
        filled: true,
        fillColor: AppTheme.primary.withOpacity(0.03),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please provide a contact number';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'e.g., 25',
        filled: true,
        fillColor: AppTheme.primary.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Age is required';
        }
        return null;
      },
    );
  }

  Widget _buildStreetField() {
    return TextFormField(
      controller: _streetController,
      decoration: InputDecoration(
        hintText: 'e.g., Sunflower St.',
        filled: true,
        fillColor: AppTheme.primary.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Street name is required';
        }
        return null;
      },
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Any additional notes...',
        filled: true,
        fillColor: AppTheme.primary.withOpacity(0.03),
      ),
    );
  }


  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.textInverse,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          elevation: 4,
          shadowColor: AppTheme.primary.withOpacity(0.4),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          _isSubmitting ? 'Processing...' : 'Submit Request',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final specialCollectionService =
        Provider.of<SpecialCollectionService>(context, listen: false);

    final user = auth.user;

    if (user == null) {
      _showErrorDialog('Please sign in to submit a request');
      setState(() => _isSubmitting = false);
      return;
    }


    final result = await specialCollectionService.requestSpecialCollection(
      residentName: _residentNameController.text.trim(),
      residentBarangay: user['barangay'] ?? '',
      residentPurok: user['purok'] ?? '',
      residentStreet: _streetController.text.trim(),
      residentAge: _ageController.text.trim(),
      wasteType: _selectedWasteType,
      estimatedQuantity: _selectedQuantity,
      pickupLocation: _pickupLocationController.text.trim(),
      message: _messageController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(result['error'] ?? 'Failed to submit request');
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Request Submitted!'),
          content: const Text(
            'Your request has been submitted. Please wait for approval from the Metro Office.',
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

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
