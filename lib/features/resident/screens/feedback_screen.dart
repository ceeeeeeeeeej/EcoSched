import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final _messageController = TextEditingController();
  final _barangayController = TextEditingController();
  final _purokController = TextEditingController();

  String _selectedCategory = 'General waste concern | (Kinatibuk-an sa basura)';
  String _selectedPriority = 'Medium | (Kasamtangan)';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General waste concern | (Kinatibuk-an sa basura)',
    'Missed or late garbage collection | (Wala nakuha ang basura)',
    'Schedule or route issue | (Problema sa eskedyul o ruta)',
    'Trash segregation / sorting issue | (Problema sa paglain-lain sa basura)',
    'Overflowing bins or dumpsite | (Aapaw ang basurahan)',
    'Smell or cleanliness issue | (Baho o isyu sa kalimpyo)',
    'EcoSched app (waste app) | (Isyu sa app)',
    'Compliment / Appreciation | (Pagdayeg / Pasalamat)',
    'Good service experience | (Maayong serbisyo)',
    'Efficient collection | (Paspas nga pagkolekta)',
    'Clean area maintained | (Limpyo ang palibot)',
  ];

  bool get _isPositiveFeedback {
    return [
      'Compliment / Appreciation | (Pagdayeg / Pasalamat)',
      'Good service experience | (Maayong serbisyo)',
      'Efficient collection | (Paspas nga pagkolekta)',
      'Clean area maintained | (Limpyo ang palibot)',
    ].contains(_selectedCategory);
  }

  final List<String> _priorities = [
    'Low | (Ubos)',
    'Medium | (Kasamtangan)',
    'High | (Hataas)',
    'Urgent | (Dinalian)',
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

    // Pre-fill location fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().user;
      if (user != null) {
        setState(() {
          _barangayController.text = user['barangay']?.toString() ?? '';
          _purokController.text = user['purok']?.toString() ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    _barangayController.dispose();
    _purokController.dispose();
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
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Help Us Improve Local Collection\n',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextOnCard,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '(Tabangi Kami sa Pagpalambo)',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Report issues or suggest improvements to waste management in your area. Your feedback helps us maintain a cleaner community.\n\n',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: secondaryTextOnCard,
                                    height: 1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '(I-report ang mga isyu o isugyot ang mga paagi para mapalambo ang pagdumala sa basura sa inyong lugar. Ang imong feedback makatabang sa pagmintinar sa kalimpyo sa atong komunidad.)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: secondaryTextOnCard,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                ),
                              ],
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
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Feedback Details\n',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextOnCard,
                                  ),
                                ),
                                TextSpan(
                                  text: '(Detalye sa Feedback)',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Category Selection
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Category\n',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextOnCard,
                                  ),
                                ),
                                TextSpan(
                                  text: '(Kategorya)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: secondaryTextOnCard,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldFillColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return _categories.map((String category) {
                                final parts = category.split(' | ');
                                final english = parts[0];
                                final bisaya = parts.length > 1 ? parts[1] : '';

                                return Container(
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$english\n',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: primaryTextOnCard,
                                          ),
                                        ),
                                        if (bisaya.isNotEmpty)
                                          TextSpan(
                                            text: bisaya,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: secondaryTextOnCard,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items: _categories.map((String category) {
                              final parts = category.split(' | ');
                              final english = parts[0];
                              final bisaya = parts.length > 1 ? parts[1] : '';

                              return DropdownMenuItem<String>(
                                value: category,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      english,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    if (bisaya.isNotEmpty)
                                      Text(
                                        bisaya,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: secondaryTextOnCard,
                                        ),
                                      ),
                                  ],
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

                          if (!_isPositiveFeedback) ...[
                            // Priority Selection
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Priority Level\n',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: primaryTextOnCard,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '(Antas sa prayoridad)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: secondaryTextOnCard,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: fieldFillColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              selectedItemBuilder: (BuildContext context) {
                                return _priorities.map((String priority) {
                                  final parts = priority.split(' | ');
                                  final english = parts[0];
                                  final bisaya = parts.length > 1 ? parts[1] : '';

                                  return Container(
                                    alignment: Alignment.centerLeft,
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$english\n',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: primaryTextOnCard,
                                            ),
                                          ),
                                          if (bisaya.isNotEmpty)
                                            TextSpan(
                                              text: bisaya,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: secondaryTextOnCard,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              items: _priorities.map((String priority) {
                                final parts = priority.split(' | ');
                                final english = parts[0];
                                final bisaya = parts.length > 1 ? parts[1] : '';

                                return DropdownMenuItem<String>(
                                  value: priority,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$english\n',
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: primaryTextOnCard,
                                            ),
                                          ),
                                          if (bisaya.isNotEmpty)
                                            TextSpan(
                                              text: bisaya,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: secondaryTextOnCard,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
                          ],


                          // Message Field
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Additional Details\n',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextOnCard,
                                  ),
                                ),
                                TextSpan(
                                  text: '(Dugang Detalye)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: secondaryTextOnCard,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Please provide specific details to help us address your concern. \n\n(Palihug paghatag og espesipikong detalye aron matabangan namo ang imong reklamo.)',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryTextOnCard.withOpacity(0.6),
                              ),
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
                          const SizedBox(height: 16),

                          // Location Detail Fields
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Barangay\n',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: primaryTextOnCard,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '(Barangay)',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: secondaryTextOnCard,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _barangayController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Victoria',
                                        filled: true,
                                        fillColor: fieldFillColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Purok\n',
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: primaryTextOnCard,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '(Purok)',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: secondaryTextOnCard,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _purokController,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Purok 1',
                                        filled: true,
                                        fillColor: fieldFillColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    AnimatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSubmitting
                                ? Icons.hourglass_empty_rounded
                                : Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _isSubmitting
                                      ? 'Submitting...\n'
                                      : 'Submit Feedback\n',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: _isSubmitting
                                      ? '(Gapadala...)'
                                      : '(I-sumiter ang Feedback)',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onPressed: _isSubmitting ? null : _submitFeedback,
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
        priority: _isPositiveFeedback ? 'Low | (Ubos)' : _selectedPriority,
        message: _messageController.text.trim(),
        isAnonymous: _isAnonymous,
        residentId: user?['uid']?.toString(),
        residentName: user?['displayName']?.toString() ??
            user?['fullName']?.toString() ??
            user?['name']?.toString(),
        residentEmail: _isAnonymous ? null : user?['email']?.toString(),
        serviceArea: user?['serviceArea']?.toString(),
        barangay: _barangayController.text.trim(),
        purok: _purokController.text.trim(),
        isGuest: !authService.isAuthenticated,
      );

      HapticFeedback.lightImpact();

      if (mounted) {
        _formKey.currentState?.reset();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'General waste concern | (Kinatibuk-an sa basura)';
          _selectedPriority = 'Medium | (Kasamtangan)';
          _isAnonymous = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text('Feedback sent | Napadala na'),
              ],
            ),
            content: const Text(
                'Thank you for taking the time to share your feedback. We will review it and use it to improve waste collection in your area. \n\n Salamat sa imong paggahin og oras sa pagpaambit sa imong feedback. Amo kining susihon para sa pagpalambo sa serbisyo sa inyong lugar.'),
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
        String errorMsg = e.toString();
        if (e is PostgrestException) {
          errorMsg = e.message;
          if (e.details != null && e.details.toString().isNotEmpty) {
            errorMsg += ': ${e.details}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $errorMsg'),
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
