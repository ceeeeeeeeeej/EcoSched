import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/translations.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/reminder_service.dart';
import '../../../core/services/bin_service.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/gradient_background.dart';
import 'feedback_screen.dart';
import 'resident_location_map_screen.dart';
import 'special_collection_list_screen.dart';
import '../widgets/schedule_card.dart';
import '../../../core/routes/app_router.dart';

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

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen>
    with WidgetsBindingObserver {
  int currentPage = 0;
  int currentNavIndex = 0;
  String? _lastEffectiveArea;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
            'victoria';
        final String effectiveArea =
            serviceArea.toString().split(',')[0].trim();

        if (kDebugMode) {
          print(
              '🏠 ResidentDashboard: Initializing for Area: $effectiveArea (raw: $serviceArea)');
          print('🏠 User Data: $user');
        }
        _lastEffectiveArea = effectiveArea;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _lastEffectiveArea != null) {
      if (kDebugMode) {
        print('🏠 ResidentDashboard: App resumed, refreshing schedules...');
      }
      Provider.of<PickupService>(context, listen: false)
          .loadSchedulesForServiceArea(
        _lastEffectiveArea!,
        forceReload: true,
      );
    }
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
                      icon: Icons.camera_rounded,
                      text: context.tr('scan'),
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
            tooltip: context.tr('bin_location'),
            icon: const Icon(Icons.location_on_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ResidentLocationMapScreen(),
                ),
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
                        // New Reminder and Instructions Cards
                        _buildReminderCard(context, responsive),
                        _buildInstructionsCard(context, responsive),
                        SizedBox(height: responsive.spacing(16)),
                        // Only upcoming collection card is shown to simplify UI
                        _buildUpcomingSection(context, responsive),
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

  Widget _buildUpcomingSection(BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    return Consumer<PickupService>(
      builder: (context, pickupService, _) {
        // Get user's service area
        final auth = Provider.of<AuthService>(context, listen: false);
        final user = auth.user;
        final serviceArea = (user?['barangay'] ?? user?['location'] ?? '')
            .toString()
            .trim();

        if (serviceArea.isEmpty) return const SizedBox.shrink();

        // 1. Get Today's Pickups
        final todayPickups = pickupService.pickupsForDate(DateTime.now());

        // 2. Get Next Upcoming Pickup (if today is empty)
        final nextPickup = pickupService.getNextCollection(serviceArea);

        final bool hasToday = todayPickups.isNotEmpty;
        final bool hasNext = nextPickup != null;

        if (!hasToday && !hasNext) {
          return const SizedBox.shrink();
        }

        final String sectionTitle =
            hasToday ? "TODAY'S SCHEDULE" : "NEXT COLLECTION";
        final List<Map<String, dynamic>> displayItems =
            hasToday ? todayPickups : [nextPickup!];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(4)),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppTheme.textDark.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...displayItems.map((pickup) {
              final date = pickup['date'] as DateTime;
              final isRescheduled = pickup['isRescheduled'] ?? false;
              
              // Standardize Time Formatting: Convert raw '08:00:00' or DateTime to '8:00 AM'
              String formattedTime = '08:00 AM';
              try {
                formattedTime = DateFormat('h:mm a').format(date);
              } catch (e) {
                formattedTime = pickup['time']?.toString() ?? '08:00 AM';
              }

              return ScheduleCard(
                date: DateFormat('EEEE, MMM d').format(date),
                time: formattedTime,
                type: pickup['type']?.toString() ?? 'Waste Collection',
                status: isRescheduled ? 'Rescheduled' : (hasToday ? 'Today' : 'Upcoming'),
                isRescheduled: isRescheduled,
                originalDate: pickup['originalDate'] as DateTime?,
                rescheduledReason: pickup['rescheduledReason']?.toString(),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(BuildContext context, Responsive responsive) {
    // Determine context brightness to adjust colors for dark mode context gracefully
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(16)),
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3F2104) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
            color: isDark
                ? const Color(0xFF9A3412).withOpacity(0.5)
                : const Color(0xFFFFEDD5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF97316), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFDBA74)
                        : const Color(0xFF9A3412),
                    fontSize: 15 * responsive.fontSizeMultiplier,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFED7AA)
                          : const Color(0xFFC2410C),
                      fontSize: 13.5 * responsive.fontSizeMultiplier,
                      height: 1.4,
                      fontFamily:
                          Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    ),
                    children: const [
                      TextSpan(
                          text:
                              'Do not place garbage along the highway unless it is your scheduled collection time.\n'),
                      TextSpan(
                        text:
                            '(Ayaw ibutang ang basura daplin sa karsada gawas kung oras na sa imong naka-schedule nga koleksyon.)',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(BuildContext context, Responsive responsive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(vertical: responsive.spacing(8)),
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.backgroundSecondary.withOpacity(0.4)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.push_pin_rounded,
                  color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15 * responsive.fontSizeMultiplier,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionItem(
              'Place garbage along the highway only during schedule\n(Ibutang ang basura daplin sa karsada sulod lamang sa oras sa eskedyul)',
              responsive,
              context),
          const SizedBox(height: 12),
          _buildInstructionItem(
              'Use sealed bags\n(Paggamit og sirado nga mga bag)',
              responsive,
              context),
          const SizedBox(height: 12),
          _buildInstructionItem(
              'Avoid blocking the road\n(Likayi ang pag-ali sa karsada)',
              responsive,
              context),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
      String text, Responsive responsive, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, left: 2, right: 2),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(
            builder: (context) {
              final parts = text.split('\n');
              final baseStyle = TextStyle(
                fontSize: 13.5 * responsive.fontSizeMultiplier,
                height: 1.4,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.85),
              );

              if (parts.length == 1) {
                return Text(text, style: baseStyle);
              }

              return RichText(
                text: TextSpan(
                  style: baseStyle,
                  children: [
                    TextSpan(text: '${parts[0]}\n'),
                    TextSpan(
                      text: parts.sublist(1).join('\n'),
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
                      SizedBox(height: responsive.spacing(12)),

                      // --- QUICK DEBUG BUTTON REMOVED ---

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
