import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/staggered_list.dart';
import '../widgets/route_card.dart';
import '../widgets/collection_stats_card.dart';
import 'route_planning_screen.dart';
import 'collection_history_screen.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/main_drawer.dart';

class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() => _CollectorDashboardScreenState();
}

class _CollectorDashboardScreenState extends State<CollectorDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _headerController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: Text(
          'Collector Dashboard',
          style: TextStyle(fontSize: 18 * responsive.fontSizeMultiplier),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.camera_alt,
              size: responsive.iconSize(24),
            ),
            tooltip: 'Live Scan',
            onPressed: () {
              // Open live scan screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LiveScanScreen(
                    apiKey: AppConstants.geminiApiKey,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: responsive.verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth: responsive.getContainerWidth(
                        mobilePercent: 1.0,
                        tabletPercent: 0.9,
                        desktopPercent: 0.8,
                        maxWidth: 1200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        SlideTransition(
                          position: _headerSlideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: GlassmorphicContainer(
                              width: double.infinity,
                              padding: EdgeInsets.all(responsive.spacing(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                'Good Morning, John!',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                  fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * responsive.fontSizeMultiplier,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(8)),
                              Text(
                                'Ready to start your collection route?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textLight,
                                  fontSize: (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) * responsive.fontSizeMultiplier,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    
                    // Quick Stats
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Today\'s Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * responsive.fontSizeMultiplier,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(16)),
                    StaggeredGrid(
                      crossAxisCount: responsive.getGridCrossAxisCount(
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                      childAspectRatio: responsive.isMobile ? 1.2 : 1.3,
                      crossAxisSpacing: responsive.spacing(16),
                      mainAxisSpacing: responsive.spacing(16),
                    children: [
                      CollectionStatsCard(
                        title: 'Routes',
                        value: '12',
                        icon: Icons.route,
                        color: AppTheme.primaryGreen,
                      ),
                      CollectionStatsCard(
                        title: 'Completed',
                        value: '8',
                        icon: Icons.check_circle,
                        color: AppTheme.lightGreen,
                      ),
                      CollectionStatsCard(
                        title: 'Efficiency',
                        value: '94%',
                        icon: Icons.trending_up,
                        color: AppTheme.accentOrange,
                      ),
                      CollectionStatsCard(
                        title: 'Time Saved',
                        value: '2.5h',
                        icon: Icons.timer,
                        color: AppTheme.accentOrange,
                      ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(32)),
                    
                    // Today's Routes
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Today\'s Routes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                          fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * responsive.fontSizeMultiplier,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(16)),
                  
                  // Route Cards
                  StaggeredList(
                    children: [
                      BounceInAnimation(
                        child: RouteCard(
                          routeName: 'Downtown District',
                          stops: 15,
                          estimatedTime: '2h 30m',
                          status: 'In Progress',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RoutePlanningScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      BounceInAnimation(
                        delay: const Duration(milliseconds: 200),
                        child: RouteCard(
                          routeName: 'Residential Area A',
                          stops: 22,
                          estimatedTime: '3h 15m',
                          status: 'Pending',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RoutePlanningScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      BounceInAnimation(
                        delay: const Duration(milliseconds: 400),
                        child: RouteCard(
                          routeName: 'Industrial Zone',
                          stops: 8,
                          estimatedTime: '1h 45m',
                          status: 'Completed',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CollectionHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    ),
                    SizedBox(height: responsive.spacing(32)),
                    
                    // Action Buttons - Responsive layout
                    responsive.isMobile
                        ? Column(
                            children: [
                              AnimatedButton(
                                text: 'Start Route',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RoutePlanningScreen(),
                                    ),
                                  );
                                },
                                icon: Icons.play_arrow,
                                width: double.infinity,
                              ),
                              SizedBox(height: responsive.spacing(16)),
                              AnimatedButton(
                                text: 'View History',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CollectionHistoryScreen(),
                                    ),
                                  );
                                },
                                backgroundColor: AppTheme.accentOrange,
                                icon: Icons.history,
                                width: double.infinity,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: AnimatedButton(
                                  text: 'Start Route',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RoutePlanningScreen(),
                                      ),
                                    );
                                  },
                                  icon: Icons.play_arrow,
                                ),
                              ),
                              SizedBox(width: responsive.spacing(16)),
                              Expanded(
                                child: AnimatedButton(
                                  text: 'View History',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CollectionHistoryScreen(),
                                      ),
                                    );
                                  },
                                  backgroundColor: AppTheme.accentOrange,
                                  icon: Icons.history,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
