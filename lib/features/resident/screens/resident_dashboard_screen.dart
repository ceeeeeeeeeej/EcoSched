import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/animations.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/services/bin_service.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/modern_card.dart';
import '../widgets/schedule_card.dart';
import 'feedback_screen.dart';
import 'special_collection_list_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  int currentPage = 0;
  int currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      final serviceArea = user?['serviceArea'] ??
          user?['barangay'] ??
          user?['location'] ??
          'victoria';
      final String effectiveArea =
          serviceArea.toString().split(',')[0].trim().toLowerCase();

      if (kDebugMode) {
        print(
            '🏠 ResidentDashboard: Initializing for Area: $effectiveArea (raw: $serviceArea)');
        print('🏠 User Data: $user');
      }
      Provider.of<PickupService>(context, listen: false)
          .loadSchedulesForServiceArea(effectiveArea);
    });
  }

  final List<Widget> pages = const [
    _HomePage(),
    FeedbackScreen(),
    SpecialCollectionListScreen(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.backgroundSecondary.withOpacity(0.5)
              : Colors.white.withOpacity(0.5),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: GNav(
                  gap: 10,
                  activeColor: Colors.white,
                  iconSize: 22,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: AppTheme.primary,
                  tabBorderRadius: AppTheme.radiusL,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  tabs: const [
                    GButton(
                      icon: Icons.home_rounded,
                      text: 'Home',
                    ),
                    GButton(
                      icon: Icons.feedback_rounded,
                      text: 'Feedback',
                    ),
                    GButton(
                      icon: Icons.camera_rounded,
                      text: 'Scan',
                    ),
                    GButton(
                      icon: Icons.local_shipping_rounded,
                      text: 'Special',
                    ),
                    GButton(
                      icon: Icons.notifications_rounded,
                      text: 'Alerts',
                    ),
                  ],
                  selectedIndex: currentNavIndex,
                  onTabChange: (index) {
                    if (index == 2) {
                      _openLiveScan(context);
                      return;
                    }
                    final mappedPageIndex = _mapNavIndexToPageIndex(index);
                    setState(() {
                      currentNavIndex = index;
                      currentPage = mappedPageIndex;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
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
        return 1; // Feedback
      case 3:
        return 2; // Special Collection
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
      _NavItemData(icon: Icons.article_rounded, label: 'Feedback'),
      _NavItemData(icon: Icons.local_shipping_rounded, label: 'Special'),
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

    return Scaffold(
      appBar: PremiumAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: AppTheme.textInverse, size: 28),
            const SizedBox(width: 8),
            Text(
              'EcoSched',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textInverse,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                tooltip:
                    isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded),
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
              return RefreshIndicator(
                onRefresh: () async {
                  final serviceArea =
                      Provider.of<AuthService>(context, listen: false)
                          .user?['serviceArea'];
                  if (serviceArea != null) {
                    await Provider.of<PickupService>(context, listen: false)
                        .loadSchedulesForServiceArea(serviceArea.toString());
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalPadding,
                    vertical: responsive.verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Only upcoming collection card is shown to simplify UI
                        _buildUpcomingCollectionCard(context, responsive),
                        SizedBox(height: responsive.spacing(24)),
                        // assigned schedule section removed per request
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Assigned schedule and empty state methods removed to simplify home screen

  String _formatAssignedDate(dynamic rawDate) {
    if (rawDate is DateTime) {
      return _formatDate(rawDate);
    }
    if (rawDate is String && rawDate.isNotEmpty) {
      return rawDate;
    }
    return 'Date to be announced';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  Widget _buildUpcomingCollectionCard(
      BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    return Consumer<PickupService>(
      builder: (context, pickupService, _) {
        // Get user's service area
        final auth = Provider.of<AuthService>(context, listen: false);
        final user = auth.user;
        final serviceArea = user?['barangay'] ?? user?['location'] ?? '';

        // Get next collection
        final nextCollection = pickupService.getNextCollection(serviceArea);

        if (nextCollection == null) {
          return const SizedBox.shrink();
        }

        final collectionDate = nextCollection['date'] as DateTime;
        final now = DateTime.now();
        final daysUntil = collectionDate.difference(now).inDays;
        final isRescheduled = nextCollection['isRescheduled'] ?? false;
        final rescheduledReason = nextCollection['rescheduledReason'] ?? '';

        final String area = (nextCollection['address'] ?? '').toString();
        String wasteType =
            (nextCollection['type'] ?? 'Eco Collection').toString();
        if (area.isNotEmpty && area.toLowerCase() != 'unknown area') {
          final capArea =
              area[0].toUpperCase() + area.substring(1).toLowerCase();
          if (!wasteType.toLowerCase().contains(area.toLowerCase())) {
            wasteType = '$capArea $wasteType';
          }
        }

        return AppAnimations.fadeInSlideUp(
          duration: AppAnimations.normal,
          offset: 20,
          child: ModernCard(
            gradient: isRescheduled
                ? [AppTheme.accentOrange, const Color(0xFFFF6B6B)]
                : [AppTheme.primaryGreen, AppTheme.lightGreen],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isRescheduled
                            ? Icons.schedule_outlined
                            : Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isRescheduled
                                      ? 'Collection Rescheduled'
                                      : 'Upcoming Collection',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isRescheduled)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'RESCHEDULED',
                                    style: TextStyle(
                                      color: AppTheme.accentOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            wasteType,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(collectionDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextCollection['time'] ?? '08:00',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppAnimations.pulse(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$daysUntil',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              daysUntil == 1 ? 'day' : 'days',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isRescheduled && rescheduledReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reason: $rescheduledReason',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.user;
      final barangay = user?['barangay'] ?? user?['location'] ?? 'victoria';
      Provider.of<BinService>(context, listen: false)
          .loadBinsForArea(barangay.toString());
    });
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} minutes ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final reminderService = context.watch<ReminderService>();

    final allNotifications = reminderService.reminders;

    return Scaffold(
      appBar: PremiumAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
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
        actions: [
          if (reminderService.unreadCount > 0)
            TextButton(
              onPressed: () => reminderService.markAllAsRead(),
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: AppTheme.textInverse,
                  fontSize: 14 * responsive.fontSizeMultiplier,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Removed Bin Status Section

                      Text(
                        'Notifications',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20 * responsive.fontSizeMultiplier,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(12)),

                      if (allNotifications.isEmpty)
                        _buildEmptyAlertsState(context, responsive)
                      else
                        // Notifications List
                        ...allNotifications.map((notification) {
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

  Widget _buildEmptyAlertsState(BuildContext context, Responsive responsive) {
    return GlassmorphicContainer(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(32)),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 48,
            color: AppTheme.textLight.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'All clear! No notifications at this time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context,
      Map<String, dynamic> notification, Responsive responsive) {
    final theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final reminderService = context.read<ReminderService>();

    final dynamic id = notification['id'];
    final bool isRead = notification['read'] ?? false;
    final DateTime createdAt = notification['createdAt'] as DateTime;

    return Card(
      margin: EdgeInsets.only(bottom: responsive.spacing(12)),
      elevation: isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        side: BorderSide(
          color:
              isRead ? Colors.transparent : AppTheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
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
          notification['title'] ?? 'Notification',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color:
                isDarkTheme ? theme.colorScheme.onSurface : AppTheme.textDark,
            fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) *
                responsive.fontSizeMultiplier,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkTheme
                    ? theme.colorScheme.onSurface.withOpacity(0.75)
                    : AppTheme.textLight,
                fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) *
                    responsive.fontSizeMultiplier,
              ),
            ),
            SizedBox(height: responsive.spacing(4)),
            Text(
              _relativeTime(createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDarkTheme
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : AppTheme.textLight,
                fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) *
                    responsive.fontSizeMultiplier,
              ),
            ),
          ],
        ),
        trailing: isRead
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
          reminderService.markAsRead(id);
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
