import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 기능 소개 섹션 - 미니멀하고 세련된 PC 최적화
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const List<_FeatureData> _features = [
    _FeatureData(
      icon: Icons.chat_bubble_outline,
      title: '프라이빗 메시지',
      description: '좋아하는 캐스트와 1:1 채팅처럼 느껴지는 특별한 소통',
      accentColor: Color(0xFF8B5CF6),
    ),
    _FeatureData(
      icon: Icons.workspace_premium,
      title: '구독 시스템',
      description: '스탠다드 · 프리미엄 · VIP, 원하는 만큼 가까워지기',
      accentColor: Color(0xFFF59E0B),
    ),
    _FeatureData(
      icon: Icons.favorite_outline,
      title: 'DreamTime 후원',
      description: '캐스트에게 마음을 전하고 특별한 답장 받기',
      accentColor: Color(0xFFEC4899),
    ),
    _FeatureData(
      icon: Icons.notifications_active_outlined,
      title: '이벤트 알림',
      description: '굿즈, 팬미팅 소식을 누구보다 빠르게',
      accentColor: Color(0xFF10B981),
    ),
  ];

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
        color: AppColors.deepShadow,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // 섹션 헤더
              _buildSectionHeader(isMobile),
              SizedBox(height: isDesktop ? AppTheme.space12 : AppTheme.space8),

              // 기능 그리드
              isDesktop
                  ? _buildDesktopGrid()
                  : _buildMobileGrid(isMobile),
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
            'FEATURES',
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
          '특별한 기능들',
          style: (isMobile ? AppTypography.heading1 : AppTypography.displayMedium)
              .copyWith(
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.space2),

        // 서브타이틀
        Text(
          'MOE BACKSTAGE만의 특별한 경험',
          style: AppTypography.body.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDesktopGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : AppTheme.space3,
              right: index == _features.length - 1 ? 0 : AppTheme.space3,
            ),
            child: _FeatureCard(feature: feature),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileGrid(bool isMobile) {
    if (isMobile) {
      // 모바일: 1열
      return Column(
        children: _features.map((feature) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space4),
            child: _FeatureCard(feature: feature, isCompact: true),
          );
        }).toList(),
      );
    }

    // 태블릿: 2x2 그리드
    return Wrap(
      spacing: AppTheme.space4,
      runSpacing: AppTheme.space4,
      alignment: WrapAlignment.center,
      children: _features.map((feature) {
        return SizedBox(
          width: 280,
          child: _FeatureCard(feature: feature),
        );
      }).toList(),
    );
  }
}

/// 기능 데이터 클래스
class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

/// 기능 카드 - 미니멀 디자인
class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final bool isCompact;

  const _FeatureCard({
    required this.feature,
    this.isCompact = false,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final feature = widget.feature;

    if (widget.isCompact) {
      // 모바일 컴팩트 레이아웃
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _isHovered
                  ? feature.accentColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              // 아이콘
              _buildIcon(feature, size: 44),
              const SizedBox(width: AppTheme.space4),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 데스크탑/태블릿 카드 레이아웃
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppTheme.space6),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: _isHovered
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              transform: Matrix4.translationValues(
                0,
                _isHovered ? -4 : 0,
                0,
              ),
              child: _buildIcon(feature, size: 52),
            ),
            const SizedBox(height: AppTheme.space5),

            // 타이틀
            Text(
              feature.title,
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.space2),

            // 설명
            Text(
              feature.description,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnDarkSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(_FeatureData feature, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: feature.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: feature.accentColor.withOpacity(0.2),
        ),
      ),
      child: Icon(
        feature.icon,
        color: feature.accentColor,
        size: size * 0.5,
      ),
    );
  }
}
