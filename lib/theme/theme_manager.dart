import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeManager {
  static ThemeData buildIOSTheme() {
    // Brand colors + iOS influence
    const Color primaryColor = Colors.black;
    const Color accentRed = Color(0xFFE53935);
    const Color accentGreen = Color(0xFF00C853);
    const Color scaffoldBackgroundColor = Color(0xFFF2F2F7); // iOS light background
    const Color dividerColor = Color(0xFFCED4DA); // iOS divider gray
    const Color primaryTextColor = Color(0xFF1C1C1E);
    const Color secondaryTextColor = Color(0xFF3A3A3C);
    const Color tertiaryTextColor = Color(0xFF636366);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'SF Pro Text', // iOS font
      dividerColor: dividerColor,

      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentGreen,
        onSecondary: Colors.white,
        background: scaffoldBackgroundColor,
        onBackground: primaryTextColor,
        surface: Colors.white,
        onSurface: primaryTextColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w600, color: primaryTextColor, fontFamily: 'SF Pro Display'
        ),
        titleMedium: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w500, color: primaryTextColor, fontFamily: 'SF Pro Text'
        ),
        bodyLarge: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w400, color: secondaryTextColor, fontFamily: 'SF Pro Text'
        ),
        bodyMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w400, color: tertiaryTextColor, fontFamily: 'SF Pro Text'
        ),
        labelLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'SF Pro Text'
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SF Pro Text'
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0, // iOS buttons have no shadow
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'SF Pro Text'
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        hintStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: tertiaryTextColor,
          fontFamily: 'SF Pro Text',
        ),
      ),

      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        dense: true,
        horizontalTitleGap: 8,
      ),

      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 0.8,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
    );
  }
}
