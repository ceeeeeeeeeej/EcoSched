import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/translations.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/animations.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/services/bin_service.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/modern_card.dart';
import 'feedback_screen.dart';
import 'resident_location_map_screen.dart';
import 'special_collection_list_screen.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/services/notification_service.dart';

class ResidentDashboardScreen extends StatefulWidget {
  final int initialNavIndex;

  const ResidentDashboardScreen({
    super.key,
    this.initialNavIndex = 0,
  });

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
    currentNavIndex = widget.initialNavIndex;
    currentPage = _mapNavIndexToPageIndex(widget.initialNavIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);

      void initLogic() {
        if (!mounted) return;
        // Safety check: redirect to location selection if no barangay is selected
        if (!authService.hasBarangaySelected) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.residentLocationSelection,
            (route) => false,
          );
          return;
        }

        final user = authService.user;
        final serviceArea = user?['serviceArea'] ??
            user?['barangay'] ??
            user?['location'] ??
            '';
        final String effectiveArea =
            serviceArea.toString().split(',')[0].trim();

        if (kDebugMode) {
          print(
              '🏠 ResidentDashboard: Initializing for Area: $effectiveArea (raw: $serviceArea)');
          print('🏠 User Data: $user');
        }
        Provider.of<PickupService>(context, listen: false)
            .loadSchedulesForServiceArea(effectiveArea);
      }

      if (authService.isAuthCheckComplete) {
        initLogic();
      } else {
        void listener() {
          if (authService.isAuthCheckComplete) {
            authService.removeListener(listener);
            initLogic();
          }
        }

        authService.addListener(listener);
      }
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
                  iconSize: 26,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  duration: const Duration(milliseconds: 400),
                  tabBackgroundColor: AppTheme.primary,
                  tabBorderRadius: AppTheme.radiusL,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  tabs: [
                    GButton(
                      icon: Icons.home_rounded,
                      text: context.tr('home'),
                    ),
                    GButton(
                      icon: Icons.feedback_rounded,
                      text: context.tr('feedback'),
                    ),
                    GButton(
                      icon: Icons.qr_code_scanner_rounded,
                      text: context.tr('ecoscan'),
                    ),
                    GButton(
                      icon: Icons.local_shipping_rounded,
                      text: context.tr('special'),
                    ),
                    GButton(
                      icon: Icons.notifications_rounded,
                      text: context.tr('alerts'),
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
            Image.asset(
              'assets/images/ecosched_logo.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('app_title'),
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textInverse,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change Barangay',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.splash,
                (route) => false,
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
                        // 2. Reminder Card
                        _buildReminderCard(context, responsive),
                        SizedBox(height: responsive.spacing(24)),

                        // 2. Instructions Card
                        _buildInstructionsCard(context, responsive),
                        SizedBox(height: responsive.spacing(24)),

                        // 3. Today's Schedule Section
                        Consumer<PickupService>(
                          builder: (context, pickupService, _) {
                            final auth = Provider.of<AuthService>(context, listen: false);
                            final serviceArea = auth.user?['barangay'] ?? '';
                            final nextCollection = pickupService.getNextCollection(serviceArea);
                            
                            bool isToday = false;
                            if (nextCollection != null) {
                              final date = nextCollection['date'] as DateTime;
                              final now = DateTime.now();
                              isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                            }
                            
                            final headerText = isToday ? "TODAY'S SCHEDULE" : "UPCOMING SCHEDULE";
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(context, headerText),
                                SizedBox(height: responsive.spacing(12)),
                                _buildTodayScheduleCard(context, responsive),
                              ],
                            );
                          },
                        ),
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


  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(BuildContext context, Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8), // Peach/Light Orange background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                context.tr('reminder_highway'),
                style: const TextStyle(
                  color: Color(0xFF8A4D00),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('reminder_highway_body'),
            style: const TextStyle(
              color: Color(0xFF8A4D00),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context, Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin_rounded,
                  color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                context.tr('instructions_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(context, context.tr('instruction_highway')),
          _buildBulletPoint(context, context.tr('instruction_sealed')),
          _buildBulletPoint(context, context.tr('instruction_blocking')),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleCard(BuildContext context, Responsive responsive) {
    return Consumer<PickupService>(
      builder: (context, pickupService, _) {
        final auth = Provider.of<AuthService>(context, listen: false);
        final serviceArea = auth.user?['barangay'] ?? '';
        final nextCollection = pickupService.getNextCollection(serviceArea);

        if (nextCollection == null) {
          return GlassmorphicContainer(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                context.tr('no_collection_today'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final date = nextCollection['date'] as DateTime;
        final now = DateTime.now();
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        
        final dateStr = DateFormat('EEEE, MMM d').format(date);
        final timeStr = nextCollection['time'] ?? '08:00:00';

        return AppAnimations.fadeInSlideUp(
          child: GlassmorphicContainer(
            opacity: 0.25,
            blur: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Icon(Icons.circle_outlined,
                            color: Colors.white70, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collection: ${nextCollection['address'] ?? 'Village'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isToday ? 'Status: Today' : 'Status: Upcoming',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: AppTheme.primaryGreen, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            dateStr,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded,
                              color: Colors.orange, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

        // Calculate daysUntil based on standard calendar dates (ignoring time)
        // so that 'tomorrow' always shows as 1 day instead of 0 days.
        final today = DateTime(now.year, now.month, now.day);
        final targetDate = DateTime(
            collectionDate.year, collectionDate.month, collectionDate.day);
        final daysUntil = targetDate.difference(today).inDays;
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
                                      ? context.tr('collection_rescheduled')
                                      : context.tr('upcoming_collection'),
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
                            context.tr('date'),
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
                            context.tr('time'),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              daysUntil == 0
                                  ? (collectionDate.isBefore(now)
                                      ? 'NOW'
                                      : 'TODAY')
                                  : '$daysUntil',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: (daysUntil == 0) ? 14 : 24,
                              ),
                            ),
                            if (daysUntil != 0)
                              Text(
                                daysUntil == 1
                                    ? context.tr('day')
                                    : context.tr('days'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 10,
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
                            '${context.tr('reason')}: $rescheduledReason',
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
    if (diff.inMinutes < 1) return context.tr('just_now');
    if (diff.inHours < 1)
      return context.tr('minutes_ago', args: [diff.inMinutes.toString()]);
    if (diff.inDays < 1)
      return context.tr('hours_ago', args: [diff.inHours.toString()]);
    if (diff.inDays < 7)
      return context.tr('days_ago', args: [diff.inDays.toString()]);
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
              context.tr('notifications'),
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
                context.tr('mark_all_read'),
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
                        context.tr('notifications'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 20 * responsive.fontSizeMultiplier,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(24)),

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
          Text(
            context.tr('no_notifications'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textLight),
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
