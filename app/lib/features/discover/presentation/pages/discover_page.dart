import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
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
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _casts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCasts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCasts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final service = ref.read(supabaseServiceProvider);
      final casts = await service.getCasts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (mounted) {
        setState(() {
          _casts = casts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '캐스트를 불러오는데 실패했습니다';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_searchQuery != value) {
        setState(() {
          _searchQuery = value;
        });
        _loadCasts();
      }
    });
  }

  void _showSubscriptionModal(Map<String, dynamic> cast) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SubscriptionBottomSheet(
        cast: cast,
        onSubscribe: (tierCode) async {
          Navigator.pop(context);
          await _handleSubscribe(cast, tierCode);
        },
      ),
    );
  }

  Future<void> _handleSubscribe(Map<String, dynamic> cast, String tierCode) async {
    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUserId;

      if (userId == null) {
        _showSnackBar('로그인이 필요합니다', isError: true);
        return;
      }

      final service = ref.read(supabaseServiceProvider);
      await service.createSubscription(
        fanId: userId,
        castId: cast['id'],
        tierCode: tierCode,
      );

      _showSnackBar('${cast['stage_name']}님을 구독했습니다! 🎉', isError: false);

      // 채팅방으로 이동
      if (mounted) {
        context.push('/chat/${cast['id']}');
      }
    } catch (e) {
      _showSnackBar('구독에 실패했습니다', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.statusError : AppColors.statusSuccess,
              size: 20,
            ),
            const SizedBox(width: AppTheme.space2),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.deepShadow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      children: [
                        Text(
                          '탐색',
                          style: AppTypography.heading1,
                        ),
                        const Spacer(),
                        // 필터 버튼
                        IconButton(
                          onPressed: () {
                            // TODO: 필터 모달
                          },
                          icon: const Icon(Icons.tune),
                        ),
                      ],
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
                        decoration: InputDecoration(
                          hintText: '캐스트 검색...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textOnDarkMuted,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 20,
                                    color: AppColors.textOnDarkMuted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space4,
                            vertical: AppTheme.space3,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),

              // 캐스트 그리드
              Expanded(
                child: _buildCastGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastGrid() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.space4),
            Text('캐스트를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.statusError.withOpacity(0.7),
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              _errorMessage!,
              style: AppTypography.body.copyWith(
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            OutlinedButton.icon(
              onPressed: _loadCasts,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_casts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                size: 64,
                color: AppColors.textOnDarkMuted.withOpacity(0.5),
              ),
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
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space2),
              Text(
                '다른 검색어로 시도해보세요',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textOnDarkMuted.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCasts,
      color: AppColors.snowPure,
      backgroundColor: AppColors.deepShadow,
      child: GridView.builder(
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
        itemCount: _casts.length,
        itemBuilder: (context, index) {
          final cast = _casts[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 200)),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _CastGridItem(
              cast: cast,
              onTap: () => context.push('/chat/${cast['id']}'),
              onSubscribe: () => _showSubscriptionModal(cast),
            ),
          );
        },
      ),
    );
  }
}

/// 캐스트 그리드 아이템
class _CastGridItem extends StatelessWidget {
  final Map<String, dynamic> cast;
  final VoidCallback onTap;
  final VoidCallback onSubscribe;

  const _CastGridItem({
    required this.cast,
    required this.onTap,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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

            // 팀 & 구독자 수
            if (cast['team'] != null)
              Text(
                cast['team']['name'] ?? '',
                style: AppTypography.caption,
              ),

            Text(
              '${cast['subscriber_count'] ?? 0} 구독',
              style: AppTypography.caption.copyWith(
                color: AppColors.textOnDarkMuted.withOpacity(0.7),
              ),
            ),

            const Spacer(),

            // 구독 버튼
            Padding(
              padding: const EdgeInsets.all(AppTheme.space3),
              child: GestureDetector(
                onTap: onSubscribe,
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
            ),
          ],
        ),
      ),
    );
  }
}

/// 구독 티어 선택 바텀시트
class _SubscriptionBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> cast;
  final Function(String tierCode) onSubscribe;

  const _SubscriptionBottomSheet({
    required this.cast,
    required this.onSubscribe,
  });

  @override
  ConsumerState<_SubscriptionBottomSheet> createState() => _SubscriptionBottomSheetState();
}

class _SubscriptionBottomSheetState extends ConsumerState<_SubscriptionBottomSheet> {
  String? _selectedTier;
  List<Map<String, dynamic>> _tiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    try {
      final service = ref.read(supabaseServiceProvider);
      final tiers = await service.getSubscriptionTiers();

      if (mounted) {
        setState(() {
          _tiers = tiers;
          _isLoading = false;
          if (tiers.isNotEmpty) {
            _selectedTier = tiers[0]['code'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppTheme.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: AppTheme.space3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppTheme.space4),

          // 캐스트 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.gradientSnowPearl,
                  ),
                  child: widget.cast['profile_image'] != null
                      ? ClipOval(
                          child: Image.network(
                            widget.cast['profile_image'],
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 28,
                          color: AppColors.deepNight,
                        ),
                ),
                const SizedBox(width: AppTheme.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cast['stage_name'] ?? '',
                        style: AppTypography.heading3,
                      ),
                      Text(
                        '구독 티어를 선택해주세요',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space6),

          // 티어 목록
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppTheme.space6),
              child: CircularProgressIndicator(),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
              child: Column(
                children: _tiers.map((tier) => _TierCard(
                  tier: tier,
                  isSelected: _selectedTier == tier['code'],
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTier = tier['code'];
                    });
                  },
                )).toList(),
              ),
            ),

          const SizedBox(height: AppTheme.space6),

          // 구독 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTier != null
                    ? () => widget.onSubscribe(_selectedTier!)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                ),
                child: Text(
                  _selectedTier != null
                      ? '${_getTierPrice(_selectedTier!)}원/월 구독하기'
                      : '구독하기',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTierPrice(String tierCode) {
    final tier = _tiers.firstWhere(
      (t) => t['code'] == tierCode,
      orElse: () => {},
    );
    final price = tier['price_monthly'] ?? 0;
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

/// 티어 카드
class _TierCard extends StatelessWidget {
  final Map<String, dynamic> tier;
  final bool isSelected;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppTheme.space3),
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: isSelected
                ? AppColors.snowPure.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 라디오 버튼
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.snowPure
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.snowPure,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTheme.space4),

            // 티어 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tier['name'] ?? '',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '답장 ${tier['reply_tokens_per_message'] ?? 0}회 · 기본 ${tier['base_char_limit'] ?? 0}자',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            // 가격
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩${_formatPrice(tier['price_monthly'] ?? 0)}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '/월',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
