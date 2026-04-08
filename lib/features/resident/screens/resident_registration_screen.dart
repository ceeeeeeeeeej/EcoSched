import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';

class ResidentRegistrationScreen extends StatefulWidget {
  final String barangay;

  const ResidentRegistrationScreen({
    super.key,
    required this.barangay,
  });

  @override
  State<ResidentRegistrationScreen> createState() => _ResidentRegistrationScreenState();
}

class _ResidentRegistrationScreenState extends State<ResidentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  late List<String> _puroks;
  late String _selectedPurok;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _puroks = _getPuroksForBarangay(widget.barangay);
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
    // Default list for Dayo-an or others
    return [
      'Purok 1',
      'Purok 2',
      'Purok 3',
      'Purok 4',
      'Purok 5',
      'Purok 6',
      'Purok 7',
      'Other',
    ];
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final contact = _contactController.text.trim();
      
      // Determine if email or phone
      String? email;
      String? phone;
      if (contact.contains('@')) {
        email = contact;
      } else {
        phone = contact;
      }

      String userId = auth.user?['uid'] ?? '';

      // If no userId (no Supabase session), fall back to device-derived ID
      if (userId.isEmpty) {
        userId = auth.deviceId ?? '';
      }

      // Set local location
      auth.setResidentLocation(
        barangay: widget.barangay,
        purok: _selectedPurok,
        email: email,
        phone: phone,
      );

      // Always register/update in database — userId may come from device or session
      final effectiveUserId = auth.user?['uid'] ?? userId;
      if (effectiveUserId.isNotEmpty) {
        await auth.registerResidentInDatabase(
          barangay: widget.barangay,
          userId: effectiveUserId,
          purok: _selectedPurok,
          email: email,
          phone: phone,
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome-animation', arguments: widget.barangay);
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
              // Background Blobs
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
                      // Header
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

                      // Form Container
                      GlassmorphicContainer(
                        padding: const EdgeInsets.all(AppTheme.spacing6),
                        borderRadius: AppTheme.radiusXL,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Barangay (Read-only)
                              _buildInfoField(
                                label: 'Selected Barangay',
                                value: widget.barangay,
                                icon: Icons.business_rounded,
                              ),
                              const SizedBox(height: AppTheme.spacing4),

                              // Contact Info
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
                                decoration: InputDecoration(
                                  hintText: 'Email or Phone Number',
                                  prefixIcon: const Icon(Icons.contact_mail_rounded),
                                  filled: true,
                                  fillColor: colorScheme.surface.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email or phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacing4),

                              // Purok
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

                              // Submit Button
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

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing4,
            vertical: AppTheme.spacing4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: AppTheme.spacing3),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
