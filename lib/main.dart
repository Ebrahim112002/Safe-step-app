import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  // ১. ফ্লাটার ইঞ্জিন ইনিশিয়ালাইজেশন
  WidgetsFlutterBinding.ensureInitialized();

  // ২. ফায়ারবেস ম্যানুয়াল কনফিগারেশন (আপনার দেওয়া ডাটা অনুযায়ী)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // আপনার Project ID এবং Project Number ব্যবহার করা হয়েছে
      apiKey: "AIzaSyA-আপনার-কনসোল-থেকে-সংগ্রহ-করুন", // এটি পেতে নিচে দ্রষ্টব্য
      appId: "1:878163418286:android:আপনার-অ্যাপ-আইডি", // আপনার প্রজেক্ট নম্বর সহ
      messagingSenderId: "878163418286", 
      projectId: "safe-step-cf39f",
      storageBucket: "safe-step-cf39f.appspot.com",
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