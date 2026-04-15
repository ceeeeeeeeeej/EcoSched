import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../widgets/enhanced_nature_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/nature_animations.dart';

class WelcomeAnimationScreen extends StatefulWidget {
  final String barangay;

  const WelcomeAnimationScreen({
    super.key,
    required this.barangay,
  });

  @override
  State<WelcomeAnimationScreen> createState() => _WelcomeAnimationScreenState();
}

class _WelcomeAnimationScreenState extends State<WelcomeAnimationScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _textController;
  late AnimationController _iconController;

  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );

    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _textController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    // Start animations
    _cardController.forward();
    _textController.forward();
    _iconController.repeat(reverse: true);

    // Initialize state and navigate after delay
    _startInitializationSequence();
  }

  Future<void> _startInitializationSequence() async {
    debugPrint('🎬 Welcome Animation started for: ${widget.barangay}');

    // Wait for the animation to be prominent
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      debugPrint('❌ Widget unmounted, skipping initialization');
      return;
    }

    try {
      // Set resident location state
      final auth = context.read<AuthService>();
      final pickupService = context.read<PickupService>();

      final barangay = widget.barangay;
      const purok = 'Purok 1'; // Default purok for quick connection

      debugPrint('📍 Setting resident location: $barangay, $purok');
      auth.setResidentLocation(
        barangay: barangay,
        purok: purok,
      );

      final serviceArea = _mapBarangayToServiceArea(barangay);
      debugPrint('🔄 Loading schedules for service area: $serviceArea');
      pickupService.loadSchedulesForServiceArea(serviceArea);
      // NotificationService.subscribeToServiceAreaTopic(serviceArea,
      //     userId: auth.residentId);

      debugPrint('⏱️ Waiting 2 seconds before navigation...');
      // Wait for the full duration before navigating
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) {
        debugPrint('❌ Widget unmounted before navigation');
        return;
      }

      debugPrint('🏠 Navigating to resident dashboard');
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.residentDashboard,
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
    }
  }

  String _mapBarangayToServiceArea(String barangay) {
    final value = barangay.trim().toLowerCase();
    if (value.contains('victoria')) return 'victoria';
    if (value.contains('dayo-an') || value.contains('dayo-ay')) {
      return 'dayo-an';
    }
    return 'victoria';
  }

  @override
  void dispose() {
    _cardController.dispose();
    _textController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVictoria = widget.barangay.toLowerCase().contains('victoria');
    final accentColor = isVictoria ? AppTheme.primary : AppTheme.accentBlue;
    final gradient =
        isVictoria ? AppTheme.primaryGradient : AppTheme.secondaryGradient;

    return Scaffold(
      body: Stack(
        children: [
          EnhancedNatureBackground(
            showPattern: true,
            child: const SizedBox.expand(),
          ),

          // Floating elements for premium feel
          Positioned.fill(
            child: FloatingLeaves(
              leafCount: 12,
              speed: 0.8,
              leafColor: AppTheme.primaryGreen.withOpacity(0.4),
              isActive: true,
            ),
          ),
          Positioned.fill(
            child: FloatingParticles(
              particleCount: 15,
              speed: 1.2,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.accentBlue,
                AppTheme.accentOrange,
              ],
              isActive: true,
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: FadeTransition(
                opacity: _cardOpacity,
                child: SlideTransition(
                  position: _cardSlide,
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    borderRadius: AppTheme.radius2XL,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Eco Icon
                        ScaleTransition(
                          scale: _iconScale,
                          child: AnimatedBuilder(
                            animation: _iconController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _iconController.value * 0.1,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: gradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.eco_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Welcome Text Message
                        FadeTransition(
                          opacity: _textOpacity,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Welcome to EcoSched!',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textLight,
                                      height: 1.6,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text:
                                              'You are now connected to the waste management system of '),
                                      TextSpan(
                                        text: 'Barangay ${widget.barangay}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Loading Indicator
                        SizedBox(
                          width: 40,
                          height: 2,
                          child: LinearProgressIndicator(
                            backgroundColor: accentColor.withOpacity(0.1),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
