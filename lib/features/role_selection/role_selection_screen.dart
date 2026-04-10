import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/transitions/nature_transitions.dart';
import '../../widgets/enhanced_nature_background.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../widgets/animated_button.dart';
import '../resident/screens/resident_location_selection_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppConstants.mediumAnimation,
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    // Only resident role selection remains
    Navigator.of(context).push(
      NaturePageRoute(
        child: const ResidentLocationSelectionScreen(),
        transitionType: NatureTransitionType.slideUp,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnhancedNatureBackground(
        showPattern: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppTheme.spacing8 * 2,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Enhanced App Logo with gradient
                              NatureHeroAnimation(
                                tag: 'app_logo',
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: AppTheme.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppTheme.primary.withOpacity(0.4),
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
                              const SizedBox(height: 20),
                              Text(
                                'Step into EcoSched',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textDark,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Smart, sustainable waste management',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppTheme.textLight,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select your role to continue',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            // Only Resident Page remains, simplified layout
                            GlassmorphicContainer(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppTheme.spacing8),
                              borderRadius: AppTheme.radiusL,
                              child: Column(
                                children: [
                                  NatureHeroAnimation(
                                    tag: 'resident_icon',
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.secondary
                                                .withOpacity(0.1),
                                            AppTheme.secondary
                                                .withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.secondary
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.home_rounded,
                                        size: 40,
                                        color: AppTheme.secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Community Resident',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondary,
                                          letterSpacing: -0.3,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sync with local schedules, receive smart reminders, and keep your community clean.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textLight,
                                          height: 1.4,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  AnimatedButton(
                                    text: 'Get Started',
                                    onPressed: () => _selectRole(
                                        AppConstants.residentRole),
                                    width: double.infinity,
                                    backgroundColor: AppTheme.secondary,
                                    icon: Icons.arrow_forward_rounded,
                                    isGradient: true,
                                    gradientColors:
                                        AppTheme.secondaryGradient,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing4,
                            vertical: AppTheme.spacing2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.05),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco,
                                size: 14,
                                color: AppTheme.primaryGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'IoT-Enabled Smart Waste Collection',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
