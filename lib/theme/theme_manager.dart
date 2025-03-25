import 'package:flutter/material.dart';

class ThemeManager {
  static ThemeData buildIOSTheme() {
    const Color primaryColor = Color(0xFF1C1C1E);
    const Color greenColor = Color(0xFF00C853); // Vibrant Green
    const Color scaffoldBackgroundColor = Color(0xFFF2F2F7);
    const Color primaryTextColor = Color(0xFF1C1C1E);
    const Color secondaryTextColor = Color(0xFF3A3A3C);
    const Color tertiaryTextColor = Color(0xFF636366); // Lighter gray

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondaryContainer: greenColor,
        onSecondaryContainer: Colors.white,
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
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: primaryTextColor),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: primaryTextColor),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: tertiaryTextColor),
        labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: greenColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),

      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
