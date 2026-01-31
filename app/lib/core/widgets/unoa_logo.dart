import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// UNOA 브랜드 로고 위젯
/// 'o' 글자에 빨간색 하이라이트가 적용된 타이포그래피 로고
class UnoaLogo extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final bool showGlow;

  const UnoaLogo({
    super.key,
    this.fontSize = 36,
    this.fontWeight = FontWeight.w300,
    this.letterSpacing = 4,
    this.showGlow = true,
  });

  /// 스플래시 화면용 대형 로고
  const UnoaLogo.splash({super.key})
      : fontSize = 48,
        fontWeight = FontWeight.w200,
        letterSpacing = 6,
        showGlow = true;

  /// 홈 헤더용 중형 로고
  const UnoaLogo.header({super.key})
      : fontSize = 28,
        fontWeight = FontWeight.w300,
        letterSpacing = 4,
        showGlow = false;

  /// 앱바용 소형 로고
  const UnoaLogo.appBar({super.key})
      : fontSize = 20,
        fontWeight = FontWeight.w400,
        letterSpacing = 2,
        showGlow = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1.0,
    );

    Widget logo = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // 'u'
        Text(
          'u',
          style: textStyle.copyWith(color: AppColors.snowPure),
        ),
        // 'n'
        Text(
          'n',
          style: textStyle.copyWith(color: AppColors.snowPure),
        ),
        // 'o' - 빨간색 하이라이트
        _buildHighlightedO(textStyle),
        // 'a'
        Text(
          'a',
          style: textStyle.copyWith(color: AppColors.snowPure),
        ),
      ],
    );

    if (showGlow) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRedGlow,
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }

  Widget _buildHighlightedO(TextStyle baseStyle) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accentRedLight,
          AppColors.accentRed,
          AppColors.accentRedDark,
        ],
      ).createShader(bounds),
      child: Text(
        'o',
        style: baseStyle.copyWith(
          color: Colors.white, // ShaderMask가 이 색상을 대체함
          fontWeight: FontWeight.w400, // 'o'만 약간 더 굵게
        ),
      ),
    );
  }
}

/// 애니메이션이 적용된 UNOA 로고
class AnimatedUnoaLogo extends StatefulWidget {
  final double fontSize;
  final Duration animationDuration;

  const AnimatedUnoaLogo({
    super.key,
    this.fontSize = 48,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedUnoaLogo> createState() => _AnimatedUnoaLogoState();
}

class _AnimatedUnoaLogoState extends State<AnimatedUnoaLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentRedGlow
                        .withOpacity(0.25 * _glowAnimation.value),
                    blurRadius: 40 * _glowAnimation.value,
                    spreadRadius: 10 * _glowAnimation.value,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: UnoaLogo(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w200,
        letterSpacing: 6,
        showGlow: false,
      ),
    );
  }
}
