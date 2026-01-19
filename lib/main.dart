import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart'; // SplashScreen import koro

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://zrpaydgzspdqsbarzqyj.supabase.co',
      anonKey: 'sb_publishable_t2suX6M-qQnxdXiLxnD_CA_ONJBm9Ok',
      debug: false,
    );
  } catch (e) {
    debugPrint('Supabase init error ignored: $e');
  }

  runApp(const SafeStepApp());
}

class SafeStepApp extends StatelessWidget {
  const SafeStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeStep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        };
        return widget!;
      },
      // App ekhon SplashScreen theke shuru hobe
      home: const SplashScreen(),
    );
  }
}

// AuthWrapper decide korbe SplashScreen er por koi jabe
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Session check logic
    final session = Supabase.instance.client.auth.currentSession;

    // Jodi user age login kora na thake (session null), tobe login e pathao
    if (session == null) {
      return const LoginScreen();
    } else {
      // User login kora thakle direct Main Home e pathao
      return const MainNavigation();
    }
  }
}