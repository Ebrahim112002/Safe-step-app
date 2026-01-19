import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  // Error gulo console e hide korar jonno
  WidgetsFlutterBinding.ensureInitialized();

  // Web assertion error bondho korar jonno ei try-catch block
  try {
    await Supabase.initialize(
      url: 'https://zrpaydgzspdqsbarzqyj.supabase.co',
      anonKey: 'sb_publishable_t2suX6M-qQnxdXiLxnD_CA_ONJBm9Ok',
      debug: false, // Faltu debug logs bondho hobe
    );
  } catch (e) {
    // Initialization fail holeo jeno crash na kore
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
      // Error widget ta customize kora jate screen e laal error na dekhay
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        };
        return widget!;
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Ekhane null check kora hoyeche jate session load na holeo error na mare
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session != null ? const MainNavigation() : const LoginScreen();
    } catch (e) {
      return const LoginScreen();
    }
  }
}