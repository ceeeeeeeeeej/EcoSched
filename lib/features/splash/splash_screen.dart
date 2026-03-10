import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/location_constants.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glassmorphic_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTurns;
  bool _entered = false;
  bool _isVerifying = false;
  bool _showWelcome = false;
  String _selectedBarangayName = '';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('🚀 FLASH: SplashScreen.initState');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _logoTurns = Tween<double>(begin: -0.004, end: 0.004).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) print('🚀 FLASH: SplashScreen first frame build done');
      if (!mounted) return;
      setState(() => _entered = true);

      // Check for existing session after a short delay to allow animations to play
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    // Wait for auth check to be ready
    final auth = Provider.of<AuthService>(context, listen: false);

    void tryNavigate() {
      if (!mounted) return;

      if (auth.isAuthCheckComplete) {
        // Only auto-navigate if the user is a Collector
        // Residents should always land on the Barangay Selection screen as requested
        if (auth.isAuthenticated && auth.isCollector()) {
          if (kDebugMode) {
            print('🚀 FLASH: Collector session found, auto-navigating...');
          }
          auth.goHome(context);
        } else {
          if (kDebugMode) {
            print(
                '🚀 FLASH: No collector session or resident user, staying on Splash.');
          }
        }
      }
    }

    if (auth.isAuthCheckComplete) {
      tryNavigate();
    } else {
      void listener() {
        if (auth.isAuthCheckComplete) {
          auth.removeListener(listener);
          tryNavigate();
        }
      }

      auth.addListener(listener);
    }
  }

  Future<void> _handleBarangaySelection(
      BuildContext context, String barangay) async {
    setState(() => _isVerifying = true);

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showErrorSnackBar(context,
              'Location services are disabled. Please enable them to proceed.');
        }
        setState(() => _isVerifying = false);
        return;
      }

      // 2. Check/Request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showErrorSnackBar(context,
                'Location permissions are denied. We need your location to verify your barangay.');
          }
          setState(() => _isVerifying = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showErrorSnackBar(context,
              'Location permissions are permanently denied. Please enable them in settings.');
        }
        setState(() => _isVerifying = false);
        return;
      }

      // 3. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20), // Increased from 10s
      );

      // 4. Verify against bounds (Skip for Visitors)
      final bool isVisitor = barangay.toLowerCase() == 'visitors';
      final isInside = isVisitor ||
          LocationConstants.isWithinBarangay(
              barangay, position.latitude, position.longitude);

      if (!isInside) {
        if (mounted) {
          String message = '';
          if (barangay.toLowerCase().contains('dayo')) {
            message =
                'You are not currently located in Barangay Dayo-an. This selection is only available for residents within Barangay Dayo-an.';
          } else if (barangay.toLowerCase().contains('victoria')) {
            message =
                'You are not currently located in Barangay Victoria. This selection is only available for residents within Barangay Victoria.';
          } else {
            message =
                'You are not currently located in Barangay Mahayag. This selection is only available for residents within Barangay Mahayag.';
          }
          _showAccessDeniedDialog(context, message);
        }
        setState(() => _isVerifying = false);
        return;
      }

      // 5. If everything is fine, proceed
      if (mounted) {
        final auth = Provider.of<AuthService>(context, listen: false);

        // Use a default purok
        const String defaultPurok = 'Purok 1';

        // Ensure we have a session (Anonymous or otherwise)
        if (!auth.isAuthenticated) {
          // await auth.signInAnonymously(); // DISABLED: Anonymous sign-ins are disabled in Supabase
        }

        // Set local location first
        auth.setResidentLocation(
          barangay: barangay,
          purok: defaultPurok,
        );

        // Then register in database for Admin tracking
        final residentUser = auth.user;
        if (residentUser != null && residentUser['uid'] != null) {
          await auth.registerResidentInDatabase(
            barangay: barangay,
            userId: residentUser['uid'],
            purok: defaultPurok,
          );
        }

        if (mounted) {
          setState(() {
            _selectedBarangayName = barangay;
            _showWelcome = true;
            _isVerifying = false;
          });
        }

        // Wait for animation
        await Future.delayed(const Duration(seconds: 3));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/resident');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Location verification error: $e');
      if (mounted) {
        _showErrorSnackBar(
            context, 'Failed to verify location. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAccessDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final brandGradient = LinearGradient(
      colors: [
        colorScheme.primary,
        colorScheme.primaryContainer,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: GradientBackground(
        showPattern: true,
        opacity: 0.9,
        child: SafeArea(
          child: Stack(
            children: [
              IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      top: -90,
                      left: -60,
                      child: _GlowBlob(
                        size: 220,
                        color: colorScheme.primary
                            .withOpacity(isDark ? 0.22 : 0.14),
                      ),
                    ),
                    Positioned(
                      bottom: -120,
                      right: -90,
                      child: _GlowBlob(
                        size: 260,
                        color: colorScheme.secondary
                            .withOpacity(isDark ? 0.20 : 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacing6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOut,
                      opacity: _entered ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOut,
                        offset: _entered ? Offset.zero : const Offset(0, 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppTheme.spacing6),
                            Center(
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: RotationTransition(
                                  turns: _logoTurns,
                                  child: Container(
                                    width: 112,
                                    height: 112,
                                    decoration: BoxDecoration(
                                      gradient: brandGradient,
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radius3XL),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(
                                                  isDark ? 0.45 : 0.25),
                                          blurRadius: 40,
                                          offset: const Offset(0, 16),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.eco_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing5),
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) {
                                return brandGradient.createShader(bounds);
                              },
                              child: Text(
                                'EcoSched',
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'Smart Community Waste Management',
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium?.copyWith(
                                color: (textTheme.titleMedium?.color ??
                                        colorScheme.onSurface)
                                    .withOpacity(0.78),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing4,
                                vertical: AppTheme.spacing2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surface
                                    .withOpacity(isDark ? 0.12 : 0.55),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                                border: Border.all(
                                  color: colorScheme.outlineVariant
                                      .withOpacity(isDark ? 0.35 : 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: AppTheme.spacing2),
                                  Flexible(
                                    child: Text(
                                      'Schedules • Reminders • Community Updates',
                                      textAlign: TextAlign.center,
                                      style: textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: (textTheme.labelLarge?.color ??
                                                colorScheme.onSurface)
                                            .withOpacity(0.82),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing8),
                            Text(
                              'Select Your Barangay',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            _BarangaySelectionCard(
                              title: 'Barangay Dayo-an',
                              isLoading: _isVerifying,
                              onTap: _isVerifying
                                  ? () {}
                                  : () => _handleBarangaySelection(
                                      context, 'Dayo-an'),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            _BarangaySelectionCard(
                              title: 'Barangay Victoria',
                              isLoading: _isVerifying,
                              onTap: _isVerifying
                                  ? () {}
                                  : () => _handleBarangaySelection(
                                      context, 'Victoria'),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            _BarangaySelectionCard(
                              title: 'Barangay Mahayag',
                              isLoading: _isVerifying,
                              onTap: _isVerifying
                                  ? () {}
                                  : () => _handleBarangaySelection(
                                      context, 'Mahayag'),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            _BarangaySelectionCard(
                              title: 'Visitors',
                              isLoading: _isVerifying,
                              onTap: _isVerifying
                                  ? () {}
                                  : () => _handleBarangaySelection(
                                      context, 'Visitors'),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                          ],
                        ),
                      ),
                    ),
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

class _BarangaySelectionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isLoading;

  const _BarangaySelectionCard({
    required this.title,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GlassmorphicContainer(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusL,
      blur: 24,
      opacity: isDark ? 0.10 : 0.16,
      color: colorScheme.surface,
      borderColor: colorScheme.outlineVariant.withOpacity(isDark ? 0.40 : 0.28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing5,
            vertical: AppTheme.spacing5,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.business_rounded,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: AppTheme.spacing4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
