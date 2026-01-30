import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 눈/펄 효과가 적용된 프라이머리 버튼
class SnowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final double? width;
  final double height;

  const SnowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppColors.gradientSnowPearl,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: [
          ...AppTheme.shadowMd,
          ...AppTheme.glowSoft,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepNight,
                    ),
                  )
                : DefaultTextStyle(
                    style: AppTypography.button.copyWith(
                      color: AppColors.deepNight,
                    ),
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 아웃라인 버튼 (보조)
class OutlineSnowButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;

  const OutlineSnowButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          child: Center(
            child: DefaultTextStyle(
              style: AppTypography.button.copyWith(
                color: AppColors.snowPure,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
