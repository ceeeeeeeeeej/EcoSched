import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transitions/nature_transitions.dart';
import '../services/auth_service.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/role_selection/role_selection_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/landing_page_screen.dart';
import '../../features/collector/screens/collector_login.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../widgets/enhanced_nature_background.dart';
import '../utils/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../features/resident/screens/resident_dashboard_screen.dart';
import '../../features/resident/screens/resident_location_selection_screen.dart';
import '../../features/resident/screens/resident_location_map_screen.dart';
import '../../features/resident/screens/notification_center_screen.dart';
import '../../features/resident/screens/feedback_screen.dart';
import '../../features/collector/screens/collector_dashboard_screen.dart';
import '../../features/common/screens/profile_screen.dart';
import '../../features/common/screens/settings_screen.dart';
import '../../features/resident/screens/welcome_animation_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String roleSelection = '/role';
  static const String auth = '/auth';
  static const String collectorLogin = '/collector/login';
  static const String residentDashboard = '/resident';
  static const String residentLocationSelection = '/resident/location';
  static const String residentLocationMap = '/resident/location-map';
  static const String schedulePickup = '/resident/schedule';
  static const String residentNotifications = '/resident/notifications';
  static const String residentFeedback = '/resident/feedback';
  static const String compostPitFinder = '/resident/compost-pits';
  static const String residentCollectionHistory = '/resident/history';
  static const String ecoTips = '/resident/eco-tips';
  static const String collectorDashboard = '/collector';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String welcomeAnimation = '/welcome-animation';
}

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = _buildPage(settings);
    return NaturePageRoute(
      child: page,
      transitionType: NatureTransitionType.slideFromRight,
      duration: const Duration(milliseconds: 350),
    );
  }

  static Widget _buildPage(RouteSettings settings) {
    final BuildContext? context = navigatorKey.currentContext;
    final String? name = settings.name;
    final auth = context != null
        ? Provider.of<AuthService>(context, listen: false)
        : null;

    switch (name) {
      case AppRoutes.splash:
        return const SplashScreen();
      case AppRoutes.landing:
        return const LandingPageScreen();
      case AppRoutes.roleSelection:
        return const RoleSelectionScreen();
      case AppRoutes.auth:
        return const AuthScreen();
      case AppRoutes.collectorLogin:
        return const _CollectorLoginWrapper();
      case AppRoutes.residentDashboard:
        // Allow residents without authentication check
        if (auth != null && auth.isCollector()) {
          return const CollectorDashboardScreen();
        }
        return const ResidentDashboardScreen();
      case AppRoutes.residentLocationSelection:
        final selectedBarangay = settings.arguments as String?;
        return ResidentLocationSelectionScreen(
            selectedBarangay: selectedBarangay);
      case AppRoutes.residentLocationMap:
        final args = settings.arguments as Map<String, dynamic>?;
        final barangay = args?['barangay'] as String?;
        final purok = args?['purok'] as String?;
        final currentLocation = args?['currentLocation'] as String?;
        return ResidentLocationMapScreen(
          barangay: barangay,
          purok: purok,
          currentLocation: currentLocation,
        );
      case AppRoutes.welcomeAnimation:
        final barangay = settings.arguments as String? ?? 'Victoria';
        return WelcomeAnimationScreen(barangay: barangay);
      case AppRoutes.schedulePickup:
      //   // Allow residents without authentication check
      //   return const SchedulePickupScreen();
      // case AppRoutes.residentCollectionHistory:
      //   return const ResidentCollectionHistoryScreen();
      case AppRoutes.residentNotifications:
        // Allow residents without authentication check
        return const NotificationCenterScreen();
      case AppRoutes.residentFeedback:
        // Allow residents without authentication check
        return const FeedbackScreen();
      // case AppRoutes.compostPitFinder:
      //   // Allow residents without authentication check
      //   return const CompostPitFinderScreen();
      case AppRoutes.collectorDashboard:
        if (auth != null && auth.isAuthenticated && auth.isCollector()) {
          return const CollectorDashboardScreen();
        }
        return const AuthScreen();
      case AppRoutes.profile:
        if (auth != null && auth.isAuthenticated) {
          return const ProfileScreen();
        }
        return const AuthScreen();
      case AppRoutes.settings:
        if (auth != null && auth.isAuthenticated) {
          return const SettingsScreen();
        }
        return const AuthScreen();
      default:
        return const SplashScreen();
    }
  }
}

extension NavigationExtensions on BuildContext {
  Future<T?> pushRoute<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> replaceWith<T>(String routeName, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed<T, T>(routeName, arguments: arguments);
  }

  void goHomeForRole() {
    final auth = read<AuthService>();
    if (auth.isCollector()) {
      Navigator.of(this).pushNamedAndRemoveUntil(
          AppRoutes.collectorDashboard, (route) => false);
    } else {
      Navigator.of(this).pushNamedAndRemoveUntil(
          AppRoutes.residentDashboard, (route) => false);
    }
  }
}

// Collector Login Wrapper Widget
class _CollectorLoginWrapper extends StatefulWidget {
  const _CollectorLoginWrapper();

  @override
  State<_CollectorLoginWrapper> createState() => _CollectorLoginWrapperState();
}

class _CollectorLoginWrapperState extends State<_CollectorLoginWrapper>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Scaffold(
      body: EnhancedNatureBackground(
        showPattern: true,
        child: SafeArea(
          child: Column(
            children: [
              // Navigation Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding / 2,
                  vertical: responsive.spacing(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: AppTheme.textDark,
                      tooltip: 'Back to Role Selection',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalPadding,
                      vertical: responsive.spacing(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Collector Icon with enhanced styling
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                NatureHeroAnimation(
                                  tag: 'collector_login_icon',
                                  child: Container(
                                    width: responsive.isMobile ? 100 : 120,
                                    height: responsive.isMobile ? 100 : 120,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: AppTheme.primaryGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withOpacity(0.35),
                                          blurRadius: 25,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.local_shipping_rounded,
                                      size: responsive.isMobile ? 50 : 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Collector Login',
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                    fontSize: (theme.textTheme.headlineMedium
                                                ?.fontSize ??
                                            32) *
                                        responsive.fontSizeMultiplier,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sign in to manage your collection routes and community schedule.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppTheme.textLight,
                                    fontSize:
                                        (theme.textTheme.bodyLarge?.fontSize ??
                                                16) *
                                            responsive.fontSizeMultiplier,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Login Form Container
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: responsive.getContainerWidth(
                                  mobilePercent: 1.0,
                                  tabletPercent: 0.7,
                                  desktopPercent: 0.5,
                                  maxWidth: 450,
                                ),
                              ),
                              child: GlassmorphicContainer(
                                width: double.infinity,
                                padding: EdgeInsets.all(responsive.spacing(24)),
                                borderRadius: AppTheme.radiusXL,
                                child: LoginScreen(
                                  onToggleMode: () {},
                                  isCollectorLogin: true,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: responsive.spacing(40)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
