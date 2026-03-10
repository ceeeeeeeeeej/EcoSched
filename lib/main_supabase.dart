import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_state_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/pickup_service.dart';
import 'core/error/error_handler.dart';
import 'core/routes/app_router.dart';
import 'core/services/feedback_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/special_collection_service.dart';
import 'core/services/reminder_service.dart';
import 'core/services/background_service.dart';
import 'core/config/supabase_config.dart';

void main() async {
  if (kDebugMode) print('🚀 FLASH (Supabase): main() started');
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) print('🚀 FLASH (Supabase): WidgetsBinding initialized');

  // Initialize Supabase with a timeout
  try {
    if (kDebugMode) print('🚀 FLASH (Supabase): Initializing Supabase...');
    await SupabaseConfig.initialize().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          print('🚀 FLASH (Supabase): Supabase initialization TIMEOUT');
        }
      },
    );
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Supabase initialization attempt finished');
    }
  } catch (e) {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Error initializing Supabase: $e');
    }
  }

  // Initialize notifications with a timeout
  try {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Initializing NotificationService...');
    }
    await NotificationService.initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          print(
              '🚀 FLASH (Supabase): NotificationService initialization TIMEOUT');
        }
      },
    );
    if (kDebugMode) {
      print(
          '🚀 FLASH (Supabase): NotificationService initialization attempt finished');
    }
  } catch (e) {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Error initializing NotificationService: $e');
    }
  }

  // Initialize background service with a timeout
  try {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Initializing BackgroundService...');
    }
    await BackgroundService.initializeService().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          print(
              '🚀 FLASH (Supabase): BackgroundService initialization TIMEOUT');
        }
      },
    );
    if (kDebugMode) {
      print(
          '🚀 FLASH (Supabase): BackgroundService initialization attempt finished');
    }
  } catch (e) {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Error initializing BackgroundService: $e');
    }
  }

  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      print('🚀 FLASH (Supabase): Caught Flutter Error: ${details.exception}');
    }
    ErrorHandler.handleError(
      details.exception,
      details.stack,
      context: 'Flutter Error',
    );
  };

  if (kDebugMode) print('🚀 FLASH (Supabase): Calling runApp()...');
  runApp(const EcoSchedApp());
  if (kDebugMode) print('🚀 FLASH (Supabase): runApp() called');
}

class EcoSchedApp extends StatelessWidget {
  const EcoSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PickupService()),
        ChangeNotifierProvider(create: (_) => FeedbackService()),
        ChangeNotifierProvider(create: (_) => SpecialCollectionService()),
        ChangeNotifierProxyProvider2<AuthService, PickupService,
            ReminderService>(
          create: (_) => ReminderService()..initialize(),
          update: (_, auth, pickupService, reminderService) {
            final service =
                reminderService ?? (ReminderService()..initialize());
            service.updateDependencies(
              authService: auth,
              pickupService: pickupService,
            );
            return service;
          },
        ),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'EcoSched',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            navigatorKey: AppRouter.navigatorKey,
            navigatorObservers: [AppRouter.routeObserver],
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    MediaQuery.of(context)
                        .textScaler
                        .scale(1.0)
                        .clamp(0.8, 1.2),
                  ),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
