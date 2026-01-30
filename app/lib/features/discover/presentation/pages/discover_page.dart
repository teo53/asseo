import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

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
class _CastGridItem extends StatelessWidget {
  final Map<String, dynamic> cast;

  const _CastGridItem({required this.cast});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: 캐스트 상세 페이지 또는 구독 바텀시트
        context.push('/chat/${cast['id']}');
      },
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
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space2,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSnowPearl,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '구독하기',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.deepNight,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
