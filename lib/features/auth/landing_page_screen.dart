import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/enhanced_nature_background.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../widgets/nature_animations.dart';
import '../../core/transitions/nature_transitions.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pickup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/localization/translations.dart';
import '../../core/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    // Residents don't need authentication, so they always see landing page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final auth = Provider.of<AuthService>(context, listen: false);
      // Collector auto-jump removed
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToResidentDashboard(String barangay) {
    final auth = context.read<AuthService>();
    final pickupService = context.read<PickupService>();

    const purok = 'Purok 1';
    auth.setResidentLocation(barangay: barangay, purok: purok);

    final serviceArea = _mapBarangayToServiceArea(barangay);
    pickupService.loadSchedulesForServiceArea(serviceArea);
    NotificationService.subscribeToServiceAreaTopic(serviceArea,
        userId: auth.residentId);

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.residentDashboard,
      (route) => false,
    );
  }

  String _mapBarangayToServiceArea(String barangay) {
    final value = barangay.trim().toLowerCase();
    if (value.contains('victoria')) return 'victoria';
    if (value.contains('dayo-an') || value.contains('dayo-ay'))
      return 'dayo-an';
    return 'victoria';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          EnhancedNatureBackground(
            showPattern: true,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 20,
                    child: Consumer<LanguageProvider>(
                      builder: (context, lang, _) {
                        return NatureRippleEffect(
                          rippleColor: AppTheme.primary,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                                icon: const Icon(Icons.language, size: 18),
                                label: Text(
                                  lang.isBisaya ? 'English' : 'Bisaya',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => lang.toggleLanguage(),
                              ),
                            );
                          },
                        ),
                      ),
                      SingleChildScrollView(
                        padding: EdgeInsets.all(AppTheme.spacing8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),

                            // App Logo and Title
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: NatureHeroAnimation(
                                            tag: 'landing_logo',
                                            child: EcoPulseAnimation(
                                              isActive: true,
                                              child: NatureRippleEffect(
                                                rippleColor: AppTheme.primaryGreen,
                                                child: Container(
                                                  width: 120,
                                                  height: 120,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: AppTheme.primaryGradient,
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(30),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppTheme.primaryGreen
                                                            .withOpacity(0.4),
                                                        blurRadius: 30,
                                                        offset: const Offset(0, 15),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Image.asset(
                                                    'assets/images/ecosched_logo.png',
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                NatureBounceAnimation(
                                  isActive: true,
                                  child: Text(
                                    context.tr('experience_ecosched'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textDark,
                                          letterSpacing: -0.5,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                EcoShimmerEffect(
                                  isActive: true,
                                  baseColor: AppTheme.textLight.withOpacity(0.3),
                                  highlightColor: AppTheme.textLight,
                                  child: Text(
                                    context.tr('select_location_begin'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppTheme.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Barangay Selection Cards
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                // Victoria Card
                                _buildBarangayCard(
                                  context.tr('victoria'),
                                  Icons.location_city_rounded,
                                  AppTheme.primary,
                                  AppTheme.primaryGradient,
                                  context.tr('access_schedules_victoria'),
                                ),
                                const SizedBox(height: 20),
                                // Dayo-an Card
                                _buildBarangayCard(
                                  context.tr('dayo_an'),
                                  Icons.location_city_rounded,
                                  AppTheme.accentBlue,
                                  AppTheme.secondaryGradient,
                                  context.tr('access_schedules_dayo_an'),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating Nature Elements (non-interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: FloatingLeaves(
                leafCount: 15,
                speed: 0.7,
                leafColor: AppTheme.primaryGreen,
                isActive: true,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: FloatingParticles(
                particleCount: 20,
                speed: 0.9,
                colors: <Color>[
                  AppTheme.primaryGreen,
                  AppTheme.accentOrange,
                  AppTheme.accentBlue,
                  AppTheme.primaryGreenLight,
                ],
                isActive: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayCard(
    String barangay,
    IconData icon,
    Color color,
    List<Color> gradient,
    String description,
  ) {
    return GestureDetector(
      onTap: () {
        _navigateToResidentDashboard(barangay);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToResidentDashboard(barangay);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: NatureRippleEffect(
            rippleColor: color,
            child: GlassmorphicContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              borderRadius: AppTheme.radiusL,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      barangay,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: -0.5,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('select'),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
