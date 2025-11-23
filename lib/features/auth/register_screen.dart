import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/animations/micro_interactions.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/nature_animations.dart';
import '../../core/transitions/nature_transitions.dart';
import '../../core/error/error_handler.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../role_selection/role_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggleMode;
  
  const RegisterScreen({
    super.key,
    required this.onToggleMode,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  
  String _selectedRole = 'resident';
  String _selectedServiceArea = 'downtown';

  final List<Map<String, String>> _roles = [
    {'value': 'municipal', 'label': 'Municipal Manager'},
    {'value': 'collector', 'label': 'Waste Collector'},
    {'value': 'resident', 'label': 'Community Resident'},
    {'value': 'iot', 'label': 'IoT Specialist'},
  ];

  final List<Map<String, String>> _serviceAreas = [
    {'value': 'downtown', 'label': 'Downtown District'},
    {'value': 'residential', 'label': 'Residential Zone A'},
    {'value': 'commercial', 'label': 'Commercial District'},
    {'value': 'industrial', 'label': 'Industrial Zone'},
    {'value': 'suburban', 'label': 'Suburban Area'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
        displayName: _fullNameController.text.trim(),
      );
      
      if (result != null && mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Registration successful! Please check your email for verification.',
        );
        Navigator.of(context).pushReplacement(
          NaturePageRoute(
            child: const RoleSelectionScreen(),
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          NatureHeroAnimation(
            tag: 'app_logo',
            child: Text(
              'Join EcoSched!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your account to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Full Name Field
          AnimatedTextField(
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: Icons.person_outlined,
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
          AnimatedTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: Icons.email_outlined,
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
          
          // Phone Field
          AnimatedTextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            prefixIcon: Icons.phone_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Organization Field
          AnimatedTextField(
            controller: _organizationController,
            textInputAction: TextInputAction.next,
            labelText: 'Organization',
            hintText: 'Enter your organization',
            prefixIcon: Icons.business_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your organization';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Role Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Role',
              prefixIcon: const Icon(Icons.work_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            items: _roles.map((role) {
              return DropdownMenuItem<String>(
                value: role['value'],
                child: Text(role['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Service Area Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedServiceArea,
            decoration: InputDecoration(
              labelText: 'Service Area',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
            items: _serviceAreas.map((area) {
              return DropdownMenuItem<String>(
                value: area['value'],
                child: Text(area['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedServiceArea = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Password Field
          AnimatedTextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.next,
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            onSuffixTap: _togglePasswordVisibility,
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
          
          // Confirm Password Field
          AnimatedTextField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            textInputAction: TextInputAction.done,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: Icons.lock_outlined,
            suffixIcon: _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            onSuffixTap: _toggleConfirmPasswordVisibility,
            onSubmitted: _handleRegister,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Terms and Conditions
          Row(
            children: [
              AnimatedCheckbox(
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
              text: 'Create Account',
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
    );
  }
}
