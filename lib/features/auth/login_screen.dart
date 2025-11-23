import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/micro_interactions.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/nature_animations.dart';
import '../../core/error/error_handler.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggleMode;
  final bool isCollectorLogin;
  
  const LoginScreen({
    super.key,
    required this.onToggleMode,
    this.isCollectorLogin = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
        
        // Navigate to appropriate dashboard based on user role
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            widget.isCollectorLogin ? 'Collector Login' : 'Welcome Back!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isCollectorLogin 
                ? 'Sign in as a waste collector'
                : 'Sign in to continue to EcoSched',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Email Field
          AnimatedTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
            showFloatingLabel: true,
            showNatureEffects: true,
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
          const SizedBox(height: 20),
          
          // Password Field
          AnimatedTextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            onSuffixTap: _togglePasswordVisibility,
            showFloatingLabel: true,
            showNatureEffects: true,
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
          const SizedBox(height: 16),
          
          // Remember Me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (_) => _toggleRememberMe(),
                      activeColor: AppTheme.primaryGreen,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Flexible(
                      child: Text(
                        'Remember me',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                  ErrorHandler.showSuccessSnackBar(
                    context,
                    'Forgot password feature coming soon!',
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Login Button with Nature Animation
          NatureRippleEffect(
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
          ),
          const SizedBox(height: 24),
          
          // Demo Login Button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing4,
              vertical: AppTheme.spacing2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Demo Login',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }
}
