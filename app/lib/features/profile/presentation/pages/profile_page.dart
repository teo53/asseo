import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';
import 'profile_edit_page.dart';
import 'notification_settings_page.dart';
import 'language_settings_page.dart';
import 'support_page.dart';
import 'app_info_page.dart';

/// 프로필 페이지
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final service = ref.watch(supabaseServiceProvider);
    final demoProfile = ref.watch(demoProfileProvider);
    final currentLanguage = ref.watch(demoLanguageProvider);

    // 데모 모드 또는 실제 유저가 있으면 프로필 표시
    final showProfile = isDemoMode || currentUser != null;

    // 언어 표시 이름
    final languageDisplayName = {
      'ko': '한국어',
      'en': 'English',
      'ja': '日本語',
      'zh': '中文',
    }[currentLanguage] ?? '한국어';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: !showProfile
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder(
                  future: isDemoMode
                      ? Future.value(demoProfile)
                      : service.getProfile(currentUser!.id),
                  builder: (context, snapshot) {
                    final profile = isDemoMode ? demoProfile : snapshot.data;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space6),
                      child: Column(
                        children: [
                          const SizedBox(height: AppTheme.space6),

                          // 프로필 아이콘
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.profileBackground,
                              border: Border.all(
                                color: AppColors.profileBorder,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 50,
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space4),

                          // 닉네임
                          Text(
                            profile?['nickname'] ?? '사용자',
                            style: AppTypography.heading2,
                          ),
                          const SizedBox(height: AppTheme.space1),

                          // 이메일
                          Text(
                            isDemoMode ? 'test@test.com' : (currentUser?.email ?? ''),
                            style: AppTypography.bodySmall,
                          ),

                          // DreamTime 잔액 (데모 모드)
                          if (profile?['dreamtime_balance'] != null) ...[
                            const SizedBox(height: AppTheme.space4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.space4,
                                vertical: AppTheme.space2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: AppColors.snowPearl,
                                  ),
                                  const SizedBox(width: AppTheme.space2),
                                  Text(
                                    '${profile!['dreamtime_balance']} DT',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.snowPearl,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppTheme.space10),

                          // 메뉴 리스트
                          _ProfileMenuItem(
                            icon: Icons.person_outline,
                            title: '프로필 수정',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                              );
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.favorite_outline,
                            title: '내 구독',
                            onTap: () {
                              context.go('/chat');
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.notifications_outlined,
                            title: '알림 설정',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
                              );
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.language_outlined,
                            title: '언어 설정',
                            subtitle: languageDisplayName,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LanguageSettingsPage()),
                              );
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.help_outline,
                            title: '고객센터',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SupportPage()),
                              );
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.info_outline,
                            title: '앱 정보',
                            subtitle: 'v1.0.0 ${isDemoMode ? '(데모)' : ''}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AppInfoPage()),
                              );
                            },
                          ),

                          const SizedBox(height: AppTheme.space8),

                          // 로그아웃 버튼
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                if (isDemoMode) {
                                  ref.read(demoAuthStateProvider.notifier).state = false;
                                  context.go('/login');
                                } else {
                                  ref.read(authServiceProvider).signOut();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.statusError,
                                side: const BorderSide(
                                  color: AppColors.statusError,
                                ),
                              ),
                              child: const Text('로그아웃'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// 프로필 메뉴 아이템
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space4,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textOnDarkSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppTheme.space4),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall,
                  ),
                const SizedBox(width: AppTheme.space2),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textOnDarkMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
