import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBg = Color(0xFF0A0E21); // Dark Navy Background
  static const Color cardColor = Color(0xFF1D1E33); // Card Background
  static const Color primaryBlue = Color(0xFF4C86FF);
  static const Color emergencyRed = Color(0xFFFF4B4B);
  static const Color accentPurple = Color(0xFF915FB5);

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryBlue,
    cardColor: cardColor,
    appBarTheme: const AppBarTheme(backgroundColor: darkBg, elevation: 0),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.grey,
    ),
  );
}