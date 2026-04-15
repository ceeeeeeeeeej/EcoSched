import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/id_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  final String? barangay;

  const ResidentRegistrationScreen({
    super.key,
    this.barangay,
  });

  @override
  State<ResidentRegistrationScreen> createState() => _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState extends State<ResidentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  late String _selectedBarangay;
  late List<String> _puroks;
  late String _selectedPurok;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBarangay = widget.barangay ?? 'Victoria';
    _puroks = _getPuroksForBarangay(_selectedBarangay);
    _selectedPurok = _puroks.first;
  }

  List<String> _getPuroksForBarangay(String barangay) {
    if (barangay.toLowerCase().contains('victoria')) {
      return [
        'M. homes',
        'Sandiya',
        'Pinya',
        'Bayabas',
        'Mangga',
        'Narra',
        'Albezzia',
        'Mejica',
        'Paradise',
        'Relocation',
      ];
    }
    // Default list for Dayo-an
    return [
      'Ipil-ipil',
      'Kalipayan',
      'Mambago',
      'Acacia',
    ];
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final phone = _contactController.text.trim();
      String? email; 

      String userId = auth.user?['uid'] ?? '';
      
      if (userId.isEmpty) {
        final deviceId = auth.deviceId ?? '';
        userId = IdUtils.generateUuidFromSeed(deviceId);
      }

      // 🛡️ SECURITY CHECK: Match existing profile for this device
      final existingPhone = await auth.getExistingResidentPhone(userId);
      
      if (existingPhone != null && existingPhone.isNotEmpty) {
        final normalizedInput = phone.replaceAll(RegExp(r'\D'), '');
        final normalizedExisting = existingPhone.replaceAll(RegExp(r'\D'), '');
        
        if (normalizedInput != normalizedExisting) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid number. Please use the phone number registered to this device.'),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 4),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Set local location
      auth.setResidentLocation(
        barangay: _selectedBarangay,
        purok: _selectedPurok,
        email: email,
        phone: phone,
      );

      // Register in database
      final effectiveUserId = auth.user?['uid'] ?? userId;
      if (effectiveUserId.isNotEmpty) {
        await auth.registerResidentInDatabase(
          barangay: _selectedBarangay,
          userId: effectiveUserId,
          purok: _selectedPurok,
          email: email,
          phone: phone,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome-animation', arguments: _selectedBarangay);
      }
    } catch (e) {
      if (kDebugMode) print('Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete setup. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        showPattern: true,
        opacity: 0.9,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -50,
                child: _GlowBlob(
                  size: 300,
                  color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -80,
                child: _GlowBlob(
                  size: 400,
                  color: colorScheme.secondary.withOpacity(isDark ? 0.12 : 0.08),
                ),
              ),
              
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle_rounded,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Complete Your Profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing2),
                      Text(
                        'Stay updated on your local pickups',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),

                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(AppTheme.spacing6),
                        borderRadius: AppTheme.radiusXL,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Barangay Selection
                              Text(
                                'Select Your Barangay',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing2),
                              DropdownButtonFormField<String>(
                                value: _selectedBarangay,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.business_rounded),
                                  filled: true,
                                  fillColor: colorScheme.surface.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: ['Victoria', 'Dayo-an'].map((b) {
                                  return DropdownMenuItem(
                                    value: b,
                                    child: Text(b),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedBarangay = value;
                                      _puroks = _getPuroksForBarangay(value);
                                      _selectedPurok = _puroks.first;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: AppTheme.spacing4),

                              Text(
                                'Contact Information',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing2),
                              TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter Phone Number',
                                  prefixIcon: const Icon(Icons.phone_android_rounded),
                                  filled: true,
                                  fillColor: colorScheme.surface.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  final phoneRegex = RegExp(r'^(09|\+639|[9])\d{9}$');
                                  if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacing4),

                              Text(
                                'Select Your Purok',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing2),
                              DropdownButtonFormField<String>(
                                value: _selectedPurok,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.location_on_rounded),
                                  filled: true,
                                  fillColor: colorScheme.surface.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: _puroks.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedPurok = value);
                                  }
                                },
                              ),
                              const SizedBox(height: AppTheme.spacing8),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Finish Setup',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
