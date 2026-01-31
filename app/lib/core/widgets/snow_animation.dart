import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 환상적인 눈 내리는 애니메이션 위젯
/// "밤에 내린 눈" 컨셉 - 깊이감 있는 3개 레이어 + 은은한 글로우
class SnowAnimation extends StatefulWidget {
  final Widget child;
  final int snowflakeCount;
  final bool enabled;

  const SnowAnimation({
    super.key,
    required this.child,
    this.snowflakeCount = 40,
    this.enabled = true,
  });

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<EtherealSnowflake> _snowflakes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _initSnowflakes();
  }

  void _initSnowflakes() {
    _snowflakes = [];

    // 후경 레이어 (작고, 느리고, 흐릿함) - 40%
    final backCount = (widget.snowflakeCount * 0.4).round();
    for (int i = 0; i < backCount; i++) {
      _snowflakes.add(EtherealSnowflake.create(
        random: _random,
        layer: SnowLayer.back,
      ));
    }

    // 중경 레이어 (중간) - 35%
    final midCount = (widget.snowflakeCount * 0.35).round();
    for (int i = 0; i < midCount; i++) {
      _snowflakes.add(EtherealSnowflake.create(
        random: _random,
        layer: SnowLayer.middle,
      ));
    }

    // 전경 레이어 (크고, 빠르고, 선명함) - 25%
    final frontCount = widget.snowflakeCount - backCount - midCount;
    for (int i = 0; i < frontCount; i++) {
      _snowflakes.add(EtherealSnowflake.create(
        random: _random,
        layer: SnowLayer.front,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: EtherealSnowPainter(
                    snowflakes: _snowflakes,
                    time: _controller.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 눈송이 레이어 구분
enum SnowLayer { back, middle, front }

/// 몽환적인 눈송이 데이터
class EtherealSnowflake {
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double opacity;
  final double driftAmplitude;
  final double driftFrequency;
  final double driftPhase;
  final double twinklePhase;
  final double twinkleSpeed;
  final double blurAmount;
  final SnowLayer layer;

  EtherealSnowflake({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.driftAmplitude,
    required this.driftFrequency,
    required this.driftPhase,
    required this.twinklePhase,
    required this.twinkleSpeed,
    required this.blurAmount,
    required this.layer,
  });

  factory EtherealSnowflake.create({
    required Random random,
    required SnowLayer layer,
  }) {
    // 레이어별 속성 차등 적용
    double sizeMin, sizeMax, speedMin, speedMax, opacityMin, opacityMax, blur;

    switch (layer) {
      case SnowLayer.back:
        sizeMin = 0.8; sizeMax = 1.5;
        speedMin = 0.15; speedMax = 0.25;
        opacityMin = 0.08; opacityMax = 0.18;
        blur = 3.0;
        break;
      case SnowLayer.middle:
        sizeMin = 1.2; sizeMax = 2.2;
        speedMin = 0.25; speedMax = 0.4;
        opacityMin = 0.15; opacityMax = 0.3;
        blur = 1.5;
        break;
      case SnowLayer.front:
        sizeMin = 1.8; sizeMax = 3.0;
        speedMin = 0.35; speedMax = 0.55;
        opacityMin = 0.25; opacityMax = 0.45;
        blur = 0.8;
        break;
    }

    return EtherealSnowflake(
      startX: random.nextDouble(),
      startY: random.nextDouble() * 1.2 - 0.2, // 화면 위에서 시작할 수도 있음
      size: random.nextDouble() * (sizeMax - sizeMin) + sizeMin,
      speed: random.nextDouble() * (speedMax - speedMin) + speedMin,
      opacity: random.nextDouble() * (opacityMax - opacityMin) + opacityMin,
      driftAmplitude: random.nextDouble() * 25 + 10, // 좌우 흔들림 폭
      driftFrequency: random.nextDouble() * 0.8 + 0.4, // 흔들림 빈도
      driftPhase: random.nextDouble() * 2 * pi,
      twinklePhase: random.nextDouble() * 2 * pi,
      twinkleSpeed: random.nextDouble() * 1.5 + 0.5,
      blurAmount: blur,
      layer: layer,
    );
  }
}

/// 환상적인 눈 페인터
class EtherealSnowPainter extends CustomPainter {
  final List<EtherealSnowflake> snowflakes;
  final double time;

  EtherealSnowPainter({
    required this.snowflakes,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var flake in snowflakes) {
      // Y 위치: 위에서 아래로 떨어짐
      final yProgress = (flake.startY + time * flake.speed) % 1.3;
      final y = yProgress * size.height;

      // 화면 밖이면 스킵
      if (y < -20 || y > size.height + 20) continue;

      // X 위치: 자연스러운 곡선 움직임 (sin + cos 조합)
      final drift = sin(flake.driftPhase + time * flake.driftFrequency * 2 * pi) *
                    flake.driftAmplitude * 0.7 +
                    cos(flake.driftPhase * 1.5 + time * flake.driftFrequency * 1.3 * 2 * pi) *
                    flake.driftAmplitude * 0.3;
      final x = flake.startX * size.width + drift;

      // 화면 밖이면 스킵
      if (x < -20 || x > size.width + 20) continue;

      // 반짝임 효과 (은은하게)
      final twinkle = sin(flake.twinklePhase + time * flake.twinkleSpeed * 2 * pi);
      final currentOpacity = (flake.opacity + twinkle * 0.08).clamp(0.05, 0.5);

      // 가장자리 페이드 아웃
      double edgeFade = 1.0;
      if (yProgress < 0.1) {
        edgeFade = yProgress / 0.1;
      } else if (yProgress > 1.1) {
        edgeFade = (1.3 - yProgress) / 0.2;
      }

      final finalOpacity = (currentOpacity * edgeFade).clamp(0.0, 1.0);

      final center = Offset(x, y);

      // 코어 (중심부) - 약간 더 밝음
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(finalOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blurAmount * 0.5);
      canvas.drawCircle(center, flake.size * 0.6, corePaint);

      // 글로우 (외곽 빛) - 부드러운 확산
      final glowPaint = Paint()
        ..color = const Color(0xFFF0F4FF).withOpacity(finalOpacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blurAmount * 2);
      canvas.drawCircle(center, flake.size * 1.2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(EtherealSnowPainter oldDelegate) => true;
}

/// 살짝 반짝이는 프리미엄 눈 효과 (스플래시/로그인용)
class SparklingSnowAnimation extends StatefulWidget {
  final Widget child;
  final int snowflakeCount;
  final bool enabled;

  const SparklingSnowAnimation({
    super.key,
    required this.child,
    this.snowflakeCount = 50,
    this.enabled = true,
  });

  @override
  State<SparklingSnowAnimation> createState() => _SparklingSnowAnimationState();
}

class _SparklingSnowAnimationState extends State<SparklingSnowAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  late List<PremiumSnowflake> _snowflakes;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _initSnowflakes();
  }

  void _initSnowflakes() {
    _snowflakes = [];

    // 후경 레이어 - 35%
    final backCount = (widget.snowflakeCount * 0.35).round();
    for (int i = 0; i < backCount; i++) {
      _snowflakes.add(PremiumSnowflake.create(
        random: _random,
        layer: SnowLayer.back,
      ));
    }

    // 중경 레이어 - 40%
    final midCount = (widget.snowflakeCount * 0.40).round();
    for (int i = 0; i < midCount; i++) {
      _snowflakes.add(PremiumSnowflake.create(
        random: _random,
        layer: SnowLayer.middle,
      ));
    }

    // 전경 레이어 - 25%
    final frontCount = widget.snowflakeCount - backCount - midCount;
    for (int i = 0; i < frontCount; i++) {
      _snowflakes.add(PremiumSnowflake.create(
        random: _random,
        layer: SnowLayer.front,
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_mainController, _shimmerController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: PremiumSnowPainter(
                    snowflakes: _snowflakes,
                    time: _mainController.value,
                    shimmer: _shimmerController.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 프리미엄 눈송이 데이터
class PremiumSnowflake {
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double baseOpacity;
  final double driftAmplitude;
  final double driftFrequency;
  final double driftPhase;
  final double sparklePhase;
  final double sparkleIntensity;
  final double blurAmount;
  final SnowLayer layer;
  final bool hasSparkle;

  PremiumSnowflake({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.baseOpacity,
    required this.driftAmplitude,
    required this.driftFrequency,
    required this.driftPhase,
    required this.sparklePhase,
    required this.sparkleIntensity,
    required this.blurAmount,
    required this.layer,
    required this.hasSparkle,
  });

  factory PremiumSnowflake.create({
    required Random random,
    required SnowLayer layer,
  }) {
    double sizeMin, sizeMax, speedMin, speedMax, opacityMin, opacityMax, blur;

    switch (layer) {
      case SnowLayer.back:
        sizeMin = 0.6; sizeMax = 1.3;
        speedMin = 0.12; speedMax = 0.22;
        opacityMin = 0.06; opacityMax = 0.15;
        blur = 4.0;
        break;
      case SnowLayer.middle:
        sizeMin = 1.0; sizeMax = 2.0;
        speedMin = 0.2; speedMax = 0.35;
        opacityMin = 0.12; opacityMax = 0.28;
        blur = 2.0;
        break;
      case SnowLayer.front:
        sizeMin = 1.5; sizeMax = 2.8;
        speedMin = 0.3; speedMax = 0.5;
        opacityMin = 0.2; opacityMax = 0.4;
        blur = 0.8;
        break;
    }

    return PremiumSnowflake(
      startX: random.nextDouble(),
      startY: random.nextDouble() * 1.3 - 0.3,
      size: random.nextDouble() * (sizeMax - sizeMin) + sizeMin,
      speed: random.nextDouble() * (speedMax - speedMin) + speedMin,
      baseOpacity: random.nextDouble() * (opacityMax - opacityMin) + opacityMin,
      driftAmplitude: random.nextDouble() * 20 + 8,
      driftFrequency: random.nextDouble() * 0.6 + 0.3,
      driftPhase: random.nextDouble() * 2 * pi,
      sparklePhase: random.nextDouble() * 2 * pi,
      sparkleIntensity: random.nextDouble() * 0.15 + 0.05,
      blurAmount: blur,
      layer: layer,
      hasSparkle: random.nextDouble() > 0.6, // 40%의 눈송이만 반짝임
    );
  }
}

/// 프리미엄 눈 페인터
class PremiumSnowPainter extends CustomPainter {
  final List<PremiumSnowflake> snowflakes;
  final double time;
  final double shimmer;

  PremiumSnowPainter({
    required this.snowflakes,
    required this.time,
    required this.shimmer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var flake in snowflakes) {
      // Y 위치
      final yProgress = (flake.startY + time * flake.speed) % 1.4;
      final y = yProgress * size.height;

      if (y < -30 || y > size.height + 30) continue;

      // X 위치 - 복합 곡선 움직임
      final primaryDrift = sin(flake.driftPhase + time * flake.driftFrequency * 2 * pi);
      final secondaryDrift = sin(flake.driftPhase * 0.7 + time * flake.driftFrequency * 0.6 * 2 * pi);
      final drift = (primaryDrift * 0.65 + secondaryDrift * 0.35) * flake.driftAmplitude;
      final x = flake.startX * size.width + drift;

      if (x < -30 || x > size.width + 30) continue;

      // 반짝임 계산
      double sparkle = 0;
      if (flake.hasSparkle) {
        sparkle = sin(flake.sparklePhase + shimmer * 2 * pi) * flake.sparkleIntensity;
      }

      final currentOpacity = (flake.baseOpacity + sparkle).clamp(0.05, 0.5);

      // 가장자리 페이드
      double fade = 1.0;
      if (yProgress < 0.1) fade = yProgress / 0.1;
      else if (yProgress > 1.2) fade = (1.4 - yProgress) / 0.2;

      final finalOpacity = (currentOpacity * fade).clamp(0.0, 1.0);
      final center = Offset(x, y);

      // 메인 코어
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(finalOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blurAmount * 0.4);
      canvas.drawCircle(center, flake.size * 0.5, corePaint);

      // 소프트 글로우
      final softGlow = Paint()
        ..color = const Color(0xFFF5F8FF).withOpacity(finalOpacity * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blurAmount * 1.5);
      canvas.drawCircle(center, flake.size, softGlow);

      // 반짝임 효과 (특별한 눈송이만)
      if (flake.hasSparkle && sparkle > 0.03) {
        final sparklePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withOpacity(sparkle * 2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, flake.blurAmount * 3);
        canvas.drawCircle(center, flake.size * 2, sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(PremiumSnowPainter oldDelegate) => true;
}
