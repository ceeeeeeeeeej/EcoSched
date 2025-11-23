import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/enhanced_nature_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/nature_animations.dart';
import '../../../core/transitions/nature_transitions.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_screen.dart';

class CollectorRegistrationScreen extends StatefulWidget {
  const CollectorRegistrationScreen({super.key});

  @override
  State<CollectorRegistrationScreen> createState() => _CollectorRegistrationScreenState();
}

class _CollectorRegistrationScreenState extends State<CollectorRegistrationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  
  String _selectedServiceZone = 'Zone A';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _serviceZones = [
    'Zone A',
    'Zone B',
    'Zone C',
    'Zone D',
    'Zone E',
    'Zone F',
    'Zone G',
    'Zone H',
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleAgreeToTerms() {
    setState(() {
      _agreeToTerms = !_agreeToTerms;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Please agree to the terms and conditions',
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: 'collector',
      );
      
      if (result != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Registration successful! Please check your email for verification.',
        );
        Navigator.of(context).pushReplacement(
          NaturePageRoute(
            child: const AuthScreen(),
            transitionType: NatureTransitionType.slideFromRight,
            duration: const Duration(milliseconds: 600),
          ),
        );
      } else if (authService.error != null && mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          authService.error!,
        );
      }
    } catch (error) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Registration failed. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnhancedNatureBackground(
        showPattern: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacing8), 
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
                            tag: 'collector_registration_logo',
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
                                    Icons.local_shipping,
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
                              'Collector Registration',
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
                              'Join as a waste collection professional',
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
                  
                  // Registration Form Container with Nature Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: NatureRippleEffect(
                          rippleColor: AppTheme.primaryGreen.withOpacity(0.3),
                          child: GlassmorphicContainer(
                            width: double.infinity,
                            padding: EdgeInsets.all(AppTheme.spacing8), 
                            borderRadius: AppTheme.radiusL,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Name Field
                                  TextFormField(
                                    controller: _nameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      hintText: 'Enter your full name',
                                      prefixIcon: const Icon(Icons.person_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      if (value.length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      hintText: 'Enter your email',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: const Icon(Icons.lock_outlined),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                        ),
                                        onPressed: _togglePasswordVisibility,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                                        return 'Password must contain uppercase, lowercase, and number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Service Zone Selection
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedServiceZone,
                                    decoration: InputDecoration(
                                      labelText: 'Service Zone',
                                      prefixIcon: const Icon(Icons.location_on_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                      ),
                                    ),
                                    items: _serviceZones.map((zone) {
                                      return DropdownMenuItem<String>(
                                        value: zone,
                                        child: Text(zone),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedServiceZone = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Terms and Conditions
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _agreeToTerms,
                                        onChanged: (_) => _toggleAgreeToTerms(),
                                        activeColor: AppTheme.primaryGreen,
                                      ),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textLight,
                                            ),
                                            children: [
                                              const TextSpan(text: 'I agree to the '),
                                              TextSpan(
                                                text: 'Terms of Service',
                                                style: TextStyle(
                                                  color: AppTheme.primaryGreen,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const TextSpan(text: ' and '),
                                              TextSpan(
                                                text: 'Privacy Policy',
                                                style: TextStyle(
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
                                  const SizedBox(height: 24),
                                  
                                  // Register Button with Nature Animation
                                  NatureRippleEffect(
                                    rippleColor: AppTheme.primaryGreen,
                                    child: AnimatedButton(
                                      text: 'Create Collector Account',
                                      onPressed: _isLoading ? null : _handleRegister,
                                      isLoading: _isLoading,
                                      width: double.infinity,
                                      icon: Icons.person_add,
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
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Back to Role Selection
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: NatureBounceAnimation(
                      isActive: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Want to register as a resident? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: NatureRippleEffect(
                              rippleColor: AppTheme.primaryGreen,
                              child: Text(
                                'Go Back',
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
    );
  }
}
