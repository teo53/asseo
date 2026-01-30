import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';

/// 프로필 페이지
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: currentUser == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder(
                  future: service.getProfile(currentUser.id),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space6),
                      child: Column(
                        children: [
                          const SizedBox(height: AppTheme.space6),

                          // 프로필 이미지
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.gradientSnowPearl,
                              boxShadow: AppTheme.glowMedium,
                            ),
                            child: profile?['profile_image'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      profile!['profile_image'],
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.deepNight,
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
                            currentUser.email ?? '',
                            style: AppTypography.bodySmall,
                          ),

                          const SizedBox(height: AppTheme.space10),

                          // 메뉴 리스트
                          _ProfileMenuItem(
                            icon: Icons.person_outline,
                            title: '프로필 수정',
                            onTap: () {
                              // TODO: 프로필 수정 페이지
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.favorite_outline,
                            title: '내 구독',
                            onTap: () {
                              // TODO: 구독 관리 페이지
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.notifications_outlined,
                            title: '알림 설정',
                            onTap: () {
                              // TODO: 알림 설정 페이지
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.language_outlined,
                            title: '언어 설정',
                            subtitle: '한국어',
                            onTap: () {
                              // TODO: 언어 설정
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.help_outline,
                            title: '고객센터',
                            onTap: () {
                              // TODO: 고객센터
                            },
                          ),
                          _ProfileMenuItem(
                            icon: Icons.info_outline,
                            title: '앱 정보',
                            subtitle: 'v1.0.0',
                            onTap: () {
                              // TODO: 앱 정보
                            },
                          ),

                          const SizedBox(height: AppTheme.space8),

                          // 로그아웃 버튼
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await authService.signOut();
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
