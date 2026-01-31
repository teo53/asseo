import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/snow_animation.dart';
import '../../providers/preregistration_provider.dart';
import 'email_form.dart';

/// 히어로 섹션 - PC 최적화 2-Column 레이아웃
class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preregistrationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;
    final formatter = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: screenHeight),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientVoid,
      ),
      child: Stack(
        children: [
          // 눈 애니메이션 배경
          Positioned.fill(
            child: SnowAnimation(
              snowflakeCount: isMobile ? 30 : 60,
              child: const SizedBox.expand(),
            ),
          ),

          // 우측 상단 글로우 (PC)
          if (isDesktop)
            Positioned(
              top: -200,
              right: -100,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.snowPure.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // 콘텐츠
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppTheme.space4 : AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(context, ref, state, formatter)
                    : _buildMobileLayout(context, ref, state, formatter, isMobile),
              ),
            ),
          ),

          // 스크롤 인디케이터 (하단 고정)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppTheme.space8,
            child: _buildScrollIndicator(),
          ),
        ],
      ),
    );
  }

  /// PC 데스크탑 레이아웃 - 좌측 텍스트, 우측 폼
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    PreregistrationState state,
    NumberFormat formatter,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측: 브랜드 메시지
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: AppTheme.space12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 로고 + 브랜드명
                Row(
                  children: [
                    _buildLogo(size: 56),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      'MOE BACKSTAGE',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space10),

                // 메인 헤드라인
                Text(
                  '밤에 내린 눈처럼\n당신만의 특별한 순간',
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 52,
                    fontWeight: FontWeight.w200,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppTheme.space6),

                // 서브 카피
                Text(
                  '좋아하는 캐스트와 나누는 프라이빗 메시지,\n지금 사전예약하고 가장 먼저 만나보세요.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textOnDarkSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppTheme.space8),

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

  /// 모바일/태블릿 레이아웃 - 세로 스택
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    PreregistrationState state,
    NumberFormat formatter,
    bool isMobile,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppTheme.space8),

        // 로고
        _buildLogo(size: 80),
        const SizedBox(height: AppTheme.space6),

        // 브랜드명
        Text(
          'MOE BACKSTAGE',
          style: AppTypography.displayMedium.copyWith(
            fontWeight: FontWeight.w200,
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space4),

        // 서브타이틀
        Text(
          '밤에 내린 눈처럼,\n당신만의 특별한 순간',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.w300,
            color: AppColors.textOnDarkSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space3),

        // 설명
        Text(
          '좋아하는 캐스트와 나누는 프라이빗 메시지',
          style: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space8),

        // 사전예약 카드
        _buildRegistrationCard(context, ref, state),
        const SizedBox(height: AppTheme.space6),

        // 예약자 수
        _buildRegistrationCount(state.totalCount, formatter),
        const SizedBox(height: AppTheme.space12),
      ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 카드 헤더
          Text(
            '사전예약',
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '런칭 시 가장 먼저 알려드려요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
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

          const SizedBox(height: AppTheme.space6),
          const Divider(color: Colors.white10),
          const SizedBox(height: AppTheme.space4),

          // 혜택 안내
          _buildBenefits(),
        ],
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.gradientSnowPearl,
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppColors.snowPure.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'M',
          style: TextStyle(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w200,
            color: AppColors.deepNight,
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyRegistered(PreregistrationState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.statusSuccess.withOpacity(0.3),
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
            state.phone ?? '',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      '첫 달 무료',
      '한정판 배지',
      '굿즈 할인',
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
          '이 기다리고 있어요',
          style: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildScrollIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '더 알아보기',
          style: AppTypography.caption.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: AppTheme.space2),
        const _BouncingArrow(),
      ],
    );
  }
}

/// 바운싱 화살표 애니메이션
class _BouncingArrow extends StatefulWidget {
  const _BouncingArrow();

  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textOnDarkMuted,
            size: 28,
          ),
        );
      },
    );
  }
}
