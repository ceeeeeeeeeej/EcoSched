import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/feedback_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'General waste concern';
  String _selectedPriority = 'Medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General waste concern',
    'Missed or late garbage collection',
    'Schedule or route issue',
    'Trash segregation / sorting issue',
    'Overflowing bins or dumpsite',
    'Smell or cleanliness issue',
    'EcoSched app (waste app)',
  ];

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Urgent',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final Color primaryTextOnCard =
        isDarkTheme ? theme.colorScheme.onSurface : AppTheme.textDark;
    final Color secondaryTextOnCard = isDarkTheme
        ? theme.colorScheme.onSurface.withOpacity(0.8)
        : AppTheme.textLight;
    final Color fieldFillColor = isDarkTheme
        ? theme.colorScheme.surface.withOpacity(0.95)
        : Colors.white.withOpacity(0.8);

    return Scaffold(
      appBar: PremiumAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EcoSched',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textInverse,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/house.gif',
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    GlassmorphicContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.feedback_rounded,
                                color: AppTheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Help Us Improve Local Collection',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextOnCard,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Report issues or suggest improvements to waste management in your area. Your feedback helps us maintain a cleaner community.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: secondaryTextOnCard,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feedback Form
                    GlassmorphicContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Feedback Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryTextOnCard,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Category Selection
                          Text(
                            'Category',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryTextOnCard,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldFillColor,
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Priority Selection
                          Text(
                            'Priority Level',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryTextOnCard,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedPriority,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldFillColor,
                            ),
                            items: _priorities.map((String priority) {
                              return DropdownMenuItem<String>(
                                value: priority,
                                child: Text(
                                  priority,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPriority = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Title Field
                          Text(
                            'Subject',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryTextOnCard,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText:
                                  'Summarize your feedback in a few words',
                              filled: true,
                              fillColor: fieldFillColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a subject.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Message Field
                          Text(
                            'Additional Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryTextOnCard,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Please provide specific details to help us address your concern.',
                              filled: true,
                              fillColor: fieldFillColor,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please provide additional details.';
                              }
                              if (value.length < 10) {
                                return 'Please provide more specific information.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    AnimatedButton(
                      text: _isSubmitting
                          ? 'Submitting Request...'
                          : 'Submit Feedback',
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      icon: _isSubmitting
                          ? Icons.hourglass_empty_rounded
                          : Icons.send_rounded,
                      isGradient: true,
                      gradientColors: AppTheme.primaryGradient,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final feedbackService = context.read<FeedbackService>();
    final authService = context.read<AuthService>();
    final user = authService.user;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await feedbackService.submitFeedback(
        category: _selectedCategory,
        priority: _selectedPriority,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        isAnonymous: _isAnonymous,
        residentId: user?['uid']?.toString(),
        residentName: user?['displayName']?.toString() ??
            user?['fullName']?.toString() ??
            user?['name']?.toString(),
        residentEmail: _isAnonymous ? null : user?['email']?.toString(),
        serviceArea: user?['serviceArea']?.toString(),
        barangay: user?['barangay']?.toString(),
        purok: user?['purok']?.toString(),
      );

      HapticFeedback.lightImpact();

      if (mounted) {
        _formKey.currentState?.reset();
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = _categories.first;
          _selectedPriority = 'Medium';
          _isAnonymous = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Feedback sent'),
              ],
            ),
            content: const Text(
                'Thank you for taking the time to share your feedback. We will review it and use it to improve waste collection in your area.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting feedback: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Submission failed: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
