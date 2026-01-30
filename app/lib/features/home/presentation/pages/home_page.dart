import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

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
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
                      ),
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
        // 채팅방으로 이동
        context.push('/chat/${cast['id']}');
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
            // 프로필 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradientSnowPearl,
                boxShadow: AppTheme.glowSoft,
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
                      size: 40,
                      color: AppColors.deepNight,
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
                onPressed: () => context.push('/chat'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
