import 'package:flutter/material.dart';
import 'package:collector_app/core/error/error_handler.dart';
import 'package:collector_app/core/routes/app_routes.dart';
import 'package:collector_app/core/services/auth_service.dart';
import 'package:collector_app/core/theme/app_theme.dart';
import 'package:collector_app/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/translations.dart';

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
    debugPrint('🔑 LOGIN: Submit pressed. Validating form...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔑 LOGIN: Validation failed.');
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    debugPrint('🔑 LOGIN: Validation passed. Starting authentication for: ${_emailController.text}');
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔑 LOGIN: Calling signInWithEmailAndPassword...');
      final result = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint('🔑 LOGIN: signInWithEmailAndPassword result: ${result != null ? "SUCCESS" : "NULL"}');

      if (result != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          context.tr('welcome_back_ecosched'),
        );

        // Navigate to appropriate dashboard based on user role
        final userRole = result['role']?.toString().toLowerCase() ?? 'resident';
        final String route = (userRole == 'collector' || userRole == 'admin')
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
          context.tr('login_failed'),
        );
      }
    } finally {
      debugPrint('🔑 LOGIN: Process complete. Resetting isLoading.');
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
            widget.isCollectorLogin ? context.tr('collector_access') : context.tr('welcome_back'),
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
                ? context.tr('authorized_personnel_only')
                : context.tr('sign_in_to_manage'),
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
              labelText: context.tr('email_address'),
              hintText: 'e.g., collector@ecosched.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, color: primaryColor),
              filled: true,
              fillColor: primaryColor.withValues(alpha: 0.04),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) {
                return context.tr('enter_email');
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
              labelText: context.tr('security_password'),
              hintText: 'Enter your account password',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryColor),
              filled: true,
              fillColor: primaryColor.withValues(alpha: 0.04),
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
                return context.tr('enter_password');
              }
              if (value.length < 6) {
                return context.tr('password_short');
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
                    context.tr('stay_signed_in'),
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
                    context.tr('password_recovery_admin'),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                child: Text(context.tr('reset_password')),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Login Button — direct ElevatedButton to guarantee tappability
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppTheme.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sign In to Dashboard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
