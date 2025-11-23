import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tailwind_utils.dart';
import '../../core/animations/micro_interactions.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/nature_animations.dart';
import '../../core/transitions/nature_transitions.dart';
import '../../core/error/error_handler.dart';
import '../../core/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../role_selection/role_selection_screen.dart';

class TailwindRegisterScreen extends StatefulWidget {
  final VoidCallback onToggleMode;
  
  const TailwindRegisterScreen({
    super.key,
    required this.onToggleMode,
  });

  @override
  State<TailwindRegisterScreen> createState() => _TailwindRegisterScreenState();
}

class _TailwindRegisterScreenState extends State<TailwindRegisterScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
        NatureHeroAnimation(
          tag: 'app_logo',
          child: Container(
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
          ),
        ).my(8),
        
        // Title
        Text(
          'Join EcoSched!',
          style: Tailwind.text4Xl.copyWith(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ).my(2),
        
        // Subtitle
        Text(
          'Create your account to get started',
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
            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            SizedBox(height: Tailwind.gap4),
            
            // Full Name Field
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              icon: Icons.person_outlined,
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
            
            SizedBox(height: Tailwind.gap4),
            
            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
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
            
            SizedBox(height: Tailwind.gap4),
            
            // Phone Field
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
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
            
            SizedBox(height: Tailwind.gap6),
            
            // Professional Information Section
            _buildSectionHeader('Professional Information'),
            SizedBox(height: Tailwind.gap4),
            
            // Organization Field
            _buildTextField(
              controller: _organizationController,
              label: 'Organization',
              hint: 'Enter your organization',
              icon: Icons.business_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your organization';
                }
                return null;
              },
            ),
            
            SizedBox(height: Tailwind.gap4),
            
            // Role Selection
            _buildDropdownField(
              label: 'Role',
              icon: Icons.work_outlined,
              value: _selectedRole,
              items: _roles,
              onChanged: (value) => setState(() => _selectedRole = value!),
            ),
            
            SizedBox(height: Tailwind.gap4),
            
            // Service Area Selection
            _buildDropdownField(
              label: 'Service Area',
              icon: Icons.location_on_outlined,
              value: _selectedServiceArea,
              items: _serviceAreas,
              onChanged: (value) => setState(() => _selectedServiceArea = value!),
            ),
            
            SizedBox(height: Tailwind.gap6),
            
            // Security Section
            _buildSectionHeader('Security'),
            SizedBox(height: Tailwind.gap4),
            
            // Password Field
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              isVisible: _isPasswordVisible,
              onToggle: _togglePasswordVisibility,
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
            
            SizedBox(height: Tailwind.gap4),
            
            // Confirm Password Field
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm your password',
              isVisible: _isConfirmPasswordVisible,
              onToggle: _toggleConfirmPasswordVisibility,
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
            
            SizedBox(height: Tailwind.gap6),
            
            // Terms and Conditions
            _buildTermsAndConditions(),
            
            SizedBox(height: Tailwind.gap6),
            
            // Register Button
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Tailwind.textLg.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Tailwind.textSm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).mb(2),
        
        AnimatedTextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          hintText: hint,
          prefixIcon: icon,
          showFloatingLabel: false,
          showNatureEffects: true,
          primaryColor: AppTheme.primaryGreen,
          accentColor: AppTheme.accentOrange,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Tailwind.textSm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).mb(2),
        
        AnimatedTextField(
          controller: controller,
          obscureText: !isVisible,
          textInputAction: TextInputAction.next,
          hintText: hint,
          prefixIcon: Icons.lock_outlined,
          suffixIcon: isVisible ? Icons.visibility : Icons.visibility_off,
          onSuffixTap: onToggle,
          showFloatingLabel: false,
          showNatureEffects: true,
          primaryColor: AppTheme.primaryGreen,
          accentColor: AppTheme.accentOrange,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Tailwind.textSm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).mb(2),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: Tailwind.roundedLg,
            border: Border.all(color: AppTheme.neutral200),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.textMuted),
              border: InputBorder.none,
              contentPadding: Tailwind.px4,
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item['value'],
                child: Text(item['label']!),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCheckbox(
          value: _agreeToTerms,
          onChanged: (_) => _toggleAgreeToTerms(),
          activeColor: AppTheme.primaryGreen,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Tailwind.textSm.copyWith(
                color: AppTheme.textLight,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: Tailwind.textSm.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: Tailwind.textSm.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return NatureRippleEffect(
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
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
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
            'Sign In',
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
