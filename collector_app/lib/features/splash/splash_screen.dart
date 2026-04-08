import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:collector_app/core/services/auth_service.dart';
import 'package:collector_app/core/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _logoScale;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('🚀 FLASH: Collector SplashScreen.initState');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);

      // Check for existing session
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    void tryNavigate() {
      if (!mounted) return;

      if (auth.isAuthCheckComplete) {
        if (auth.isAuthenticated && auth.isCollector()) {
          if (kDebugMode) print('🚀 FLASH: Collector session found, auto-navigating...');
          Navigator.of(context).pushReplacementNamed(AppRoutes.collectorDashboard);
        } else {
          if (kDebugMode) print('🚀 FLASH: No active session, going to Login.');
          Navigator.of(context).pushReplacementNamed(AppRoutes.collectorLogin);
        }
      }
    }

    if (auth.isAuthCheckComplete) {
      // Short delay for the animation to be seen
      await Future.delayed(const Duration(milliseconds: 1500));
      tryNavigate();
    } else {
      void listener() {
        if (auth.isAuthCheckComplete) {
          auth.removeListener(listener);
          tryNavigate();
        }
      }
      auth.addListener(listener);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _entered ? 1.0 : 0.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'EcoSched Collector',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
