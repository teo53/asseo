import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/snow_animation.dart';

/// 스플래시 페이지
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SparklingSnowAnimation(
        snowflakeCount: 40,
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.gradientVoid,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientSnowPearl,
                    borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                    boxShadow: AppTheme.glowMedium,
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w200,
                        color: AppColors.deepNight,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
                const SizedBox(height: AppTheme.space6),

                // 앱 이름
                Text(
                  'MOE BACKSTAGE',
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w200,
                    letterSpacing: 6,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.3, curve: Curves.easeOut),

                const SizedBox(height: AppTheme.space2),

                // 서브타이틀
                Text(
                  '밤에 내린 눈처럼, 당신만의 특별한 순간',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textOnDarkMuted,
                    letterSpacing: 1,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 600.ms),

                const SizedBox(height: AppTheme.space16),

                // 로딩 인디케이터
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 외부 링
                      const CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.snowPure,
                      ),
                      // 내부 점
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.snowPure,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: 1000.ms,
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(0.8, 0.8),
                            duration: 1000.ms,
                            curve: Curves.easeInOut,
                          ),
                    ],
                  ),
                ).animate(delay: 800.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
