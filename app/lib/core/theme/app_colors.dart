import 'package:flutter/material.dart';

/// MOE BACKSTAGE 컬러 시스템
/// 디자인 컨셉: "Dreamlike Snow" (몽환적인 눈)
class AppColors {
  AppColors._();

  // ============================================
  // Snow White - 눈처럼 부드러운 흰색 계열
  // ============================================
  static const Color snowPure = Color(0xFFFFFFFF);
  static const Color snowSoft = Color(0xFFF8F9FA);
  static const Color snowPearl = Color(0xFFF0F1F3);
  static const Color snowMist = Color(0xFFE8EAED);

  // ============================================
  // Deep Gray - 짙은 회색/검정 계열
  // ============================================
  static const Color deepVoid = Color(0xFF121214);
  static const Color deepNight = Color(0xFF1A1A1D);
  static const Color deepShadow = Color(0xFF242428);
  static const Color deepSlate = Color(0xFF2E2E33);
  static const Color deepAsh = Color(0xFF3A3A40);

  // ============================================
  // Accent Colors
  // ============================================
  static const Color accentPearl = Color(0xD9FFFFFF); // 85% opacity
  static const Color accentGlow = Color(0x26FFFFFF); // 15% opacity
  static const Color accentShimmer = Color(0x4DC8C8DC); // 30% opacity

  // ============================================
  // Semantic Colors
  // ============================================

  // Text on Dark
  static const Color textOnDark = snowPure;
  static const Color textOnDarkSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textOnDarkMuted = Color(0x80FFFFFF); // 50%

  // Text on Light
  static const Color textOnLight = deepNight;
  static const Color textOnLightSecondary = Color(0xB31A1A1D); // 70%

  // Surfaces
  static const Color surfaceDark = deepNight;
  static const Color surfaceDarkElevated = deepShadow;
  static const Color surfaceLight = snowSoft;
  static const Color surfaceLightElevated = snowPure;

  // Interactive States
  static const Color interactiveHover = Color(0x14FFFFFF); // 8%
  static const Color interactivePressed = Color(0x1FFFFFFF); // 12%
  static const Color interactiveFocus = Color(0x33FFFFFF); // 20%

  // Status Colors
  static const Color statusSuccess = Color(0xFF4ADE80);
  static const Color statusWarning = Color(0xFFFBBF24);
  static const Color statusError = Color(0xFFF87171);
  static const Color statusInfo = Color(0xFF60A5FA);

  // ============================================
  // Gradients
  // ============================================

  /// 눈/펄 효과 그라디언트
  static const LinearGradient gradientSnowPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xF2F8F9FA),
      Color(0xE6F0F1F3),
    ],
  );

  static const LinearGradient gradientSnowPearl = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFAF5F5FA),
      Color(0xF2F0F0F8),
      Color(0xEBEBEBF5),
    ],
  );

  /// 어두운 배경 그라디언트
  static const LinearGradient gradientVoid = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      deepVoid,
      deepNight,
      deepVoid,
    ],
  );

  static const RadialGradient gradientNightRadial = RadialGradient(
    center: Alignment(0, -1),
    radius: 1.5,
    colors: [
      deepSlate,
      deepNight,
      deepVoid,
    ],
  );
}
