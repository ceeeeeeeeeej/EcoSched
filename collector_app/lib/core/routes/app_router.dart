import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collector_app/core/transitions/nature_transitions.dart';
import 'package:collector_app/core/services/auth_service.dart';
import 'package:collector_app/core/theme/app_theme.dart';
import 'package:collector_app/core/utils/responsive.dart';
import 'package:collector_app/core/routes/app_routes.dart';
import 'package:collector_app/features/splash/splash_screen.dart';
import 'package:collector_app/features/collector/screens/collector_login.dart';
import 'package:collector_app/features/collector/screens/collector_dashboard_screen.dart';
import 'package:collector_app/features/collector/screens/collector_notifications_screen.dart';
import 'package:collector_app/widgets/enhanced_nature_background.dart';
import 'package:collector_app/widgets/glassmorphic_container.dart';

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
    final String? name = settings.name;

    switch (name) {
      case AppRoutes.splash:
        return const SplashScreen();
      case AppRoutes.collectorLogin:
        return const _CollectorLoginWrapper();
      case AppRoutes.collectorDashboard:
        return const CollectorDashboardScreen();
      case AppRoutes.residentNotifications:
        return const CollectorNotificationsScreen();
      case AppRoutes.residentDashboard:
        return const _AccessDeniedScreen();
      default:
        return const _CollectorLoginWrapper(); // Default to login
    }
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'This application is reserved for Waste Collectors and Administrators. Your account does not have the required permissions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => auth.signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Sign Out & Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
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
                                      gradient: const LinearGradient(
                                        colors: AppTheme.primaryGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.35),
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
