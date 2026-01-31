import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// 랜딩페이지 푸터
class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.space4 : AppTheme.space8,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepNight,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          // 로고
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSnowPearl,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w200,
                      color: AppColors.deepNight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              Text(
                'MOE BACKSTAGE',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),

          // 링크들
          Wrap(
            spacing: AppTheme.space4,
            runSpacing: AppTheme.space2,
            alignment: WrapAlignment.center,
            children: [
              _FooterLink(text: '이용약관', onTap: () {}),
              _FooterLink(text: '개인정보처리방침', onTap: () {}),
              _FooterLink(text: '문의하기', onTap: () {}),
            ],
          ),
          const SizedBox(height: AppTheme.space4),

          // 소셜 미디어
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                icon: Icons.language,
                onTap: () {},
              ),
              const SizedBox(width: AppTheme.space3),
              _SocialButton(
                icon: Icons.chat_bubble_outline,
                onTap: () {},
              ),
              const SizedBox(width: AppTheme.space3),
              _SocialButton(
                icon: Icons.alternate_email,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),

          // 저작권
          Text(
            '© 2024 MOE BACKSTAGE. All rights reserved.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space2),

          // 문의 이메일
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 14,
                color: AppColors.textOnDarkMuted,
              ),
              const SizedBox(width: AppTheme.space1),
              Text(
                'support@moebackstage.com',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 푸터 링크
class _FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: AppTypography.bodySmall.copyWith(
            color: _isHovered
                ? AppColors.snowPure
                : AppColors.textOnDarkSecondary,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

/// 소셜 미디어 버튼
class _SocialButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered
                ? AppColors.snowPure
                : AppColors.textOnDarkMuted,
          ),
        ),
      ),
    );
  }
}
