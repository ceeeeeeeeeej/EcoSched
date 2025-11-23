import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/nature_animations.dart';
import '../../../core/transitions/nature_transitions.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/routes/app_router.dart';

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

  void _navigateToMap() {
    if (_selectedBarangay == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'EcoSched is currently available only in the supported barangays.',
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.residentLocationMap,
      arguments: {
        'barangay': _selectedBarangay,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final List<Color> backgroundGradient = isDarkMode
        ? const [Color(0xFF0A1526), Color(0xFF04070E)]
        : const [Color(0xFFF4FFF6), Color(0xFFE6F1FF)];
    final Color panelColor = isDarkMode
        ? colorScheme.surface.withOpacity(0.72)
        : Colors.white.withOpacity(0.92);
    final TextStyle? mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: (theme.textTheme.bodyMedium?.color ??
              colorScheme.onBackground.withOpacity(0.9))
          .withOpacity(0.7),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacing8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // App Logo and Title with Nature Animation
                  Column(
                    children: [
                      NatureHeroAnimation(
                        tag: 'resident_location_logo',
                        child: EcoPulseAnimation(
                          isActive: true,
                          child: NatureRippleEffect(
                            rippleColor: AppTheme.accentOrange,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: AppTheme.primaryGradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppTheme.accentOrange.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Select Your Location',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onBackground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EcoShimmerEffect(
                        isActive: true,
                        baseColor: colorScheme.onBackground.withOpacity(0.25),
                        highlightColor:
                            colorScheme.onBackground.withOpacity(0.7),
                        child: Text(
                          'Choose where you live',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onBackground.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Location Selection Form Container with Nature Animation
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: NatureRippleEffect(
                      rippleColor: AppTheme.accentOrange.withOpacity(0.3),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppTheme.spacing8),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(isDarkMode ? 0.4 : 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildStatusChip(
                                    icon: Icons.flag_circle,
                                    label: 'Step 1 of 2 · Select barangay',
                                    color: colorScheme.primary,
                                  ),
                                  _buildStatusChip(
                                    icon: Icons.map,
                                    label: 'Coverage: Victoria & Dayo-an',
                                    color: AppTheme.accentOrange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Barangay',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Victoria Option
                              _buildBarangayOption(
                                _allowedBarangays[0],
                                Icons.location_city,
                                AppTheme.primaryGreen,
                              ),
                              const SizedBox(height: 12),
                              // Dayo-an Option
                              _buildBarangayOption(
                                _allowedBarangays[1],
                                Icons.location_city,
                                AppTheme.accentOrange,
                              ),
                              const SizedBox(height: 24),
                              if (_selectedBarangay != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Selected barangay: $_selectedBarangay',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                              // Continue Button with Nature Animation
                              if (_selectedBarangay != null)
                                NatureRippleEffect(
                                  rippleColor: AppTheme.accentOrange,
                                  child: AnimatedButton(
                                    text: 'Continue',
                                    onPressed: _navigateToMap,
                                    isLoading: false,
                                    width: double.infinity,
                                    icon: Icons.arrow_forward,
                                    backgroundColor: AppTheme.accentOrange,
                                    isGradient: true,
                                    gradientColors: AppTheme.primaryGradient,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Back to Role Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Want to register as a collector? ',
                        style: mutedStyle,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: NatureRippleEffect(
                          rippleColor: AppTheme.accentOrange,
                          child: Text(
                            'Go Back',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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
        ? colorScheme.surfaceVariant.withOpacity(0.25)
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
