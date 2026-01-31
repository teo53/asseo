import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/unoa_logo.dart';

/// 홈 페이지
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Map<String, dynamic>> _popularCasts = [];
  List<Map<String, dynamic>> _mySubscriptions = [];
  bool _isLoadingCasts = true;
  bool _isLoadingSubscriptions = true;
  String? _castsError;
  String? _subscriptionsError;
  int _notificationCount = 0; // TODO: 실제 알림 수로 대체

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadPopularCasts(),
      _loadMySubscriptions(),
    ]);
  }

  Future<void> _loadPopularCasts() async {
    try {
      setState(() {
        _isLoadingCasts = true;
        _castsError = null;
      });

      final service = ref.read(supabaseServiceProvider);
      final casts = await service.getPopularCasts(limit: 10);

      if (mounted) {
        setState(() {
          _popularCasts = casts;
          _isLoadingCasts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _castsError = '캐스트를 불러오는데 실패했습니다';
          _isLoadingCasts = false;
        });
      }
    }
  }

  Future<void> _loadMySubscriptions() async {
    try {
      setState(() {
        _isLoadingSubscriptions = true;
        _subscriptionsError = null;
      });

      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;

      if (userId == null) {
        setState(() {
          _isLoadingSubscriptions = false;
        });
        return;
      }

      final service = ref.read(supabaseServiceProvider);
      final subscriptions = await service.getMySubscriptions(userId);

      if (mounted) {
        setState(() {
          _mySubscriptions = subscriptions;
          _isLoadingSubscriptions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subscriptionsError = '구독 정보를 불러오는데 실패했습니다';
          _isLoadingSubscriptions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.snowPure,
            backgroundColor: AppColors.deepShadow,
            child: CustomScrollView(
              slivers: [
                // 헤더
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space6),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(-20 * (1 - value), 0),
                                child: child,
                              ),
                            );
                          },
                          child: const UnoaLogo.header(),
                        ),
                        const Spacer(),
                        // 알림 버튼
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                // TODO: 알림 센터로 이동
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('알림 센터는 준비 중입니다'),
                                    backgroundColor: AppColors.deepShadow,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_outlined),
                            ),
                            if (_notificationCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    _notificationCount > 9 ? '9+' : '$_notificationCount',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.snowPure,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 인기 캐스트 섹션
                SliverToBoxAdapter(
                  child: _buildPopularCastsSection(),
                ),

                // 내 구독 섹션
                SliverToBoxAdapter(
                  child: _buildMySubscriptionsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.space10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
          child: Row(
            children: [
              Text(
                '인기 캐스트',
                style: AppTypography.heading3,
              ),
              const SizedBox(width: AppTheme.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientSnowPearl,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'HOT',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.deepNight,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        SizedBox(
          height: 180,
          child: _buildPopularCastsList(),
        ),
      ],
    );
  }

  Widget _buildPopularCastsList() {
    if (_isLoadingCasts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_castsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: AppColors.statusError.withOpacity(0.7),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              _castsError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            TextButton(
              onPressed: _loadPopularCasts,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_popularCasts.isEmpty) {
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
      itemCount: _popularCasts.length,
      itemBuilder: (context, index) {
        final cast = _popularCasts[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: child,
              ),
            );
          },
          child: _CastCard(cast: cast),
        );
      },
    );
  }

  Widget _buildMySubscriptionsSection() {
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '전체 보기',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.snowPearl,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.snowPearl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          _buildSubscriptionsContent(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionsContent() {
    if (_isLoadingSubscriptions) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space6),
        decoration: BoxDecoration(
          color: AppColors.deepShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_subscriptionsError != null) {
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
              Icons.error_outline,
              size: 32,
              color: AppColors.statusError.withOpacity(0.7),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              _subscriptionsError!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            TextButton(
              onPressed: _loadMySubscriptions,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_mySubscriptions.isEmpty) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.95 + (0.05 * value),
              child: child,
            ),
          );
        },
        child: Container(
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
              Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  size: 40,
                  color: AppColors.textOnDarkMuted.withOpacity(0.5),
                ),
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
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDarkMuted.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              OutlinedButton.icon(
                onPressed: () => context.go('/discover'),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('캐스트 찾아보기'),
              ),
            ],
          ),
        ),
      );
    }

    // 구독 목록 표시
    return Column(
      children: _mySubscriptions.take(3).map((subscription) {
        final cast = subscription['cast'] ?? {};
        final tier = subscription['tier'] ?? {};

        return GestureDetector(
          onTap: () => context.push('/chat/${cast['id']}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.space3),
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: AppColors.deepShadow,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: Row(
              children: [
                // 프로필 이미지
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientSnowPearl,
                  ),
                  child: cast['profile_image'] != null
                      ? ClipOval(
                          child: Image.network(
                            cast['profile_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              color: AppColors.deepNight,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: AppColors.deepNight,
                        ),
                ),
                const SizedBox(width: AppTheme.space3),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientSnowPearl,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tier['name'] ?? 'Basic',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.deepNight,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space2),
                          Text(
                            '새 메시지 확인하기',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textOnDarkMuted,
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.deepNight,
                        ),
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
