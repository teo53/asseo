import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

/// 스플래시 페이지
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고 (추후 실제 로고로 교체)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSnowPearl,
                  borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                  boxShadow: AppTheme.glowMedium,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 60,
                  color: AppColors.deepNight,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: AppTheme.space6),

              // 앱 이름
              Text(
                'MOE BACKSTAGE',
                style: AppTypography.displayMedium.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: AppTheme.space2),

              // 서브타이틀
              Text(
                '당신만의 프라이빗 메시지',
                style: AppTypography.body.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: AppTheme.space12),

              // 로딩 인디케이터
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.snowPure,
                ),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
