import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';
import '../widgets/subscription_tier_modal.dart';

/// 탐색 페이지
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '탐색',
                      style: AppTypography.heading1,
                    ),
                    const SizedBox(height: AppTheme.space4),

                    // 검색바
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.body,
                        decoration: const InputDecoration(
                          hintText: '캐스트 검색...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textOnDarkMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.space4,
                            vertical: AppTheme.space3,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 캐스트 그리드
              Expanded(
                child: FutureBuilder(
                  future: service.getCasts(
                    search: _searchQuery.isNotEmpty ? _searchQuery : null,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final casts = snapshot.data ?? [];

                    if (casts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textOnDarkMuted,
                            ),
                            const SizedBox(height: AppTheme.space4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? '검색 결과가 없습니다'
                                  : '등록된 캐스트가 없습니다',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textOnDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space6,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppTheme.space4,
                        mainAxisSpacing: AppTheme.space4,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: casts.length,
                      itemBuilder: (context, index) {
                        final cast = casts[index];
                        return _CastGridItem(cast: cast);
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

/// 캐스트 그리드 아이템
class _CastGridItem extends ConsumerWidget {
  final Map<String, dynamic> cast;

  const _CastGridItem({required this.cast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed = isDemoMode
        ? ref.watch(demoSubscriptionsProvider).contains(cast['id'])
        : false;

    return GestureDetector(
      onTap: () => _showSubscriptionModal(context, cast),
      child: Container(
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
            const SizedBox(height: AppTheme.space5),
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3),
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

            // 팀
            if (cast['team'] != null)
              Text(
                cast['team']['name'] ?? '',
                style: AppTypography.caption,
              ),

            const Spacer(),

            // 구독 버튼
            Padding(
              padding: const EdgeInsets.all(AppTheme.space3),
              child: GestureDetector(
                onTap: () => _showSubscriptionModal(context, cast),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space2,
                  ),
                  decoration: BoxDecoration(
                    color: isSubscribed
                        ? AppColors.statusSuccess.withOpacity(0.2)
                        : AppColors.snowPure,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: isSubscribed
                        ? Border.all(color: AppColors.statusSuccess.withOpacity(0.5))
                        : null,
                  ),
                  child: Text(
                    isSubscribed ? '구독 중' : '구독하기',
                    style: AppTypography.bodySmall.copyWith(
                      color: isSubscribed ? AppColors.statusSuccess : AppColors.deepNight,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionModal(BuildContext context, Map<String, dynamic> cast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionTierModal(cast: cast),
    );
  }
}
