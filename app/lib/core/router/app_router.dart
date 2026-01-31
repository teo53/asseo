import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_room_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';
import '../../features/cast/presentation/pages/cast_profile_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/notification/presentation/pages/notification_list_page.dart';
import '../../main.dart';
import '../services/auth_service.dart';

/// 앱 라우터 Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isDemoLoggedIn = ref.watch(demoAuthStateProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // 데모 모드에서의 로그인 상태
      final isLoggedIn = isDemoMode
          ? isDemoLoggedIn
          : authState.valueOrNull != null;

      final isSplash = state.matchedLocation == '/';
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // 1. 로딩 중이면 스플래시에 머무름 (데모 모드에서는 스킵)
      if (!isDemoMode && authState.isLoading) {
        return isSplash ? null : '/';
      }

      // 2. 스플래시에서 로딩 완료 → 적절한 페이지로 이동
      if (isSplash) {
        return isLoggedIn ? '/home' : '/login';
      }

      // 3. 로그인 안 됨 + 보호된 페이지 → 로그인으로
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // 4. 로그인 됨 + 인증 페이지 → 홈으로
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Landing (사전예약 페이지 - 초기 진입점)
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingPage(),
      ),

      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main Shell (Bottom Navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListPage(),
            routes: [
              GoRoute(
                path: ':castId',
                builder: (context, state) {
                  final castId = state.pathParameters['castId']!;
                  return ChatRoomPage(castId: castId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => const ShopPage(),
          ),
          GoRoute(
            path: '/cast/:castId',
            builder: (context, state) {
              final castId = state.pathParameters['castId']!;
              return CastProfilePage(castId: castId);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationListPage(),
          ),
        ],
      ),
    ],
  );
});

/// 메인 쉘 (하단 네비게이션 포함)
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

/// 하단 네비게이션 바
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/shop') || location.startsWith('/cast')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/shop');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: '샵',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}
