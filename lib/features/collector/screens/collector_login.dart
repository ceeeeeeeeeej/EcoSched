import 'package:flutter/material.dart';
import 'package:ecosched/core/error/error_handler.dart';
import 'package:ecosched/core/routes/app_router.dart';
import 'package:ecosched/core/services/auth_service.dart';
import 'package:ecosched/core/theme/app_theme.dart';
import 'package:ecosched/core/utils/responsive.dart';
import 'package:ecosched/widgets/animated_button.dart';
import 'package:provider/provider.dart';

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
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final primaryColor =
        widget.isCollectorLogin ? AppTheme.primary : AppTheme.primaryGreen;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - more professional context
          Text(
            widget.isCollectorLogin ? 'Collector Access' : 'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 24) *
                  responsive.fontSizeMultiplier,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.isCollectorLogin
                ? 'Authorized personnel only. Please sign in to access your dashboard.'
                : 'Sign in to manage your EcoSched account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 16) *
                  responsive.fontSizeMultiplier,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          // Email Field with refined styling
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g., collector@ecosched.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, color: primaryColor),
              filled: true,
              fillColor: primaryColor.withOpacity(0.04),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return 'Please enter your registered email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Password Field with refined styling
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Security Password',
              hintText: 'Enter your account password',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
              filled: true,
              fillColor: primaryColor.withOpacity(0.04),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppTheme.textLight,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 16),

          // Remember Me & Forgot Password - more professional layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (_) => _toggleRememberMe(),
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stay signed in',
                    style: theme.textTheme.bodySmall?.copyWith(
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
                    'Password recovery is currently managed by administrators.',
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Reset Password?'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Login Button
          AnimatedButton(
            text: _isLoading ? 'Authenticating...' : 'Sign In to Dashboard',
            onPressed: _isLoading ? null : _handleLogin,
            isLoading: _isLoading,
            width: double.infinity,
            icon: Icons.login_rounded,
            isGradient: true,
            gradientColors: widget.isCollectorLogin
                ? AppTheme.primaryGradient
                : AppTheme.primaryGradient,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
