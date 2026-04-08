import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transitions/nature_transitions.dart';
import '../services/auth_service.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/role_selection/role_selection_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/landing_page_screen.dart';
import '../../features/resident/screens/resident_dashboard_screen.dart';
import '../../features/resident/screens/resident_location_selection_screen.dart';
import '../../features/resident/screens/resident_location_map_screen.dart';
import '../../features/resident/screens/notification_center_screen.dart';
import '../../features/resident/screens/feedback_screen.dart';
import '../../features/common/screens/profile_screen.dart';
import '../../features/common/screens/settings_screen.dart';
import '../../features/resident/screens/welcome_animation_screen.dart';
import '../../features/resident/screens/resident_registration_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String roleSelection = '/role';
  static const String auth = '/auth';
  static const String residentDashboard = '/resident';
  static const String residentLocationSelection = '/resident/location';
  static const String residentLocationMap = '/resident/location-map';
  static const String schedulePickup = '/resident/schedule';
  static const String residentNotifications = '/resident/notifications';
  static const String residentFeedback = '/resident/feedback';
  static const String compostPitFinder = '/resident/compost-pits';
  static const String residentCollectionHistory = '/resident/history';
  static const String ecoTips = '/resident/eco-tips';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String welcomeAnimation = '/welcome-animation';
  static const String residentRegistration = '/resident/registration';
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
      case AppRoutes.residentDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialNavIndex = args?['initialNavIndex'] as int? ?? 0;
        return ResidentDashboardScreen(initialNavIndex: initialNavIndex);
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
      case AppRoutes.residentRegistration:
        final barangay = settings.arguments as String? ?? 'Victoria';
        return ResidentRegistrationScreen(barangay: barangay);
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
        // By default send to landing, not splash, to prevent infinite re-initialization loops.
        return const LandingPageScreen();
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
    // Check if resident has location selected
    if (auth.hasBarangaySelected) {
      Navigator.of(this).pushNamedAndRemoveUntil(
          AppRoutes.residentDashboard, (route) => false);
    } else {
      Navigator.of(this).pushNamedAndRemoveUntil(
          AppRoutes.residentLocationSelection, (route) => false);
    }
  }
}

