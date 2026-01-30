import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 데모 모드 여부 (Supabase 연결 실패 시 true)
bool isDemoMode = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.deepVoid,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Supabase 초기화 (실패 시 데모 모드)
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase 초기화 실패: $e');
    debugPrint('데모 모드로 실행합니다.');
    isDemoMode = true;
  }

  runApp(
    const ProviderScope(
      child: MoeBackstageApp(),
    ),
  );
}

class MoeBackstageApp extends ConsumerWidget {
  const MoeBackstageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 데모 모드에서는 단순한 UI 표시
    if (isDemoMode) {
      return MaterialApp(
        title: 'MOE BACKSTAGE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DemoHomePage(),
      );
    }

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MOE BACKSTAGE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}

/// 데모 모드 홈 페이지
class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.deepVoid,
              AppColors.deepNight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // 로고 영역
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientSnowPearl,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: AppColors.deepNight,
                ),
              ),
              const SizedBox(height: 32),
              // 앱 타이틀
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.snowPure, AppColors.snowPearl],
                ).createShader(bounds),
                child: const Text(
                  'MOE BACKSTAGE',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '지하아이돌 · 메이드 팬 커뮤니케이션',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 48),
              // 데모 모드 안내
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: AppColors.snowPearl,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '데모 모드',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supabase 백엔드에 연결되지 않았습니다.\n실제 서비스를 이용하려면 Supabase 설정이 필요합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 기능 미리보기 버튼들
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    _DemoFeatureButton(
                      icon: Icons.chat_bubble_outline,
                      label: '1:1 프라이빗 메시지',
                      description: '캐스트와 특별한 소통',
                    ),
                    const SizedBox(height: 12),
                    _DemoFeatureButton(
                      icon: Icons.auto_awesome,
                      label: 'DreamTime 후원',
                      description: '마음을 전하는 특별한 방법',
                    ),
                    const SizedBox(height: 12),
                    _DemoFeatureButton(
                      icon: Icons.favorite_outline,
                      label: '구독 멤버십',
                      description: '단계별 특별 혜택',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 버전 정보
              Text(
                'v1.0.0 Demo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoFeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;

  const _DemoFeatureButton({
    required this.icon,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.snowPearl,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
