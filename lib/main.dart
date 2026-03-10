import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/app_state_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/pickup_service.dart';
import 'core/routes/app_router.dart';
import 'core/services/feedback_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/special_collection_service.dart';
import 'core/services/reminder_service.dart';
import 'core/services/bin_service.dart';
import 'core/services/background_service.dart';
import 'core/config/supabase_config.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 FLASH: Starting Ultra-Safe Boot...');

  runApp(const UltraSafeBoot());
}

class UltraSafeBoot extends StatefulWidget {
  const UltraSafeBoot({super.key});

  @override
  State<UltraSafeBoot> createState() => _UltraSafeBootState();
}

class _UltraSafeBootState extends State<UltraSafeBoot> {
  bool _ready = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    debugPrint('🚀 FLASH: Internal initialization started...');

    try {
      /// 1️⃣ Initialize Firebase (REQUIRED FOR PUSH NOTIFICATIONS)
      debugPrint('🚀 FLASH: Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      /// Small delay so splash screen appears smoothly
      await Future.delayed(const Duration(milliseconds: 500));

      /// 2️⃣ Initialize Supabase
      debugPrint('🚀 FLASH: Connecting to Supabase...');
      await SupabaseConfig.initialize().timeout(const Duration(seconds: 8));

      /// 2.5️⃣ Register FCM Token on boot
      await PushNotificationService.registerDeviceForPush();

      /// 3️⃣ Initialize Notification Service
      debugPrint('🚀 FLASH: Setting up Notifications...');
      await NotificationService.initialize()
          .timeout(const Duration(seconds: 4));

      /// 4️⃣ Start Background Service
      debugPrint('🚀 FLASH: Starting Background Service...');
      await BackgroundService.initializeService()
          .timeout(const Duration(seconds: 5));

      debugPrint('🚀 FLASH: All systems green.');

      if (mounted) {
        setState(() {
          _ready = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('🚀 FLASH: CRITICAL error during boot: $e');

      if (mounted) {
        setState(() {
          _ready = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: const Color(0xFF1B5E20),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 64),
                  const SizedBox(height: 32),
                  if (_errorMessage == null) ...[
                    const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'EcoSched Booting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Boot Failure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                        _init();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade900,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const EcoSchedApp();
  }
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
        ChangeNotifierProvider(create: (_) => BinService()),
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
