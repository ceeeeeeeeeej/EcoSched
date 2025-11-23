import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_router.dart';
import '../../core/utils/responsive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTermsAcceptance();
  }

  Future<void> _checkTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('terms_accepted') ?? false;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (!accepted) {
        // Show terms dialog after a brief delay to ensure UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTermsAcceptanceDialog();
        });
      }
    }
  }

  Future<void> _saveTermsAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryTextColor = colorScheme.onSurface;
    final secondaryTextColor = colorScheme.onSurface.withOpacity(0.7);
    final cardGradient = LinearGradient(
      colors: isDarkMode
          ? [colorScheme.primaryContainer, colorScheme.primary]
          : [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Show loading or blocked UI if terms not accepted
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: responsive.padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: responsive.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Title
                  Container(
                    width: responsive.iconSize(120),
                    height: responsive.iconSize(120),
                    decoration: BoxDecoration(
                      gradient: cardGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.eco,
                      size: responsive.iconSize(60),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing8)),

                  // App Title
                  Text(
                    'EcoSched',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          letterSpacing: -1,
                          fontSize: (Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.fontSize ??
                                  32) *
                              responsive.fontSizeMultiplier,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing2)),
                  Text(
                    'Smart Waste Collection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: secondaryTextColor,
                          fontSize: (Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.fontSize ??
                                  16) *
                              responsive.fontSizeMultiplier,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing8 * 2)),

                  // Subtitle
                  Text(
                    'Choose your barangay to get started',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                          fontSize: (Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.fontSize ??
                                  22) *
                              responsive.fontSizeMultiplier,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing2)),
                  Text(
                    'EcoSched will tailor pickup schedules and updates for your community.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                          height: 1.4,
                        ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing8)),

                  // Barangay Cards Container
                  SizedBox(
                    width: responsive.getContainerWidth(
                      mobilePercent: 1.0,
                      tabletPercent: 0.7,
                      desktopPercent: 0.5,
                      maxWidth: 500,
                    ),
                    child: Column(
                      children: [
                        // Barangay Victoria Card
                        _buildBarangayCard(
                          context,
                          'Barangay Victoria',
                          Icons.location_city,
                          AppTheme.primaryGreen,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.residentLocationSelection,
                              arguments: 'Victoria',
                            );
                          },
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spacing6)),

                        // Barangay Dayo-ay Card
                        _buildBarangayCard(
                          context,
                          'Barangay Dayo-ay',
                          Icons.location_city,
                          AppTheme.accentOrange,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.residentLocationSelection,
                              arguments: 'Dayo-an',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing8)),

                  // Collector Login Button
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.collectorLogin);
                    },
                    child: Text(
                      'Login as Collector',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14 * responsive.fontSizeMultiplier,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spacing8)),

                  // Terms and Privacy Policy Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _showTermsDialog(context),
                        child: Text(
                          'Terms of Service',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12 * responsive.fontSizeMultiplier,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12 * responsive.fontSizeMultiplier,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showPrivacyDialog(context),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12 * responsive.fontSizeMultiplier,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsAcceptanceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot close by tapping outside
      builder: (dialogContext) => _TermsAcceptanceDialog(
        onAccept: _saveTermsAcceptance,
        onViewTerms: () {
          Navigator.of(dialogContext).pop();
          _showTermsDialog(context);
        },
        onViewPrivacy: () {
          Navigator.of(dialogContext).pop();
          _showPrivacyDialog(context);
        },
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Terms of Service'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. Acceptance of Terms'),
              const SizedBox(height: 8),
              const Text(
                'By accessing and using EcoSched, you accept and agree to be bound by the terms and provision of this agreement.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. Use License'),
              const SizedBox(height: 8),
              const Text(
                'Permission is granted to temporarily use EcoSched for personal, non-commercial use only. This is the grant of a license, not a transfer of title.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. User Responsibilities'),
              const SizedBox(height: 8),
              const Text(
                'Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Service Availability'),
              const SizedBox(height: 8),
              const Text(
                'We reserve the right to modify, suspend, or discontinue any part of the service at any time without prior notice.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('5. Limitation of Liability'),
              const SizedBox(height: 8),
              const Text(
                'EcoSched shall not be liable for any indirect, incidental, special, or consequential damages resulting from the use or inability to use the service.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('1. Information We Collect'),
              const SizedBox(height: 8),
              const Text(
                'We collect information that you provide directly to us, including your location (barangay and purok), schedule preferences, and feedback.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('2. How We Use Your Information'),
              const SizedBox(height: 8),
              const Text(
                'We use the information we collect to provide, maintain, and improve our services, including waste collection scheduling and notifications.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('3. Data Sharing'),
              const SizedBox(height: 8),
              const Text(
                'We do not sell, trade, or rent your personal information to third parties. We may share data with local government units for service delivery purposes only.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('4. Data Security'),
              const SizedBox(height: 8),
              const Text(
                'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('5. Your Rights'),
              const SizedBox(height: 8),
              const Text(
                'You have the right to access, update, or delete your personal information at any time through the app settings or by contacting us.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('6. Contact Us'),
              const SizedBox(height: 8),
              const Text(
                'If you have questions about this Privacy Policy, please contact us through the feedback section in the app.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }
}

// Terms Acceptance Dialog Widget
class _TermsAcceptanceDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onViewTerms;
  final VoidCallback onViewPrivacy;

  const _TermsAcceptanceDialog({
    required this.onAccept,
    required this.onViewTerms,
    required this.onViewPrivacy,
  });

  @override
  State<_TermsAcceptanceDialog> createState() => _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends State<_TermsAcceptanceDialog> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isViewingTerms = false;
  bool _isViewingPrivacy = false;

  bool get _canAccept => _agreedToTerms && _agreedToPrivacy;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // If viewing full terms or privacy, show that content
    if (_isViewingTerms) {
      return _buildFullTermsView();
    }
    if (_isViewingPrivacy) {
      return _buildFullPrivacyView();
    }

    // Main acceptance dialog
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from closing
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: responsive.isMobile ? double.infinity : 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.gavel,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Privacy',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please read and accept to continue',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to EcoSched',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Before you continue, please review and accept our Terms of Service and Privacy Policy to use our waste management services.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textLight,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Terms Checkbox
                      _buildAgreementCheckbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        label: 'I agree to the',
                        linkText: 'Terms of Service',
                        onLinkTap: () {
                          setState(() {
                            _isViewingTerms = true;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Privacy Checkbox
                      _buildAgreementCheckbox(
                        value: _agreedToPrivacy,
                        onChanged: (value) {
                          setState(() {
                            _agreedToPrivacy = value ?? false;
                          });
                        },
                        label: 'I agree to the',
                        linkText: 'Privacy Policy',
                        onLinkTap: () {
                          setState(() {
                            _isViewingPrivacy = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with Accept Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Cannot proceed without accepting
                          if (!_canAccept) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please accept both Terms and Privacy Policy to continue'),
                                backgroundColor: AppTheme.accentOrange,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.textLight),
                        ),
                        child: Text(
                          'Decline',
                          style: TextStyle(color: AppTheme.textLight),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _canAccept
                            ? () {
                                widget.onAccept();
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: const Text(
                          'Accept & Continue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String linkText,
    required VoidCallback onLinkTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textDark,
                    ),
                children: [
                  TextSpan(text: '$label '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullTermsView() {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _isViewingTerms = false;
        });
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isViewingTerms = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terms of Service',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('1. Acceptance of Terms'),
                      const SizedBox(height: 8),
                      const Text(
                        'By accessing and using EcoSched, you accept and agree to be bound by the terms and provision of this agreement.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. Use License'),
                      const SizedBox(height: 8),
                      const Text(
                        'Permission is granted to temporarily use EcoSched for personal, non-commercial use only. This is the grant of a license, not a transfer of title.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. User Responsibilities'),
                      const SizedBox(height: 8),
                      const Text(
                        'Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Service Availability'),
                      const SizedBox(height: 8),
                      const Text(
                        'We reserve the right to modify, suspend, or discontinue any part of the service at any time without prior notice.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('5. Limitation of Liability'),
                      const SizedBox(height: 8),
                      const Text(
                        'EcoSched shall not be liable for any indirect, incidental, special, or consequential damages resulting from the use or inability to use the service.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullPrivacyView() {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _isViewingPrivacy = false;
        });
        return false;
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 600,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isViewingPrivacy = false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('1. Information We Collect'),
                      const SizedBox(height: 8),
                      const Text(
                        'We collect information that you provide directly to us, including your location (barangay and purok), schedule preferences, and feedback.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('2. How We Use Your Information'),
                      const SizedBox(height: 8),
                      const Text(
                        'We use the information we collect to provide, maintain, and improve our services, including waste collection scheduling and notifications.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('3. Data Sharing'),
                      const SizedBox(height: 8),
                      const Text(
                        'We do not sell, trade, or rent your personal information to third parties. We may share data with local government units for service delivery purposes only.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('4. Data Security'),
                      const SizedBox(height: 8),
                      const Text(
                        'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('5. Your Rights'),
                      const SizedBox(height: 8),
                      const Text(
                        'You have the right to access, update, or delete your personal information at any time through the app settings or by contacting us.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle('6. Contact Us'),
                      const SizedBox(height: 8),
                      const Text(
                        'If you have questions about this Privacy Policy, please contact us through the feedback section in the app.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }
}

// Barangay Card Builder Helper Function
Widget _buildBarangayCard(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  final responsive = context.responsive;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusL),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spacing8)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spacing4)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: color,
                size: responsive.iconSize(32),
              ),
            ),
            SizedBox(width: responsive.spacing(AppTheme.spacing6)),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize:
                          (Theme.of(context).textTheme.titleLarge?.fontSize ??
                                  22) *
                              responsive.fontSizeMultiplier,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: responsive.iconSize(20),
            ),
          ],
        ),
      ),
    ),
  );
}
