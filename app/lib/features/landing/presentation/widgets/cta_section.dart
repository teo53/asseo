import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/snow_animation.dart';
import '../../providers/preregistration_provider.dart';
import 'email_form.dart';

/// 최종 CTA 섹션 - PC 최적화 미니멀 디자인
class CtaSection extends ConsumerWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preregistrationProvider);
    final timeUntilLaunch = ref.watch(timeUntilLaunchProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;
    final formatter = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.space4 : AppTheme.space8,
        vertical: isDesktop ? AppTheme.space16 : AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientVoid,
      ),
      child: Stack(
        children: [
          // 배경 눈 애니메이션
          Positioned.fill(
            child: SnowAnimation(
              snowflakeCount: isMobile ? 20 : 40,
              child: const SizedBox.expand(),
            ),
          ),

          // 상단 글로우
          Positioned(
            top: -150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.snowPure.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 콘텐츠
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: isDesktop
                  ? _buildDesktopLayout(context, ref, state, timeUntilLaunch, formatter)
                  : _buildMobileLayout(context, ref, state, timeUntilLaunch, formatter, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  /// PC 레이아웃 - 좌측 카운트다운, 우측 폼
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    PreregistrationState state,
    AsyncValue<Duration> timeUntilLaunch,
    NumberFormat formatter,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측: 카운트다운 + 메시지
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: AppTheme.space12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 라벨
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                    vertical: AppTheme.space1,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.rocket_launch_outlined,
                        color: AppColors.snowPure,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LAUNCHING SOON',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnDarkMuted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space6),

                // 카운트다운
                timeUntilLaunch.when(
                  data: (duration) => _buildDesktopCountdown(duration),
                  loading: () => _buildDesktopCountdown(const Duration(days: 30)),
                  error: (_, __) => _buildDesktopCountdown(const Duration(days: 30)),
                ),
                const SizedBox(height: AppTheme.space8),

                // 메시지
                Text(
                  '지금 사전예약하고\n특별한 혜택을 받으세요',
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // 서브 메시지
                Text(
                  '런칭 알림부터 얼리버드 혜택까지, 놓치지 마세요.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.space6),

                // 예약자 수
                _buildRegistrationCount(state.totalCount, formatter),
              ],
            ),
          ),
        ),

        // 우측: 사전예약 카드
        Expanded(
          flex: 4,
          child: _buildRegistrationCard(context, ref, state),
        ),
      ],
    );
  }

  /// 모바일 레이아웃
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    PreregistrationState state,
    AsyncValue<Duration> timeUntilLaunch,
    NumberFormat formatter,
    bool isMobile,
  ) {
    return Column(
      children: [
        // 섹션 라벨
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: AppTheme.space1,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rocket_launch_outlined,
                color: AppColors.snowPure,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'LAUNCHING SOON',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space6),

        // 카운트다운
        timeUntilLaunch.when(
          data: (duration) => _buildMobileCountdown(duration),
          loading: () => _buildMobileCountdown(const Duration(days: 30)),
          error: (_, __) => _buildMobileCountdown(const Duration(days: 30)),
        ),
        const SizedBox(height: AppTheme.space8),

        // 메시지
        Text(
          '지금 사전예약하고\n특별한 혜택을 받으세요',
          style: AppTypography.heading1.copyWith(
            fontWeight: FontWeight.w300,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space6),

        // 사전예약 카드
        _buildRegistrationCard(context, ref, state),
        const SizedBox(height: AppTheme.space6),

        // 예약자 수
        _buildRegistrationCount(state.totalCount, formatter),
      ],
    );
  }

  /// PC 카운트다운 - 대형 숫자
  Widget _buildDesktopCountdown(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Row(
      children: [
        _buildCountdownUnit(days, 'DAYS', isLarge: true),
        _buildCountdownSeparator(),
        _buildCountdownUnit(hours, 'HRS', isLarge: true),
        _buildCountdownSeparator(),
        _buildCountdownUnit(minutes, 'MIN', isLarge: true),
        _buildCountdownSeparator(),
        _buildCountdownUnit(seconds, 'SEC', isLarge: true),
      ],
    );
  }

  /// 모바일 카운트다운
  Widget _buildMobileCountdown(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCountdownUnit(days, '일', isLarge: false),
        _buildCountdownSeparator(isSmall: true),
        _buildCountdownUnit(hours, '시간', isLarge: false),
        _buildCountdownSeparator(isSmall: true),
        _buildCountdownUnit(minutes, '분', isLarge: false),
        _buildCountdownSeparator(isSmall: true),
        _buildCountdownUnit(seconds, '초', isLarge: false),
      ],
    );
  }

  Widget _buildCountdownUnit(int value, String label, {required bool isLarge}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: isLarge ? 64 : 32,
            fontWeight: FontWeight.w200,
            color: AppColors.snowPure,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textOnDarkMuted,
            letterSpacing: isLarge ? 2 : 0,
            fontSize: isLarge ? 11 : 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSeparator({bool isSmall = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppTheme.space2 : AppTheme.space4,
      ),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: isSmall ? 24 : 48,
          fontWeight: FontWeight.w200,
          color: AppColors.textOnDarkMuted,
        ),
      ),
    );
  }

  /// 사전예약 카드
  Widget _buildRegistrationCard(
    BuildContext context,
    WidgetRef ref,
    PreregistrationState state,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 혜택 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppColors.snowPure.withOpacity(0.6),
                size: 18,
              ),
              const SizedBox(width: AppTheme.space2),
              Text(
                '사전예약 혜택',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),

          // 혜택 목록
          _buildBenefitsList(),
          const SizedBox(height: AppTheme.space6),

          const Divider(color: Colors.white10),
          const SizedBox(height: AppTheme.space6),

          // 폼 또는 완료 상태
          if (state.isRegistered)
            _buildAlreadyRegistered(state)
          else
            PreregistrationForm(
              onSuccess: () {
                final state = ref.read(preregistrationProvider);
                showDialog(
                  context: context,
                  builder: (context) => RegistrationSuccessModal(
                    phone: state.phone ?? '',
                    email: state.email,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      '첫 달 무료 이용',
      '한정판 프로필 배지',
      '굿즈 할인 혜택',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: benefits.map((benefit) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: AppColors.statusSuccess.withOpacity(0.8),
            ),
            const SizedBox(width: 4),
            Text(
              benefit,
              style: AppTypography.caption.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAlreadyRegistered(PreregistrationState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.statusSuccess.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.statusSuccess,
            size: 40,
          ),
          const SizedBox(height: AppTheme.space3),
          Text(
            '예약 완료!',
            style: AppTypography.heading3.copyWith(
              color: AppColors.statusSuccess,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            '${state.phone}으로 알려드릴게요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCount(int count, NumberFormat formatter) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.statusSuccess,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.statusSuccess.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.space2),
        Text(
          '${formatter.format(count)}명',
          style: AppTypography.body.copyWith(
            color: AppColors.snowPure,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '이 함께하고 있어요',
          style: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
      ],
    );
  }
}
