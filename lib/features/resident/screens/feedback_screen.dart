import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/animated_card.dart';

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
  final _emailController = TextEditingController();

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
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash & Waste Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.feedback,
                                color: AppTheme.primaryGreen,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Share Your Waste Feedback',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Help us improve trash collection and waste management in your area by reporting any issues or suggestions.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Feedback Form
                    GlassmorphicContainer(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trash / Waste Feedback Details',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Category Selection
                          Text(
                            'Waste issue category',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
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
                            'Priority',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPriority,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            items: _priorities.map((String priority) {
                              return DropdownMenuItem<String>(
                                value: priority,
                                child: Text(priority),
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
                            'Issue title',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText:
                                  'Short title for your trash / waste concern (e.g. missed pickup)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Message Field
                          Text(
                            'Details about the trash / waste issue',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Please describe what happened (location, time, trash type, etc.)...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius),
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your message';
                              }
                              if (value.length < 10) {
                                return 'Please provide more details (at least 10 characters)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field (if not anonymous)
                          if (!_isAnonymous) ...[
                            Text(
                              'Email (Optional)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'your.email@example.com',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.borderRadius),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.8),
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Anonymous Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _isAnonymous,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isAnonymous = value ?? false;
                                    if (_isAnonymous) {
                                      _emailController.clear();
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryGreen,
                              ),
                              Expanded(
                                child: Text(
                                  'Submit anonymously',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textDark,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    AnimatedButton(
                      text: _isSubmitting ? 'Submitting...' : 'Submit Feedback',
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      icon: _isSubmitting ? Icons.hourglass_empty : Icons.send,
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 16),

                    // Recent Feedback
                    Text(
                      'Recent Waste Feedback',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                    ),
                    const SizedBox(height: 16),

                    _buildRecentFeedbackCard(
                      'Missed or late garbage collection',
                      'Garbage truck skipped our street near Purok 2 last Monday.',
                      '2 days ago',
                      'High',
                    ),
                    const SizedBox(height: 12),

                    _buildRecentFeedbackCard(
                      'Trash segregation help',
                      'The app helped me understand how to separate biodegradable and non-biodegradable waste.',
                      '1 week ago',
                      'Medium',
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

  Widget _buildRecentFeedbackCard(
      String category, String message, String time, String priority) {
    Color priorityColor = _getPriorityColor(priority);

    return AnimatedCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white.withOpacity(0.8),
      borderRadius: AppConstants.borderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark,
                ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.accentOrange;
      case 'Medium':
        return AppTheme.primaryGreen;
      case 'Low':
        return AppTheme.lightGreen;
      default:
        return AppTheme.textLight;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    HapticFeedback.lightImpact();

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Feedback Submitted'),
            ],
          ),
          content: const Text(
              'Thank you for your waste feedback. We will review it and use it to improve trash collection and waste services.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
