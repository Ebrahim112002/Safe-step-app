import 'package:flutter/material.dart';
// Removed direct WebView platform registration to avoid analyzer issues.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // (WebView platform registration removed)

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
      // আপনার থিম ফাইলে darkTheme দেওয়া আছে কি না নিশ্চিত করুন
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ফায়ারবেস ডেটা লোড হওয়া পর্যন্ত অপেক্ষা করবে
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ইউজার লগইন করা থাকলে সরাসরি নেভিগেশন বারসহ হোম দেখাবে
        if (snapshot.hasData) {
          return const MainNavigation();
        }

        // লগইন করা না থাকলে লগইন স্ক্রিন দেখাবে
        return const LoginScreen();
      },
    );
  }
}
