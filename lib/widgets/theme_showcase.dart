import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ThemeShowcase extends StatelessWidget {
  const ThemeShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Modern Theme Showcase'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundSecondary,
              AppTheme.backgroundTertiary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacing4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Card(
                  color: AppTheme.surfaceElevated.withOpacity(0.98),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusXL,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Typography Section
                        _buildSection(
                          title: 'Typography',
                          children: [
                            Text(
                              'Display Large',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'Headline Medium',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'Title Large',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'Body Large',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Text(
                              'Body Small',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // Color Palette Section
                        _buildSection(
                          title: 'Color Palette',
                          children: [
                            _buildColorRow(
                                'Primary Green', AppTheme.primaryGreen),
                            _buildColorRow('Primary Green Dark',
                                AppTheme.primaryGreenDark),
                            _buildColorRow('Primary Green Light',
                                AppTheme.primaryGreenLight),
                            _buildColorRow('Accent Blue', AppTheme.accentBlue),
                            _buildColorRow(
                                'Accent Purple', AppTheme.accentPurple),
                            _buildColorRow(
                                'Success Green', AppTheme.successGreen),
                            _buildColorRow(
                                'Warning Yellow', AppTheme.warningYellow),
                            _buildColorRow('Error Red', AppTheme.errorRed),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // Button Styles Section
                        _buildSection(
                          title: 'Button Styles',
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                child: const Text('Primary Button'),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {},
                                child: const Text('Outlined Button'),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Text Button'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // Card Styles Section
                        _buildSection(
                          title: 'Card Styles',
                          children: [
                            Card(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacing4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Card Title',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: AppTheme.spacing2),
                                    Text(
                                      'This is a modern card with enhanced styling, better shadows, and improved spacing.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing3),
                            Card(
                              color: AppTheme.primaryGreenLight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacing4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Colored Card',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: AppTheme.spacing2),
                                    Text(
                                      'Cards can have different background colors while maintaining consistency.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // Input Fields Section
                        _buildSection(
                          title: 'Input Fields',
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icon(Icons.lock_outlined),
                                suffixIcon: Icon(Icons.visibility_outlined),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: AppTheme.spacing4),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Message',
                                hintText: 'Enter your message here...',
                                prefixIcon: Icon(Icons.message_outlined),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spacing8),

                        // Shadow Examples Section
                        _buildSection(
                          title: 'Shadow System',
                          children: [
                            _buildShadowExample(
                                'Extra Small Shadow', AppTheme.shadowXSmall),
                            _buildShadowExample(
                                'Small Shadow', AppTheme.shadowSmall),
                            _buildShadowExample(
                                'Medium Shadow', AppTheme.shadowMedium),
                            _buildShadowExample(
                                'Large Shadow', AppTheme.shadowLarge),
                            _buildShadowExample(
                                'Extra Large Shadow', AppTheme.shadowXLarge),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        ...children,
      ],
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.neutral300),
            ),
          ),
          const SizedBox(width: AppTheme.spacing3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: AppTheme.fontFamilyMono,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowExample(String name, List<BoxShadow> shadows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: shadows,
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
