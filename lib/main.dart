import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ফায়ারবেস কোর
import 'core/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  // ১. ফ্লাটার ইঞ্জিন নিশ্চিত করা
  WidgetsFlutterBinding.ensureInitialized();

  // ২. ফায়ারবেস আপনার কনফিগারেশন দিয়ে শুরু করা
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBzNzO8hu18xsGwSW40Y4DKOlRJHjLltU4",
      authDomain: "safe-step-cf39f.firebaseapp.com",
      projectId: "safe-step-cf39f",
      storageBucket: "safe-step-cf39f.firebasestorage.app",
      messagingSenderId: "878163418286",
      appId: "1:878163418286:web:3d3e33748e07569cd4a13f",
    ),
  );

  runApp(const SafeStepApp());
}

class SafeStepApp extends StatelessWidget {
  const SafeStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeStep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}