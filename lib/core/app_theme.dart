import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1A237E); // Trust & Safety
  static const Color sosRed = Color(0xFFD32F2F);      // Emergency Red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue, secondary: sosRed),
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
  }
}