import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/unoa_logo.dart';

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
              // UNOA 로고 아이콘
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientSnowPearl,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentRedGlow,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    ...AppTheme.glowMedium,
                  ],
                ),
                child: Center(
                  child: Text(
                    'U',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: AppColors.deepNight,
                      height: 1.0,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: AppTheme.space8),

              // UNOA 타이포그래피 로고
              const AnimatedUnoaLogo(
                fontSize: 52,
                animationDuration: Duration(milliseconds: 1200),
              ),

              const SizedBox(height: AppTheme.space3),

              // 서브타이틀
              Text(
                'Private Fan Communication',
                style: AppTypography.body.copyWith(
                  color: AppColors.textOnDarkMuted,
                  letterSpacing: 1,
                ),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: AppTheme.space16),

              // 로딩 인디케이터
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentRed.withOpacity(0.7),
                ),
              ).animate(delay: 1000.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
