import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/enhanced_nature_background.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../widgets/nature_animations.dart';
import '../../core/transitions/nature_transitions.dart';
import '../../core/routes/app_router.dart';
import '../../core/services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'tailwind_login_screen.dart';
import 'tailwind_register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isLogin = true;
  bool _useTailwindStyle = true; // Toggle for Tailwind vs Original style

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();

    // If already authenticated, skip auth UI and go straight to home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.isAuthenticated) {
        context.goHomeForRole();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _toggleStyle() {
    setState(() {
      _useTailwindStyle = !_useTailwindStyle;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          EnhancedNatureBackground(
            showPattern: true,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppTheme.spacing4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const SizedBox(height: 40),
                  
                  // App Logo and Title with Nature Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          NatureHeroAnimation(
                            tag: 'ecosched_logo',
                            child: EcoPulseAnimation(
                              isActive: true,
                              child: NatureRippleEffect(
                                rippleColor: AppTheme.primaryGreen,
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
                                        color: AppTheme.primaryGreen.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          NatureBounceAnimation(
                            isActive: true,
                            child: Text(
                              'Welcome to EcoSched',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          EcoShimmerEffect(
                            isActive: true,
                            baseColor: AppTheme.textLight.withOpacity(0.3),
                            highlightColor: AppTheme.textLight,
                            child: Text(
                              'Smart Waste Collection Management',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppTheme.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Auth Form Container with Nature Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: NatureRippleEffect(
                          rippleColor: AppTheme.primaryGreen.withOpacity(0.3),
                        child: _useTailwindStyle
                            ? (_isLogin 
                                ? TailwindLoginScreen(onToggleMode: _toggleAuthMode)
                                : TailwindRegisterScreen(onToggleMode: _toggleAuthMode))
                            : GlassmorphicContainer(
                                width: double.infinity,
                                padding: EdgeInsets.all(AppTheme.spacing8),
                                borderRadius: AppTheme.radiusL,
                                child: _isLogin 
                                    ? LoginScreen(onToggleMode: _toggleAuthMode)
                                    : RegisterScreen(onToggleMode: _toggleAuthMode),
                              ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Style Toggle Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: NatureRippleEffect(
                        rippleColor: AppTheme.accentOrange,
                        child: ElevatedButton.icon(
                          onPressed: _toggleStyle,
                          icon: Icon(
                            _useTailwindStyle ? Icons.style : Icons.palette,
                            size: 18,
                          ),
                          label: Text(
                            _useTailwindStyle ? 'Switch to Original' : 'Switch to Tailwind',
                            style: const TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
                            foregroundColor: AppTheme.accentOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Auth Mode Toggle with Nature Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: NatureBounceAnimation(
                      isActive: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? "Don't have an account? " : "Already have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleAuthMode,
                            child: NatureRippleEffect(
                              rippleColor: AppTheme.primaryGreen,
                              child: Text(
                                _isLogin ? 'Sign Up' : 'Sign In',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          ),
          ),
          // Enhanced Floating Nature Elements
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingLeaves(
              leafCount: 12,
              speed: 0.6,
              leafColor: AppTheme.primaryGreen,
              isActive: true,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingParticles(
              particleCount: 15,
              speed: 0.8,
              colors: <Color>[
                AppTheme.primaryGreen,
                AppTheme.accentOrange,
                AppTheme.accentBlue,
                AppTheme.primaryGreenLight,
              ],
              isActive: true,
            ),
          ),
        ],
      ),
    );
  }
}
