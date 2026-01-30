import 'package:flutter/material.dart';
import 'app_colors.dart';

/// MOE BACKSTAGE 타이포그래피 시스템
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  // ============================================
  // Text Styles
  // ============================================

  /// Display Large - 스플래시, 히어로
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.textOnDark,
  );

  /// Display Medium - 섹션 타이틀
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    height: 1.25,
    letterSpacing: -0.25,
    color: AppColors.textOnDark,
  );

  /// Heading 1 - 페이지 타이틀
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.textOnDark,
  );

  /// Heading 2 - 카드 타이틀
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.textOnDark,
  );

  /// Heading 3 - 서브섹션
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textOnDark,
  );

  /// Body Large - 강조 본문
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textOnDark,
  );

  /// Body - 기본 본문
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textOnDark,
  );

  /// Body Small - 보조 텍스트
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textOnDarkSecondary,
  );

  /// Caption - 레이블, 힌트
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textOnDarkMuted,
  );

  /// Button - 버튼 텍스트
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 0.5,
  );

  /// Label - 작은 레이블
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
    color: AppColors.textOnDarkMuted,
  );
}
