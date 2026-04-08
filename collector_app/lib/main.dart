import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:collector_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/pickup_service.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/services/feedback_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/special_collection_service.dart';
import 'core/services/reminder_service.dart';
import 'core/services/bin_service.dart';
import 'core/services/background_service.dart';
import 'core/config/supabase_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
  
  // Explicitly show notification if it has a body
  if (message.notification != null) {
    NotificationService.showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? "EcoSched Alert",
      body: message.notification?.body ?? "New update received",
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint('🚀 FLASH: Starting Collector App Boot...');

  // 2. Call runApp IMMEDIATELY. Do not await anything.
  runApp(const UltraSafeBoot());
}

class UltraSafeBoot extends StatefulWidget {
  const UltraSafeBoot({super.key});

  @override
  State<UltraSafeBoot> createState() => _UltraSafeBootState();
}

class _UltraSafeBootState extends State<UltraSafeBoot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    debugPrint('🚀 FLASH: Internal initialization started...');
    try {
      // Small delay to ensure the first frame is actually visible to the user
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🚀 FLASH: Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
        
        // Setup FCM Click Listeners
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('🔔 FCM: App opened from background notification: ${message.messageId}');
          NotificationService.handleFcmClick(message);
        });

        // 🚨 Foreground Message Listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('🔔 FCM: Foreground message received: ${message.messageId}');
          if (message.notification != null) {
            NotificationService.showNotification(
              id: message.hashCode,
              title: message.notification?.title ?? "EcoSched Alert",
              body: message.notification?.body ?? "New update received",
            );
          }
        });

        // Check if app was opened from a terminated state via notification
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('🔔 FCM: App launched from terminated notification: ${initialMessage.messageId}');
          // Note: NotificationService might not be fully initialized yet, 
          // but we can schedule this or handle it in SplashScreen.
          // Store it in AppState or similar.
          NotificationService.setLaunchedFromMessage(initialMessage);
        }
      } catch (e) {
        debugPrint('⚠️ Firebase init error (possibly already init or missing options): $e');
      }


      debugPrint('🚀 FLASH: Connecting to Supabase...');
      await SupabaseConfig.initialize().timeout(const Duration(seconds: 8));

      debugPrint('🚀 FLASH: Setting up Notifications...');
      await NotificationService.initialize()
          .timeout(const Duration(seconds: 4));

      debugPrint('🚀 FLASH: Starting Background Service...');
      await BackgroundService.initializeService()
          .timeout(const Duration(seconds: 5));

      debugPrint('🚀 FLASH: All systems green.');
    } catch (e) {
      debugPrint('🚀 FLASH: Non-fatal error during boot: $e');
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // This is the absolute first thing the engine will draw.
      // It should replace the Flutter logo immediately.
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.blue.shade700,
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'EcoSched Collector Booting...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const CollectorApp();
  }
}

class CollectorApp extends StatelessWidget {
  const CollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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
            title: 'EcoSched Collector',
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
