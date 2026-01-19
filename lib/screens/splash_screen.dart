import 'package:flutter/material.dart';
import 'dart:async';
import '../core/app_theme.dart';
import '../main.dart'; // AuthWrapper access korar jonno eita lagbe

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // 🔴 SOMOOSSA EIKHANE CHILO: direct HomeScreen e jaoa jabe na
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()), 
          // ✅ AuthWrapper e pathate hobe jate se login check korte pare
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.shield_rounded, 
                  color: AppTheme.primaryBlue, 
                  size: 80
                ),
              ),
              const SizedBox(height: 20),

              // 2. Name
              const Text(
                "SafeStep",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),

              // 3. Tagline
              Text(
                "Your Safety, Our Priority",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 50),
              
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}