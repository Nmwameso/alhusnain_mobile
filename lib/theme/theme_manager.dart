import 'dart:ui';

import 'package:flutter/material.dart';

class ThemeManager {
  static ThemeData buildIOSTheme() {
    const Color primaryColor = Color(0xFF007AFF);
    const Color greenColor = Color(0xFF00C853); // Great Green Color
    const Color scaffoldBackgroundColor = Color(0xFFF2F2F7);
    const Color primaryTextColor = Color(0xFF1C1C1E);  // iOS system label color
    const Color secondaryTextColor = Color(0xFF3A3A3C); // Darker secondary text

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(
        primary: primaryColor,
        secondary: greenColor, // Used for accents (e.g., toggles, buttons)
        surface: Colors.white,
        onSurface: primaryTextColor,
        background: scaffoldBackgroundColor,
        onBackground: primaryTextColor,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'SF Pro Text',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          fontFamily: 'SF Pro Text',
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Color(0xFF636366), // Darker secondary text
        ),
        labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      // ... rest of the theme configuration
    );
  }
}