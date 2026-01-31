import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 홈 페이지
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // 헤더
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space6),
                  child: Row(
                    children: [
                      Text(
                        'MOE\nBACKSTAGE',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w300,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      // 알림 버튼 (뱃지 포함)
                      _NotificationButton(),
                    ],
                  ),
                ),
              ),

              // 인기 캐스트 섹션
              SliverToBoxAdapter(
                child: _PopularCastsSection(),
              ),

              // 내 구독 섹션
              SliverToBoxAdapter(
                child: _MySubscriptionsSection(),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.space10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인기 캐스트 섹션
class _PopularCastsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
          child: Text(
            '인기 캐스트',
            style: AppTypography.heading3,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        SizedBox(
          height: 180,
          child: FutureBuilder(
            future: service.getPopularCasts(limit: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final casts = snapshot.data ?? [];

              if (casts.isEmpty) {
                return Center(
                  child: Text(
                    '아직 캐스트가 없습니다',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
                itemCount: casts.length,
                itemBuilder: (context, index) {
                  final cast = casts[index];
                  return _CastCard(cast: cast);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 캐스트 카드
class _CastCard extends StatelessWidget {
  final Map<String, dynamic> cast;

  const _CastCard({required this.cast});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 캐스트 프로필로 이동
        context.push('/cast/${cast['id']}');
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: AppTheme.space4),
        decoration: BoxDecoration(
          color: AppColors.deepShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.space4),
            // 프로필 아이콘
            Container(
              width: 80,
              height: 80,
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
                size: 40,
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppTheme.space3),
            // 이름
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
              child: Text(
                cast['stage_name'] ?? '알 수 없음',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 구독자 수
            Text(
              '${cast['subscriber_count'] ?? 0} 구독',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}

/// 내 구독 섹션
class _MySubscriptionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final service = ref.watch(supabaseServiceProvider);
    final subscribedCastIds = isDemoMode
        ? ref.watch(demoSubscriptionsProvider)
        : null;
    final unreadCounts = ref.watch(demoUnreadCountProvider);

    final canLoad = isDemoMode || currentUser != null;
    final userId = isDemoMode ? 'demo-user' : currentUser?.id ?? '';

    return Padding(
      padding: const EdgeInsets.all(AppTheme.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '내 구독',
                style: AppTypography.heading3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/chat'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          if (!canLoad)
            const Center(child: CircularProgressIndicator())
          else
            FutureBuilder(
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
                  return _EmptySubscriptionState();
                }

                // 최대 3개까지만 미리보기로 표시
                final previewList = subscriptions.take(3).toList();

                return Column(
                  children: previewList.map((subscription) {
                    final cast = subscription['cast'];
                    final castId = cast['id'] as String;
                    final unreadCount = isDemoMode
                        ? unreadCounts[castId] ?? 0
                        : subscription['unread_count'] ?? 0;

                    return _SubscriptionPreviewItem(
                      cast: cast,
                      subscription: subscription,
                      unreadCount: unreadCount,
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// 빈 구독 상태
class _EmptySubscriptionState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_outline,
            size: 48,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '아직 구독한 캐스트가 없습니다',
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            '탐색에서 마음에 드는 캐스트를 찾아보세요',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppTheme.space4),
          ElevatedButton(
            onPressed: () => context.go('/discover'),
            child: const Text('캐스트 탐색하기'),
          ),
        ],
      ),
    );
  }
}

/// 구독 미리보기 아이템
class _SubscriptionPreviewItem extends StatelessWidget {
  final Map<String, dynamic> cast;
  final Map<String, dynamic> subscription;
  final int unreadCount;

  const _SubscriptionPreviewItem({
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
                  width: 48,
                  height: 48,
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
                  ),
                ),
                const SizedBox(width: AppTheme.space3),

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
                      const SizedBox(height: 2),
                      Text(
                        subscription['last_message']?['content'] ?? '새 메시지를 확인하세요',
                        style: AppTypography.bodySmall.copyWith(
                          color: unreadCount > 0
                              ? AppColors.textOnDark
                              : AppColors.textOnDarkMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 읽지 않은 메시지 배지
                if (unreadCount > 0)
                  Container(
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
}

/// 알림 버튼 (읽지 않은 알림 뱃지 포함)
class _NotificationButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(demoUnreadNotificationCountProvider);

    return Stack(
      children: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.statusError,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
