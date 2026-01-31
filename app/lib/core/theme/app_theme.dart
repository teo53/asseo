import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_typography.dart';

/// UNOA 앱 테마
class AppTheme {
  AppTheme._();

  // ============================================
  // Spacing
  // ============================================
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ============================================
  // Border Radius
  // ============================================
  static const double radiusSm = 6;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radiusFull = 9999;

  // ============================================
  // Shadows
  // ============================================
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];

  // Glow Effects
  static List<BoxShadow> glowSoft = [
    BoxShadow(
      color: Colors.white.withOpacity(0.1),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> glowMedium = [
    BoxShadow(
      color: Colors.white.withOpacity(0.15),
      blurRadius: 40,
      spreadRadius: 0,
    ),
  ];

  // ============================================
  // Dark Theme
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,

      // Colors
      colorScheme: const ColorScheme.dark(
        primary: AppColors.snowPure,
        onPrimary: AppColors.deepNight,
        secondary: AppColors.snowPearl,
        onSecondary: AppColors.deepNight,
        surface: AppColors.deepNight,
        onSurface: AppColors.textOnDark,
        error: AppColors.statusError,
        onError: AppColors.snowPure,
      ),

      scaffoldBackgroundColor: AppColors.deepVoid,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.heading3,
        iconTheme: IconThemeData(color: AppColors.snowPure),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.deepNight,
        selectedItemColor: AppColors.snowPure,
        unselectedItemColor: AppColors.textOnDarkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.deepShadow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textOnDarkMuted,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.snowPure,
          foregroundColor: AppColors.deepNight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: space6,
            vertical: space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.snowPure,
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: space6,
            vertical: space3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.snowPure,
          padding: const EdgeInsets.symmetric(
            horizontal: space4,
            vertical: space2,
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.05),
        thickness: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.snowPure,
      ),
    );
  }
}
