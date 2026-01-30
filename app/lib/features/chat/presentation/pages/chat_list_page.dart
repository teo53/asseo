import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';

/// 채팅 목록 페이지
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Text(
                  '채팅',
                  style: AppTypography.heading1,
                ),
              ),

              // 구독 목록
              Expanded(
                child: currentUser == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder(
                        future: service.getMySubscriptions(currentUser.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final subscriptions = snapshot.data ?? [];

                          if (subscriptions.isEmpty) {
                            return _EmptyState();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space4,
                            ),
                            itemCount: subscriptions.length,
                            itemBuilder: (context, index) {
                              final subscription = subscriptions[index];
                              final cast = subscription['cast'];
                              return _ChatListItem(
                                cast: cast,
                                subscription: subscription,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 빈 상태 위젯
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            '아직 채팅방이 없습니다',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '캐스트를 구독하고 프라이빗 메시지를 받아보세요',
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space8),
          ElevatedButton(
            onPressed: () => context.go('/discover'),
            child: const Text('캐스트 탐색하기'),
          ),
        ],
      ),
    );
  }
}

/// 채팅 목록 아이템
class _ChatListItem extends StatelessWidget {
  final Map<String, dynamic> cast;
  final Map<String, dynamic> subscription;

  const _ChatListItem({
    required this.cast,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/chat/${cast['id']}'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(
              children: [
                // 프로필 이미지
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientSnowPearl,
                  ),
                  child: cast['profile_image'] != null
                      ? ClipOval(
                          child: Image.network(
                            cast['profile_image'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.deepNight,
                        ),
                ),
                const SizedBox(width: AppTheme.space4),

                // 캐스트 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cast['stage_name'] ?? '알 수 없음',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        '마지막 메시지가 없습니다',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnDarkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 읽지 않은 메시지 수 (예시)
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: AppTheme.space2,
                //     vertical: AppTheme.space1,
                //   ),
                //   decoration: BoxDecoration(
                //     color: AppColors.snowPure,
                //     borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                //   ),
                //   child: Text(
                //     '3',
                //     style: AppTypography.caption.copyWith(
                //       color: AppColors.deepNight,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
