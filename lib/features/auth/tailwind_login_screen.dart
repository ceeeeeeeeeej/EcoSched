import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tailwind_utils.dart';
import '../../core/animations/micro_interactions.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/nature_animations.dart';

import '../../core/error/error_handler.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_router.dart';

class TailwindLoginScreen extends StatefulWidget {
  final VoidCallback onToggleMode;
  
  const TailwindLoginScreen({
    super.key,
    required this.onToggleMode,
  });

  @override
  State<TailwindLoginScreen> createState() => _TailwindLoginScreenState();
}

class _TailwindLoginScreenState extends State<TailwindLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
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

  void _toggleRememberMe() {
    setState(() {
      _rememberMe = !_rememberMe;
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authService.signInWithGoogle();
      
      if (result != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Welcome to EcoSched!',
        );
        
        final userRole = result['role'] ?? 'resident';
        final String route = userRole == 'collector'
            ? AppRoutes.collectorDashboard
            : AppRoutes.residentDashboard;
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
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
          'Google sign-in failed. Please try again.',
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (result != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Welcome back to EcoSched!',
        );
        
        final userRole = result['role'] ?? 'resident';
        final String route = userRole == 'collector'
            ? AppRoutes.collectorDashboard
            : AppRoutes.residentDashboard;
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
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
          'Login failed. Please try again.',
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.05),
                AppTheme.accentBlue.withOpacity(0.03),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: Tailwind.responsivePadding(context),
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),
                  
                  SizedBox(height: Tailwind.responsiveGap(context)),
                  
                  // Form Section
                  _buildForm(),
                  
                  SizedBox(height: Tailwind.responsiveGap(context)),
                  
                  // Footer Section
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo/Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppTheme.primaryGradient),
            borderRadius: Tailwind.rounded2Xl,
            boxShadow: Tailwind.shadowLg,
          ),
          child: const Icon(
            Icons.eco,
            color: Colors.white,
            size: 40,
          ),
        ).my(8),
        
        // Title
        Text(
          'Welcome Back!',
          style: Tailwind.text4Xl.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ).my(2),
        
        // Subtitle
        Text(
          'Sign in to continue to EcoSched',
          style: Tailwind.textLg.copyWith(
            color: AppTheme.textLight,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: Tailwind.card,
      padding: Tailwind.p8,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            _buildEmailField(),
            
            SizedBox(height: Tailwind.gap5),
            
            // Password Field
            _buildPasswordField(),
            
            SizedBox(height: Tailwind.gap4),
            
            // Remember Me & Forgot Password
            _buildRememberAndForgot(),
            
            SizedBox(height: Tailwind.gap6),
            
            // Login Button
            _buildLoginButton(),
            
            SizedBox(height: Tailwind.gap5),
            
            // Divider
            _buildDivider(),
            
            SizedBox(height: Tailwind.gap5),
            
            // Google Sign-In Button
            _buildGoogleButton(),
            
            SizedBox(height: Tailwind.gap6),
            
            // Demo Login
            _buildDemoLogin(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: Tailwind.textSm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).mb(2),
        
        AnimatedTextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          showFloatingLabel: false,
          showNatureEffects: true,
          primaryColor: AppTheme.primaryGreen,
          accentColor: AppTheme.accentOrange,
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
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Tailwind.textSm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).mb(2),
        
        AnimatedTextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outlined,
          suffixIcon: _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          onSuffixTap: _togglePasswordVisibility,
          showFloatingLabel: false,
          showNatureEffects: true,
          primaryColor: AppTheme.primaryGreen,
          accentColor: AppTheme.accentOrange,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          onSubmitted: _handleLogin,
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AnimatedCheckbox(
              value: _rememberMe,
              onChanged: (_) => _toggleRememberMe(),
              activeColor: AppTheme.primaryGreen,
            ),
            Text(
              'Remember me',
              style: Tailwind.textSm.copyWith(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            ErrorHandler.showSuccessSnackBar(
              context,
              'Forgot password feature coming soon!',
            );
          },
          style: TextButton.styleFrom(
            padding: Tailwind.px2,
          ),
          child: Text(
            'Forgot Password?',
            style: Tailwind.textSm.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return NatureRippleEffect(
      rippleColor: AppTheme.primaryGreen,
      child: AnimatedButton(
        text: 'Sign In',
        onPressed: _isLoading ? null : _handleLogin,
        isLoading: _isLoading,
        width: double.infinity,
        icon: Icons.login,
        isGradient: true,
        gradientColors: AppTheme.primaryGradient,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.textMuted.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: Tailwind.px4,
          child: Text(
            'OR',
            style: Tailwind.textSm.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.textMuted.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return NatureRippleEffect(
      rippleColor: AppTheme.accentOrange,
      child: AnimatedButton(
        text: 'Continue with Google',
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        backgroundColor: Colors.white,
        textColor: AppTheme.textDark,
        width: double.infinity,
        icon: Icons.g_mobiledata,
        isOutlined: true,
      ),
    );
  }

  Widget _buildDemoLogin() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: Tailwind.roundedLg,
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: Tailwind.p4,
      child: Column(
        children: [
          Text(
            'Demo Login',
            style: Tailwind.textSm.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ).mb(2),
          
          NatureRippleEffect(
            rippleColor: AppTheme.accentOrange,
            child: AnimatedButton(
              text: 'Try Demo',
              onPressed: () {
                _emailController.text = 'demo@ecosched.com';
                _passwordController.text = 'demo123';
                _handleLogin();
              },
              backgroundColor: AppTheme.accentOrange,
              width: double.infinity,
              icon: Icons.play_arrow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: Tailwind.textBase.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        TextButton(
          onPressed: widget.onToggleMode,
          style: TextButton.styleFrom(
            padding: Tailwind.px2,
          ),
          child: Text(
            'Sign Up',
            style: Tailwind.textBase.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
