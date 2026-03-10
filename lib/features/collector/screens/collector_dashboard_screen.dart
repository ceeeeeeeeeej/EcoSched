import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/staggered_list.dart';
import '../widgets/route_card.dart';
import 'collection_history_screen.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/main_drawer.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../core/providers/app_state_provider.dart';
import '../../../core/services/pickup_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/reminder_service.dart';
// import for re-using providers if needed, or just standard import

class CollectorDashboardScreen extends StatefulWidget {
  const CollectorDashboardScreen({super.key});

  @override
  State<CollectorDashboardScreen> createState() =>
      _CollectorDashboardScreenState();
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

    // Load schedules for collector based on assigned area
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      // Default to 'victoria' if no area assigned (fallback for legacy users)
      final serviceArea =
          user?['serviceArea'] ?? user?['barangay'] ?? 'victoria';

      print('Collector Dashboard: Loading schedules for area: $serviceArea');
      Provider.of<PickupService>(context, listen: false)
          .loadSchedulesForServiceArea(serviceArea, isCollector: true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Scaffold(
      drawer: const MainDrawer(),
      appBar: PremiumAppBar(
        title: Text(
          'Collector Dashboard',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppTheme.textInverse,
            fontWeight: FontWeight.w700,
            fontSize: 18 * responsive.fontSizeMultiplier,
          ),
        ),
        actions: [
          Consumer<ReminderService>(
            builder: (context, reminderService, _) {
              final unreadCount = reminderService.unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      size: responsive.iconSize(24),
                      color: AppTheme.textInverse,
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.pushNamed(
                          context, AppRoutes.residentNotifications);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.camera_alt_rounded,
              size: responsive.iconSize(24),
              color: AppTheme.textInverse,
            ),
            tooltip: 'Live Scan',
            onPressed: () {
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
          Consumer<AppStateProvider>(
            builder: (context, appState, _) {
              final bool isDark =
                  Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                tooltip:
                    isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: responsive.iconSize(22),
                  color: AppTheme.textInverse,
                ),
                onPressed: () {
                  appState.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
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
                return RefreshIndicator(
                  onRefresh: () async {
                    // Re-load logic
                    final authService =
                        Provider.of<AuthService>(context, listen: false);
                    final user = authService.user;
                    final serviceArea =
                        user?['serviceArea'] ?? user?['barangay'] ?? 'victoria';
                    await Provider.of<PickupService>(context, listen: false)
                        .loadSchedulesForServiceArea(serviceArea,
                            isCollector: true, forceReload: true);
                  },
                  child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            // Welcome Section - Modernized
                            SlideTransition(
                              position: _headerSlideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: GlassmorphicContainer(
                                  width: double.infinity,
                                  padding:
                                      EdgeInsets.all(responsive.spacing(24)),
                                  borderRadius: AppTheme.radiusXL,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.person_outline_rounded,
                                              color: AppTheme.primary,
                                              size: responsive.iconSize(24),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Morning!',
                                                  style: theme
                                                      .textTheme.headlineSmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: AppTheme.textDark,
                                                    fontSize: (theme
                                                                .textTheme
                                                                .headlineSmall
                                                                ?.fontSize ??
                                                            24) *
                                                        responsive
                                                            .fontSizeMultiplier,
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Station · Area Victoria',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: AppTheme.textLight,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Divider(
                                          color: AppTheme.textDark
                                              .withOpacity(0.05)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Review schedules & follow safety protocols.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: AppTheme.textLight,
                                          height: 1.6,
                                          fontSize: (theme.textTheme.bodyMedium
                                                      ?.fontSize ??
                                                  14) *
                                              responsive.fontSizeMultiplier,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(24)),

                            // Today's Schedules Section
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Today',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textDark,
                                            fontSize: (Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.fontSize ??
                                                    20) *
                                                responsive.fontSizeMultiplier,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: responsive.spacing(16)),

                            // Today's Route Cards
                            Consumer<PickupService>(
                              builder: (context, pickupService, child) {
                                final schedules = pickupService
                                    .pickupsForDate(DateTime.now());

                                if (schedules.isEmpty) {
                                  return GlassmorphicContainer(
                                    width: double.infinity,
                                    padding:
                                        EdgeInsets.all(responsive.spacing(24)),
                                    borderRadius: AppTheme.radiusXL,
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(Icons.calendar_today_outlined,
                                              color: AppTheme.textLight,
                                              size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No active schedules for today.',
                                            style: TextStyle(
                                              color: AppTheme.textLight,
                                              fontSize: 14 *
                                                  responsive.fontSizeMultiplier,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return StaggeredList(
                                  children: schedules.map((schedule) {
                                    final status = schedule['status'] as String;
                                    final isScheduled = status == 'Scheduled';

                                    return BounceInAnimation(
                                      child: RouteCard(
                                        routeName: schedule['address'] ??
                                            'Unknown Area',
                                        stops: 15,
                                        estimatedTime:
                                            schedule['time'] ?? '08:00',
                                        status: status,
                                        isRescheduled:
                                            schedule['isRescheduled'] == true,
                                        originalDate: schedule['originalDate']
                                            as DateTime?,
                                        rescheduledReason:
                                            schedule['rescheduledReason']
                                                ?.toString(),
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Schedule for ${schedule['address']} at ${schedule['time']}'),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        actionLabel: isScheduled
                                            ? 'Start Collection'
                                            : (status == 'on_the_way'
                                                ? 'Complete Collection'
                                                : null),
                                        actionIcon: isScheduled
                                            ? Icons.play_arrow
                                            : Icons.check,
                                        onAction: (isScheduled ||
                                                status == 'on_the_way')
                                            ? () async {
                                                final newStatus = isScheduled
                                                    ? 'on_the_way'
                                                    : 'Completed';
                                                await pickupService
                                                    .updateScheduleStatus(
                                                        schedule['id'],
                                                        newStatus);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Status updated to $newStatus')),
                                                  );
                                                }
                                              }
                                            : null,
                                        onSecondaryAction: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Reschedule request sent to Admin.')),
                                          );
                                        },
                                        secondaryActionLabel: 'Reschedule',
                                        secondaryActionIcon: Icons.update,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            SizedBox(height: responsive.spacing(32)),

                            // Upcoming Schedules Section
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Upcoming',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                      fontSize: (Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.fontSize ??
                                              20) *
                                          responsive.fontSizeMultiplier,
                                    ),
                              ),
                            ),
                            SizedBox(height: responsive.spacing(16)),

                            Consumer<PickupService>(
                              builder: (context, pickupService, child) {
                                final upcoming = pickupService.upcomingPickups;

                                if (upcoming.isEmpty) {
                                  return GlassmorphicContainer(
                                    width: double.infinity,
                                    padding:
                                        EdgeInsets.all(responsive.spacing(24)),
                                    borderRadius: AppTheme.radiusXL,
                                    child: Center(
                                      child: Text(
                                        'No upcoming schedules found.',
                                        style: TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 14 *
                                              responsive.fontSizeMultiplier,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return StaggeredList(
                                  children: upcoming.map((schedule) {
                                    final date = schedule['date'] as DateTime;
                                    final dateStr =
                                        "${date.month}/${date.day}/${date.year}";

                                    return BounceInAnimation(
                                      child: RouteCard(
                                        routeName: schedule['address'] ??
                                            'Unknown Area',
                                        stops: 15,
                                        estimatedTime:
                                            "$dateStr · ${schedule['time'] ?? '08:00'}",
                                        status: schedule['status'],
                                        isRescheduled:
                                            schedule['isRescheduled'] == true,
                                        originalDate: schedule['originalDate']
                                            as DateTime?,
                                        rescheduledReason:
                                            schedule['rescheduledReason']
                                                ?.toString(),
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Upcoming: ${schedule['address']} on $dateStr'),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        onSecondaryAction: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Reschedule request sent to Admin.')),
                                          );
                                        },
                                        secondaryActionLabel: 'Reschedule',
                                        secondaryActionIcon: Icons.update,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                            SizedBox(height: responsive.spacing(32)),

                            // Action Buttons - Responsive layout
                            responsive.isMobile
                                ? Column(
                                    children: [
                                      AnimatedButton(
                                        text: 'History',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CollectionHistoryScreen(),
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
                                          text: 'History',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const CollectionHistoryScreen(),
                                              ),
                                            );
                                          },
                                          backgroundColor:
                                              AppTheme.accentOrange,
                                          icon: Icons.history,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      )),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
