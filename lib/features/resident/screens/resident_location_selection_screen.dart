import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/enhanced_nature_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../core/transitions/nature_transitions.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/barangay_validator.dart';
import '../../../core/config/supabase_config.dart';
import 'package:geolocator/geolocator.dart';

class ResidentLocationSelectionScreen extends StatefulWidget {
  final String? selectedBarangay;

  const ResidentLocationSelectionScreen({
    super.key,
    this.selectedBarangay,
  });

  @override
  State<ResidentLocationSelectionScreen> createState() =>
      _ResidentLocationSelectionScreenState();
}

class _ResidentLocationSelectionScreenState
    extends State<ResidentLocationSelectionScreen> {
  final _formKey = GlobalKey<FormState>();

  static const _allowedBarangays = [
    'Victoria, Tago, Surigao del Sur',
    'Dayo-an, Tago, Surigao del Sur',
  ];

  String? _selectedBarangay;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();

    // Pre-select barangay if provided
    if (widget.selectedBarangay != null &&
        _allowedBarangays.contains(widget.selectedBarangay)) {
      _selectedBarangay = widget.selectedBarangay;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _navigateToMap() async {
    if (_selectedBarangay == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'EcoSched is currently available only in the supported barangays.',
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      // 1. Get current location
      Position position = await LocationService.getCurrentLocation();

      // 2. Validate location
      bool allowed = BarangayValidator.isInsideBarangay(
        position,
        _selectedBarangay!,
      );

      setState(() => _isValidating = false);

      if (!allowed) {
        _showAccessDeniedDialog();
        return;
      }

      // 3. Save Device Token (No Login Needed)

      // 4. If correct location -> continue
      Navigator.of(context).pushNamed(
        AppRoutes.residentLocationMap,
        arguments: {
          'barangay': _selectedBarangay,
        },
      );
    } catch (e) {
      setState(() => _isValidating = false);
      ErrorHandler.showErrorSnackBar(context,
          'Location Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showAccessDeniedDialog() {
    // Get the display name for the barangay (strip the Tago, Surigao del Sur part for the message)
    final displayName = _selectedBarangay!.split(',')[0];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text("You are not inside Barangay $displayName."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    // Check if we can pop the current screen
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If we can't pop, navigate to the role selection screen
      Navigator.of(context).pushReplacementNamed(AppRoutes.roleSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: EnhancedNatureBackground(
        showPattern: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
                vertical: responsive.spacing(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Enhanced Location Logo
                  Column(
                    children: [
                      NatureHeroAnimation(
                        tag: 'resident_location_logo',
                        child: Container(
                          width: responsive.isMobile ? 110 : 130,
                          height: responsive.isMobile ? 110 : 130,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppTheme.primaryGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: responsive.isMobile ? 55 : 65,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Confirm Your Location',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontSize:
                              (theme.textTheme.headlineMedium?.fontSize ?? 32) *
                                  responsive.fontSizeMultiplier,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'EcoSched uses your location to provide personalized collection schedules and real-time alerts.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textLight,
                          fontSize:
                              (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                                  responsive.fontSizeMultiplier,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Location Selection Card
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive.getContainerWidth(
                        mobilePercent: 1.0,
                        tabletPercent: 0.8,
                        desktopPercent: 0.5,
                        maxWidth: 460,
                      ),
                    ),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      padding: EdgeInsets.all(responsive.spacing(24)),
                      borderRadius: AppTheme.radiusXL,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _buildStatusChip(
                                  icon: Icons.map_rounded,
                                  label:
                                      'Service Area: ${_selectedBarangay?.split(',').length == 3 ? _selectedBarangay!.split(',')[1].trim() : "Tago"}',
                                  color: AppTheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Select Protected Barangay',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Victoria Option
                            _buildBarangayOption(
                              _allowedBarangays[0],
                              Icons.home_work_rounded,
                              AppTheme.primary,
                            ),
                            const SizedBox(height: 12),
                            // Dayo-an Option
                            _buildBarangayOption(
                              _allowedBarangays[1],
                              Icons.home_work_rounded,
                              AppTheme.secondary,
                            ),
                            const SizedBox(height: 12),

                            if (_selectedBarangay != null) ...[
                              const SizedBox(height: 32),
                              AnimatedButton(
                                text: _isValidating
                                    ? 'Validating Location...'
                                    : 'Confirm & View Map',
                                onPressed:
                                    _isValidating ? null : _navigateToMap,
                                width: double.infinity,
                                icon: _isValidating
                                    ? Icons.hourglass_empty_rounded
                                    : Icons.map_rounded,
                                isGradient: true,
                                gradientColors: AppTheme.primaryGradient,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Professional Back Link
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Back to identity selection',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textLight,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarangayOption(String barangay, IconData icon, Color color) {
    final isSelected = _selectedBarangay == barangay;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color baseBorder = isDarkMode
        ? colorScheme.outline.withOpacity(0.2)
        : colorScheme.primary.withOpacity(0.1);
    final Color selectedBorder = color;
    final Color unselectedBg = isDarkMode
        ? colorScheme.surfaceContainerHighest.withOpacity(0.25)
        : Colors.white.withOpacity(0.65);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBarangay = barangay;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : unselectedBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? selectedBorder : baseBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.2)
                    : unselectedBg.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                barangay,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
