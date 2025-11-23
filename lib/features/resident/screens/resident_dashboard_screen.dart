import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/gradient_background.dart';
import 'feedback_screen.dart';
import 'compost_pit_finder_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  int currentPage = 0;
  int currentNavIndex = 0;

  final List<Widget> pages = const [
    _HomePage(),
    FeedbackScreen(),
    CompostPitFinderScreen(),
    _NotificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Use themed scaffold background so dark mode is respected
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[currentPage],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentNavIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.backgroundSecondary : Colors.white,
        selectedItemColor: isDark ? AppTheme.primaryLight : AppTheme.primary,
        unselectedItemColor: isDark
            ? AppTheme.textInverse.withOpacity(0.7)
            : AppTheme.textSecondary.withOpacity(0.7),
        showUnselectedLabels: true,
        onTap: (navIndex) {
          if (navIndex == 2) {
            _openLiveScan(context);
            return;
          }

          final mappedPageIndex = _mapNavIndexToPageIndex(navIndex);
          setState(() {
            currentNavIndex = navIndex;
            currentPage = mappedPageIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_rounded),
            label: 'Eco',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  void _openLiveScan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveScanScreen(apiKey: AppConstants.geminiApiKey),
        fullscreenDialog: true,
      ),
    );
  }

  int _mapNavIndexToPageIndex(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Reports/Feedback
      case 3:
        return 2; // Eco / Compost Pits
      case 4:
        return 3; // Alerts / Notifications
      default:
        return currentPage;
    }
  }

  Widget _buildGifNavItem(String assetPath, {bool isEmphasized = false}) {
    final double size = isEmphasized ? 34 : 28;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.label,
  });
}

class _EcoNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLiveScanPressed;

  const _EcoNavigationBar({
    required this.currentIndex,
    required this.onItemSelected,
    required this.onLiveScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    const navItems = [
      _NavItemData(icon: Icons.home_rounded, label: 'Home'),
      _NavItemData(icon: Icons.article_rounded, label: 'Reports'),
      _NavItemData(icon: Icons.eco_rounded, label: 'Eco'),
      _NavItemData(icon: Icons.notifications_none_rounded, label: 'Alerts'),
    ];

    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radius2XL),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing6,
              vertical: AppTheme.spacing1,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < navItems.length; i++) ...[
                  _NavIconButton(
                    icon: navItems[i].icon,
                    label: navItems[i].label,
                    isSelected: currentIndex == i,
                    onTap: () => onItemSelected(i),
                  ),
                  if (i == 1)
                    const SizedBox(width: 66), // space for floating camera
                ],
              ],
            ),
          ),

          /// Floating Camera Button
          // AnimatedPositioned(
          //   duration: const Duration(milliseconds: 260),
          //   curve: Curves.easeOutBack,
          //   // When Home (index 0) is selected, bring the camera noticeably closer to the bar
          //   top: currentIndex == 0 ? -4 : -26,
          //   child: GestureDetector(
          //     onTap: onLiveScanPressed,
          //     child: Container(
          //       width: 66,
          //       height: 66,
          //       decoration: BoxDecoration(
          //         color: Colors.white,
          //         shape: BoxShape.circle,
          //         boxShadow: [
          //           BoxShadow(
          //             color: AppTheme.accentBlue.withOpacity(0.35),
          //             blurRadius: 16,
          //             offset: const Offset(0, 6),
          //           ),
          //         ],
          //       ),
          //       child: Container(
          //         margin: const EdgeInsets.all(5),
          //         decoration: const BoxDecoration(
          //           gradient: LinearGradient(
          //             colors: [AppTheme.accentBlue, AppTheme.secondary],
          //             begin: Alignment.topLeft,
          //             end: Alignment.bottomRight,
          //           ),
          //           shape: BoxShape.circle,
          //         ),
          //         child: const Icon(
          //           Icons.camera_alt_rounded,
          //           color: Colors.white,
          //           size: 28,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white.withOpacity(0.7);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected ? activeColor : inactiveColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Page Widget
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EcoSched',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 40,
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
            const SizedBox(height: 2),
          ],
        ),
        centerTitle: false,
        backgroundColor:
            isDarkTheme ? AppTheme.backgroundSecondary : AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final isDark = appState.themeMode == ThemeMode.dark;
              return IconButton(
                tooltip:
                    isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  appState
                      .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              );
            },
          ),
        ],
      ),
      // Use themed scaffold background so dark mode is respected
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                  vertical: responsive.verticalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Today's Overview
                      _buildTodayOverview(context, responsive),

                      SizedBox(height: responsive.spacing(32)),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: (theme.textTheme.titleLarge?.fontSize ??
                                  AppTheme.titleLarge.fontSize!) *
                              responsive.fontSizeMultiplier,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(16)),

                      // Action Buttons - Responsive layout
                      responsive.isMobile
                          ? Column(
                              children: [
                                _buildActionButton(
                                  context,
                                  'Schedule Pickup',
                                  Icons.schedule,
                                  AppTheme.primaryGreen,
                                  () {
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.schedulePickup);
                                  },
                                  responsive,
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                _buildActionButton(
                                  context,
                                  'View Collection History',
                                  Icons.history,
                                  AppTheme.lightGreen,
                                  () {
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.residentCollectionHistory,
                                    );
                                  },
                                  responsive,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    'Schedule Pickup',
                                    Icons.schedule,
                                    AppTheme.primaryGreen,
                                    () {
                                      Navigator.of(context)
                                          .pushNamed(AppRoutes.schedulePickup);
                                    },
                                    responsive,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(16)),
                                Expanded(
                                  child: _buildActionButton(
                                    context,
                                    'View Collection History',
                                    Icons.history,
                                    AppTheme.lightGreen,
                                    () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.residentCollectionHistory,
                                      );
                                    },
                                    responsive,
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
    );
  }

  Widget _buildTodayOverview(BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Overview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: (theme.textTheme.titleLarge?.fontSize ??
                      AppTheme.titleLarge.fontSize!) *
                  responsive.fontSizeMultiplier,
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStatCard(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'Next Pickup',
                  value: 'Scheduled',
                  color: AppTheme.primaryGreen,
                  responsive: responsive,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: _buildOverviewStatCard(
                  context,
                  icon: Icons.recycling_rounded,
                  label: 'Sorting Score',
                  value: 'Great',
                  color: AppTheme.accentBlue,
                  responsive: responsive,
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: _buildOverviewStatCard(
                  context,
                  icon: Icons.emoji_events_rounded,
                  label: 'Eco Points',
                  value: '120',
                  color: AppTheme.accentOrange,
                  responsive: responsive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Responsive responsive,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: responsive.iconSize(22),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: (theme.textTheme.titleMedium?.fontSize ??
                      AppTheme.titleMedium.fontSize!) *
                  responsive.fontSizeMultiplier,
            ),
          ),
          SizedBox(height: responsive.spacing(4)),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: (theme.textTheme.bodySmall?.fontSize ??
                      AppTheme.bodySmall.fontSize!) *
                  responsive.fontSizeMultiplier,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    Responsive responsive,
  ) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Ink(
        decoration: BoxDecoration(
          color: isDarkTheme ? AppTheme.backgroundSecondary : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: AppTheme.shadowSmall,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(20),
          vertical: responsive.spacing(16),
        ),
        child: Row(
          children: [
            Container(
              width: responsive.iconSize(44),
              height: responsive.iconSize(44),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Icon(
                icon,
                color: color,
                size: responsive.iconSize(24),
              ),
            ),
            SizedBox(width: responsive.spacing(16)),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: (theme.textTheme.titleMedium?.fontSize ?? 18) *
                      responsive.fontSizeMultiplier,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: theme.textTheme.bodyMedium?.color ?? AppTheme.textLight,
              size: responsive.iconSize(20),
            ),
          ],
        ),
      ),
    );
  }
}

// Notifications Page Widget
class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Collection Scheduled',
      'message': 'Your waste collection is scheduled for tomorrow at 8:00 AM',
      'time': '2 hours ago',
      'type': 'schedule',
      'isRead': false,
    },
    {
      'title': 'New Compost Pit Available',
      'message':
          'A new compost pit has been added near Victoria Community Center',
      'time': '1 day ago',
      'type': 'info',
      'isRead': false,
    },
    {
      'title': 'Feedback Response',
      'message':
          'Thank you for your feedback. We have implemented your suggestion.',
      'time': '2 days ago',
      'type': 'feedback',
      'isRead': true,
    },
    {
      'title': 'Collection Completed',
      'message':
          'Your waste has been successfully collected. Thank you for participating!',
      'time': '3 days ago',
      'type': 'success',
      'isRead': true,
    },
    {
      'title': 'Reminder: Sort Your Waste',
      'message':
          'Please remember to sort your waste properly for better recycling.',
      'time': '1 week ago',
      'type': 'reminder',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EcoSched',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.textInverse,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 40,
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
          ],
        ),
        centerTitle: false,
        backgroundColor:
            isDarkTheme ? AppTheme.backgroundSecondary : AppTheme.primaryGreen,
        foregroundColor: AppTheme.textInverse,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var notification in notifications) {
                  notification['isRead'] = true;
                }
              });
            },
            child: Text(
              'Mark All Read',
              style: TextStyle(
                color: AppTheme.textInverse,
                fontSize: 14 * responsive.fontSizeMultiplier,
              ),
            ),
          ),
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final isDark = appState.themeMode == ThemeMode.dark;
              return IconButton(
                tooltip:
                    isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                onPressed: () {
                  appState
                      .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              );
            },
          ),
        ],
      ),
      // Use themed scaffold background so dark mode is respected
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GradientBackground(
        economyTheme: true,
        child: SafeArea(
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
                      maxWidth: 1000,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Notifications List
                      ...notifications.map((notification) {
                        return Padding(
                          padding:
                              EdgeInsets.only(bottom: responsive.spacing(12)),
                          child: _buildNotificationCard(
                              context, notification, responsive),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context,
      Map<String, dynamic> notification, Responsive responsive) {
    return Card(
      margin: EdgeInsets.only(bottom: responsive.spacing(12)),
      child: ListTile(
        leading: Container(
          width: responsive.iconSize(40),
          height: responsive.iconSize(40),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification['type']).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: _getNotificationColor(notification['type']),
            size: responsive.iconSize(20),
          ),
        ),
        title: Text(
          notification['title'],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: notification['isRead']
                    ? FontWeight.normal
                    : FontWeight.bold,
                color: AppTheme.textDark,
                fontSize:
                    (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) *
                        responsive.fontSizeMultiplier,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                    fontSize:
                        (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                                14) *
                            responsive.fontSizeMultiplier,
                  ),
            ),
            SizedBox(height: responsive.spacing(4)),
            Text(
              notification['time'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textLight,
                    fontSize:
                        (Theme.of(context).textTheme.bodySmall?.fontSize ??
                                12) *
                            responsive.fontSizeMultiplier,
                  ),
            ),
          ],
        ),
        trailing: notification['isRead']
            ? null
            : Container(
                width: responsive.iconSize(8),
                height: responsive.iconSize(8),
                decoration: const BoxDecoration(
                  color: AppTheme.accentOrange,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          if (mounted) {
            setState(() {
              notification['isRead'] = true;
            });
          }
        },
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'schedule':
        return AppTheme.primaryGreen;
      case 'info':
        return AppTheme.lightGreen;
      case 'feedback':
        return AppTheme.accentOrange;
      case 'success':
        return AppTheme.successGreen;
      case 'reminder':
        return AppTheme.infoBlue;
      default:
        return AppTheme.textLight;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'schedule':
        return Icons.schedule;
      case 'info':
        return Icons.info;
      case 'feedback':
        return Icons.feedback;
      case 'success':
        return Icons.check_circle;
      case 'reminder':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }
}
