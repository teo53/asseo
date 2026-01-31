import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 채팅 목록 페이지
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final service = ref.watch(supabaseServiceProvider);

    // 데모 모드 또는 실제 유저가 있으면 데이터 로드
    final canLoad = isDemoMode || currentUser != null;

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
                child: !canLoad
                    ? const Center(child: CircularProgressIndicator())
                    : _SubscriptionList(
                        userId: isDemoMode ? 'demo-user' : currentUser!.id,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 구독 목록 위젯
class _SubscriptionList extends ConsumerWidget {
  final String userId;

  const _SubscriptionList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);
    final subscribedCastIds = isDemoMode
        ? ref.watch(demoSubscriptionsProvider)
        : null;
    final unreadCounts = ref.watch(demoUnreadCountProvider);

    return FutureBuilder(
      future: service.getMySubscriptions(
        userId,
        subscribedCastIds: subscribedCastIds,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
            final castId = cast['id'] as String;
            final unreadCount = isDemoMode
                ? unreadCounts[castId] ?? 0
                : subscription['unread_count'] ?? 0;

            return _ChatListItem(
              cast: cast,
              subscription: subscription,
              unreadCount: unreadCount,
            );
          },
        );
      },
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
  final int unreadCount;

  const _ChatListItem({
    required this.cast,
    required this.subscription,
    this.unreadCount = 0,
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
                // 프로필 아이콘
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.profileBackground,
                    border: Border.all(
                      color: AppColors.profileBorder,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.textOnDarkMuted,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.space4),

                // 캐스트 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cast['stage_name'] ?? '알 수 없음',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (subscription['last_message'] != null)
                            Text(
                              _formatRelativeTime(subscription['last_message']['created_at']),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textOnDarkMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space1),
                      Text(
                        subscription['last_message']?['content'] ?? '새로운 메시지를 확인하세요',
                        style: AppTypography.bodySmall.copyWith(
                          color: unreadCount > 0
                              ? AppColors.textOnDark
                              : AppColors.textOnDarkMuted,
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 읽지 않은 메시지 수
                if (unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: AppTheme.space3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space2,
                      vertical: AppTheme.space1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.snowPure,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.deepNight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return '방금';
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      if (diff.inDays < 7) return '${diff.inDays}일 전';
      return '${date.month}/${date.day}';
    } catch (e) {
      return '';
    }
  }
}
