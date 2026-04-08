import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/routes/app_routes.dart';
import 'collection_history_screen.dart';
import '../../../widgets/live_scan_screen.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/glassmorphic_container.dart';
import '../../../widgets/animated_button.dart';
import '../../../widgets/staggered_list.dart';
import '../widgets/route_card.dart';
import '../../../core/localization/translations.dart';
import '../../../core/providers/language_provider.dart';

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
  late AnimationController _highlightController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _highlightAnimation;

  String? _highlightedId;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _cardKeys = {};

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
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _highlightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeInOut),
    );

    _headerController.forward();
    _fadeController.forward();

    // Read highlighted ID from route arguments (set when navigating from notification)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['highlightId'] != null) {
        setState(() => _highlightedId = args['highlightId'].toString());
        // Pulse the highlight 3 times then fade
        _highlightController.repeat(reverse: true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _highlightController.stop();
            _highlightController.reverse();
            setState(() => _highlightedId = null);
          }
        });
        // Scroll to the card after list renders
        Future.delayed(const Duration(milliseconds: 600), _scrollToHighlighted);
      }
    });

    _loadSchedules();
  }

  void _scrollToHighlighted() {
    if (_highlightedId == null) return;
    final key = _cardKeys[_highlightedId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      );
    }
  }

  void _loadSchedules() {
    // Load schedules for collector based on assigned area
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final reminderService =
          Provider.of<ReminderService>(context, listen: false);
      reminderService.clearSystemTray();
      final user = authService.user;
      final serviceArea =
          user?['serviceArea'] ?? user?['barangay'] ?? 'victoria';
      Provider.of<PickupService>(context, listen: false)
          .loadSchedulesForServiceArea(serviceArea, isCollector: true);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _highlightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Scaffold(
      appBar: PremiumAppBar(
        title: Text(
          context.tr('collector_dashboard'),
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
                    tooltip: context.tr('notifications'),
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
            tooltip: context.tr('live_scan'),
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
                    isDark ? context.tr('switch_light_mode') : context.tr('switch_dark_mode'),
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
          Consumer<LanguageProvider>(
            builder: (context, lang, _) {
              return IconButton(
                tooltip: lang.isBisaya ? context.tr('switch_to_english') : context.tr('switch_to_bisaya'),
                icon: const Icon(Icons.language, color: AppTheme.textInverse),
                onPressed: () => lang.toggleLanguage(),
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
                                                  .withValues(alpha: 0.1),
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
                                                Consumer<AuthService>(
                                                  builder: (context, auth, _) {
                                                    final hour =
                                                        DateTime.now().hour;
                                                    final enGreeting = hour < 12
                                                        ? 'Good Morning!'
                                                        : hour < 17
                                                            ? 'Good Afternoon!'
                                                            : 'Good Evening!';
                                                    final key = enGreeting.toLowerCase().replaceAll(' ', '_').replaceAll('!', '');
                                                    final cebGreeting = Translations.translateStatic(key, locale: 'ceb');
                                                    
                                                    return Text(
                                                      '$enGreeting ($cebGreeting)',
                                                      style: theme.textTheme
                                                          .headlineSmall
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            AppTheme.textDark,
                                                        fontSize: (theme
                                                                    .textTheme
                                                                    .headlineSmall
                                                                    ?.fontSize ??
                                                                24) *
                                                            responsive
                                                                .fontSizeMultiplier,
                                                        letterSpacing: -0.5,
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 4),
                                                Consumer<AuthService>(
                                                  builder: (context, auth, _) {
                                                    final name = auth.user?[
                                                                'displayName']
                                                            ?.toString() ??
                                                        'Collector';
                                                    return Text(
                                                      '$name · All Zones',
                                                      style: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
                                                        color:
                                                            AppTheme.textLight,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Divider(
                                          color: AppTheme.textDark
                                              .withValues(alpha: 0.05)),
                                      const SizedBox(height: 16),
                                      Text(
                                        context.tr('review_schedules'),
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
                                      context.tr('today'),
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
                                  // Remove global start route button

                                ],
                              ),
                            ),
                            SizedBox(height: responsive.spacing(16)),

                            // Today's Route Cards
                            Consumer2<PickupService, AuthService>(
                              builder:
                                  (context, pickupService, authService, child) {
                                final schedules = pickupService
                                    .pickupsForDate(DateTime.now());
                                final user = authService.user;
                                final areaName = (user?['serviceArea'] ??
                                        user?['barangay'] ??
                                        'your area')
                                    .toString()
                                    .split(' ')
                                    .map((w) => w.isEmpty
                                        ? w
                                        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
                                    .join(' ');

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
                                            context.tr('no_collection_today'),
                                            style: TextStyle(
                                              color: AppTheme.textLight,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14 *
                                                  responsive.fontSizeMultiplier,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${context.tr('zone')}: $areaName',
                                            style: TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 12 *
                                                  responsive.fontSizeMultiplier,
                                              fontWeight: FontWeight.w500,
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
                                    final date = schedule['date'] as DateTime;
                                    final dateStr =
                                        "${date.month}/${date.day}/${date.year}";
                                    return BounceInAnimation(
                                      child: RouteCard(
                                        routeName: (schedule['isSpecial'] == true && schedule['residentName'] != null)
                                            ? _capitalizeWords(schedule['residentName'].toString())
                                            : (schedule['isSpecial'] == true 
                                                ? schedule['type'] 
                                                : _capitalizeWords((schedule['address'] ?? 'Unknown Area').toString())),
                                        stops: 15,
                                        estimatedTime:
                                            "$dateStr · ${schedule['time'] ?? '08:00'}",
                                        status: status,
                                        barangay:
                                            _capitalizeWords(schedule['address']?.toString() ?? ''),
                                        isRescheduled:
                                            schedule['isRescheduled'] == true,
                                        isSpecial:
                                            schedule['isSpecial'] == true,
                                        originalDate: schedule['originalDate']
                                            as DateTime?,
                                        rescheduledReason:
                                            schedule['rescheduledReason']
                                                ?.toString(),
                                        residentName:
                                            schedule['residentName']?.toString(),
                                        pickupLocation:
                                            schedule['pickupLocation']?.toString(),
                                        purok: schedule['purok']?.toString(),
                                        street: schedule['street']?.toString(),
                                        residentBarangay:
                                            schedule['residentBarangay']?.toString(),
                                        residentAge: schedule['residentAge']?.toString(),
                                        wasteType: schedule['wasteType']?.toString(),
                                        estimatedQuantity: schedule['estimatedQuantity']?.toString(),
                                        specialInstructions: _extractMessage(schedule),
                                        onTap: () {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Schedule for ${schedule['address']} on $dateStr at ${schedule['time']}'),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        onAction: (status.toLowerCase() == 'scheduled') 
                                            ? () => _handleStartRoute(schedule) 
                                            : null,
                                        actionLabel: (status.toLowerCase() == 'scheduled') 
                                            ? context.tr('start_route') 
                                            : 'Route Started',
                                        actionIcon: Icons.play_arrow_rounded,
                                        onSecondaryAction: null,
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
                                context.tr('upcoming'),
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
                                        routeName: (schedule['isSpecial'] == true && schedule['residentName'] != null)
                                            ? _capitalizeWords(schedule['residentName'].toString())
                                            : (schedule['isSpecial'] == true 
                                                ? schedule['type'] 
                                                : _capitalizeWords((schedule['address'] ?? 'Unknown Area').toString())),
                                        stops: 15,
                                        estimatedTime:
                                            "$dateStr · ${schedule['time'] ?? '08:00'}",
                                        status: schedule['status'],
                                        barangay:
                                            _capitalizeWords(schedule['address']?.toString() ?? ''),
                                        isRescheduled:
                                            schedule['isRescheduled'] == true,
                                        isSpecial:
                                            schedule['isSpecial'] == true,
                                        originalDate: schedule['originalDate']
                                            as DateTime?,
                                        rescheduledReason:
                                            schedule['rescheduledReason']
                                                ?.toString(),
                                        residentName:
                                            schedule['residentName']?.toString(),
                                        pickupLocation:
                                            schedule['pickupLocation']?.toString(),
                                        purok: schedule['purok']?.toString(),
                                        street: schedule['street']?.toString(),
                                        residentBarangay:
                                            schedule['residentBarangay']?.toString(),
                                        residentAge: schedule['residentAge']?.toString(),
                                        wasteType: schedule['wasteType']?.toString(),
                                        estimatedQuantity: schedule['estimatedQuantity']?.toString(),
                                        specialInstructions: _extractMessage(schedule),
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
                                        onSecondaryAction: null,
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
                                        text: context.tr('history'),
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
                                          text: context.tr('history'),
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

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
  }

  /// Extracts the resident's message from the schedule map.
  /// Checks the direct 'specialInstructions' field first, then
  /// falls back to parsing 'Message: ...' from the 'locationNote' string
  /// (which is how the admin JS embeds it inside collection_schedules).
  String? _extractMessage(Map<String, dynamic> schedule) {
    final direct = schedule['specialInstructions']?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final note = schedule['locationNote']?.toString() ?? '';
    if (note.isEmpty) return null;

    final msgRegex = RegExp(r'(?:Message|Notes|Instructions):\s*([^\n,]*)',
        caseSensitive: false);
    final match = msgRegex.firstMatch(note);
    if (match != null) {
      final extracted = match.group(1)?.trim() ?? '';
      if (extracted.isNotEmpty) return extracted;
    }
    return null;
  }

  /// Handles starting a route for a specific schedule/barangay.
  /// Sends notifications and updates status to 'on_the_way'.
  Future<void> _handleStartRoute(Map<String, dynamic> schedule) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pickupService = Provider.of<PickupService>(context, listen: false);
    
    final user = authService.user;
    final collectorName = user?['displayName']?.toString() ?? 'Collector';
    final zone = schedule['address']?.toString() ?? 'Assigned Area';
    final scheduleId = schedule['id'].toString();

    // 1. Send notifications for this specific zone
    await pickupService.notifyCollectorStarted(collectorName, zone);

    // 2. Update the specific schedule status
    await pickupService.updateScheduleStatus(scheduleId, 'on_the_way');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting route for $zone. Residents have been notified!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }
}
