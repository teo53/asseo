import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/cta_section.dart';
import '../widgets/landing_footer.dart';

/// 사전예약 랜딩페이지 - PC 최적화
class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton = _scrollController.offset > 500;
    if (showButton != _showFloatingButton) {
      setState(() => _showFloatingButton = showButton);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNight,
      body: Stack(
        children: [
          // 메인 스크롤 콘텐츠
          CustomScrollView(
            controller: _scrollController,
            slivers: const [
              // 히어로 섹션
              SliverToBoxAdapter(child: HeroSection()),

              // 기능 소개 섹션
              SliverToBoxAdapter(child: FeaturesSection()),

              // 앱 미리보기 섹션
              SliverToBoxAdapter(child: _PreviewSection()),

              // 최종 CTA 섹션
              SliverToBoxAdapter(child: CtaSection()),

              // 푸터
              SliverToBoxAdapter(child: LandingFooter()),
            ],
          ),

          // 플로팅 스크롤 투 탑 버튼
          Positioned(
            right: AppTheme.space6,
            bottom: AppTheme.space6,
            child: _ScrollToTopButton(
              isVisible: _showFloatingButton,
              onPressed: _scrollToTop,
            ),
          ),
        ],
      ),
    );
  }
}

/// 스크롤 투 탑 버튼
class _ScrollToTopButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;

  const _ScrollToTopButton({
    required this.isVisible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.8,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isVisible ? onPressed : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: const Center(
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: AppColors.snowPure,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 앱 미리보기 섹션 - PC 최적화
class _PreviewSection extends StatelessWidget {
  const _PreviewSection();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.space4 : AppTheme.space8,
        vertical: isDesktop ? AppTheme.space16 : AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepNight,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // 섹션 헤더
              _buildSectionHeader(isMobile),
              SizedBox(height: isDesktop ? AppTheme.space12 : AppTheme.space8),

              // 미리보기 카드들
              isDesktop
                  ? _buildDesktopLayout()
                  : _buildMobileLayout(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(bool isMobile) {
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
          child: Text(
            'PREVIEW',
            style: AppTypography.caption.copyWith(
              color: AppColors.textOnDarkMuted,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space4),

        // 타이틀
        Text(
          '이런 경험이 기다려요',
          style: (isMobile ? AppTypography.heading1 : AppTypography.displayMedium)
              .copyWith(
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space2),

        // 서브타이틀
        Text(
          '좋아하는 캐스트와 더 가까워지는 특별한 순간',
          style: AppTypography.body.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PreviewCard(
            title: '프라이빗 채팅',
            description: '캐스트가 보내는 특별한 메시지를 마치 1:1 대화처럼 받아보세요',
            mockupContent: const _ChatMockup(),
          ),
        ),
        const SizedBox(width: AppTheme.space6),
        Expanded(
          child: _PreviewCard(
            title: '독점 굿즈',
            description: '팬만을 위한 한정판 굿즈를 가장 먼저 만나보세요',
            mockupContent: const _ShopMockup(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    return Column(
      children: [
        _PreviewCard(
          title: '프라이빗 채팅',
          description: '캐스트가 보내는 특별한 메시지를 마치 1:1 대화처럼 받아보세요',
          mockupContent: const _ChatMockup(),
        ),
        const SizedBox(height: AppTheme.space4),
        _PreviewCard(
          title: '독점 굿즈',
          description: '팬만을 위한 한정판 굿즈를 가장 먼저 만나보세요',
          mockupContent: const _ShopMockup(),
        ),
      ],
    );
  }
}

/// 미리보기 카드 - 미니멀 디자인
class _PreviewCard extends StatefulWidget {
  final String title;
  final String description;
  final Widget mockupContent;

  const _PreviewCard({
    required this.title,
    required this.description,
    required this.mockupContent,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppTheme.space5),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: _isHovered
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              widget.title,
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              widget.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space4),

            // 목업
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: widget.mockupContent,
            ),
          ],
        ),
      ),
    );
  }
}

/// 채팅 목업
class _ChatMockup extends StatelessWidget {
  const _ChatMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.3),
                      const Color(0xFFEC4899).withOpacity(0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.snowPure,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '윈터',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '방금 전',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textOnDarkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  'VIP',
                  style: AppTypography.caption.copyWith(
                    color: const Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.space3),
            child: Divider(color: Colors.white10, height: 1),
          ),

          // 메시지들
          Expanded(
            child: Column(
              children: [
                _buildChatBubble('오늘 연습 끝났어요~ 💪', '오후 6:42'),
                const SizedBox(height: AppTheme.space3),
                _buildChatBubble('내일 컴백 무대 기대해주세요! ❄️', '오후 6:43'),
                const SizedBox(height: AppTheme.space3),
                _buildChatBubble('마이들 사랑해요 🤍', '오후 6:44'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space3,
            vertical: AppTheme.space2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            text,
            style: AppTypography.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppTheme.space2, top: 4),
          child: Text(
            time,
            style: AppTypography.caption.copyWith(
              color: AppColors.textOnDarkMuted,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

/// 샵 목업
class _ShopMockup extends StatelessWidget {
  const _ShopMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusError.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: AppColors.statusError,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '인기',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.statusError,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '전체보기',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textOnDarkMuted,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),

          // 굿즈 그리드
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGoodsItem('포토카드 세트', '12,000'),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: _buildGoodsItem('응원봉', '35,000'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildGoodsItem('키링', '8,000'),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: _buildGoodsItem('슬로건', '15,000'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoodsItem(String name, String price) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.textOnDarkMuted,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            name,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '₩$price',
            style: AppTypography.caption.copyWith(
              color: AppColors.snowPure,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
