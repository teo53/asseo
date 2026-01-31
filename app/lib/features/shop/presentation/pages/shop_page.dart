import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 샵 페이지 (기존 탐색 페이지 대체)
/// 캐스트 탐색 + 굿즈 샵 + DreamTime 충전
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // 헤더
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('샵', style: AppTypography.heading1),
                          _DreamTimeBalance(),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),

                      // 검색바
                      _SearchBar(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 탭 바
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.snowPure,
                    indicatorWeight: 2,
                    labelColor: AppColors.snowPure,
                    unselectedLabelColor: AppColors.textOnDarkMuted,
                    labelStyle: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: '캐스트'),
                      Tab(text: '굿즈'),
                      Tab(text: 'DreamTime'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _CastsTab(searchQuery: _searchQuery),
                _GoodsTab(),
                _DreamTimeTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// DreamTime 잔액 표시
class _DreamTimeBalance extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(demoWalletBalanceProvider);

    return GestureDetector(
      onTap: () {
        // DreamTime 탭으로 이동 또는 충전 모달 표시
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space3,
          vertical: AppTheme.space2,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.snowPearl,
            ),
            const SizedBox(width: AppTheme.space1),
            Text(
              '$balance',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTheme.space1),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 12,
                color: AppColors.snowPure,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 검색바
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.body,
        decoration: InputDecoration(
          hintText: '캐스트, 굿즈 검색...',
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textOnDarkMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space3,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// 탭바 고정 delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.deepVoid,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}

/// 캐스트 탭
class _CastsTab extends ConsumerWidget {
  final String searchQuery;

  const _CastsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return FutureBuilder(
      future: service.getCasts(
        search: searchQuery.isNotEmpty ? searchQuery : null,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final casts = snapshot.data ?? [];

        if (casts.isEmpty) {
          return _EmptyState(
            icon: Icons.person_search,
            title: searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '등록된 캐스트가 없습니다',
            subtitle: '다른 검색어를 시도해보세요',
          );
        }

        return CustomScrollView(
          slivers: [
            // 카테고리 필터
            SliverToBoxAdapter(
              child: _CategoryFilter(),
            ),

            // 캐스트 리스트
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.space4),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cast = casts[index];
                    return _CastListItem(cast: cast);
                  },
                  childCount: casts.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 카테고리 필터
class _CategoryFilter extends StatefulWidget {
  @override
  State<_CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<_CategoryFilter> {
  int _selectedIndex = 0;
  final List<String> _categories = ['전체', '솔로', '그룹', '신인', '인기'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.space2),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space4,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.snowPure
                    : AppColors.deepShadow,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.snowPure
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.deepNight
                        : AppColors.textOnDarkSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 캐스트 리스트 아이템 (개선된 디자인)
class _CastListItem extends ConsumerWidget {
  final Map<String, dynamic> cast;

  const _CastListItem({required this.cast});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubscribed = isDemoMode
        ? ref.watch(demoSubscriptionsProvider).contains(cast['id'])
        : false;

    return GestureDetector(
      onTap: () => context.push('/cast/${cast['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space3),
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppColors.deepShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // 프로필 아이콘
            Container(
              width: 64,
              height: 64,
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
                size: 32,
                color: AppColors.textOnDarkMuted,
              ),
            ),
            const SizedBox(width: AppTheme.space4),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cast['stage_name'] ?? '알 수 없음',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space2),
                      if (cast['is_verified'] == true)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.statusInfo,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cast['group_name'] ?? 'Solo Artist',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppTheme.space2),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        label: '${cast['subscriber_count'] ?? 0}',
                      ),
                      const SizedBox(width: AppTheme.space2),
                      _StatChip(
                        icon: Icons.favorite_outline,
                        label: '${cast['likes_count'] ?? 0}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 구독 버튼
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space3,
                vertical: AppTheme.space2,
              ),
              decoration: BoxDecoration(
                color: isSubscribed
                    ? AppColors.statusSuccess.withOpacity(0.15)
                    : AppColors.snowPure,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                isSubscribed ? '구독 중' : '구독',
                style: AppTypography.caption.copyWith(
                  color: isSubscribed
                      ? AppColors.statusSuccess
                      : AppColors.deepNight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 통계 칩
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textOnDarkMuted),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textOnDarkMuted,
          ),
        ),
      ],
    );
  }
}

/// 굿즈 탭
class _GoodsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 배너
        SliverToBoxAdapter(
          child: _PromoBanner(),
        ),

        // 카테고리
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('카테고리', style: AppTypography.heading3),
                const SizedBox(height: AppTheme.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CategoryIcon(icon: Icons.checkroom, label: '의류'),
                    _CategoryIcon(icon: Icons.photo_album, label: '포토'),
                    _CategoryIcon(icon: Icons.card_giftcard, label: '굿즈'),
                    _CategoryIcon(icon: Icons.music_note, label: '음반'),
                    _CategoryIcon(icon: Icons.more_horiz, label: '더보기'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 인기 상품
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('인기 상품', style: AppTypography.heading3),
                    TextButton(
                      onPressed: () {},
                      child: const Text('전체보기'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 상품 그리드
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.space3,
              mainAxisSpacing: AppTheme.space3,
              childAspectRatio: 0.7,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _GoodsItem(index: index),
              childCount: 6,
            ),
          ),
        ),

        const SliverToBoxAdapter(
          child: SizedBox(height: AppTheme.space10),
        ),
      ],
    );
  }
}

/// 프로모 배너
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space4),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.local_offer,
              size: 120,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '🎄 크리스마스 특별 세일',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.space1),
                Text(
                  '전 상품 최대 30% 할인',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppTheme.space3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space3,
                    vertical: AppTheme.space1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '쇼핑하러 가기',
                    style: AppTypography.caption.copyWith(
                      color: const Color(0xFF44A08D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 카테고리 아이콘
class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.deepShadow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: AppColors.textOnDarkSecondary),
        ),
        const SizedBox(height: AppTheme.space2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

/// 굿즈 아이템
class _GoodsItem extends StatelessWidget {
  final int index;

  const _GoodsItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': '유키 포토카드 세트', 'price': 8000, 'discount': 20},
      {'name': '리나 아크릴 스탠드', 'price': 15000, 'discount': 0},
      {'name': '하나 슬로건', 'price': 12000, 'discount': 15},
      {'name': '윈터 포토북', 'price': 25000, 'discount': 30},
      {'name': '응원봉 키링', 'price': 5000, 'discount': 0},
      {'name': '시즌 그리팅', 'price': 18000, 'discount': 10},
    ];

    final item = items[index % items.length];
    final hasDiscount = (item['discount'] as int) > 0;
    final discountedPrice = hasDiscount
        ? ((item['price'] as int) * (1 - (item['discount'] as int) / 100)).round()
        : item['price'] as int;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.deepSlate,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image,
                      size: 40,
                      color: AppColors.textOnDarkMuted,
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusError,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${item['discount']}%',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 정보
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (hasDiscount)
                    Text(
                      '${item['price']}원',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textOnDarkMuted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '${discountedPrice}원',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: hasDiscount
                          ? AppColors.statusError
                          : AppColors.textOnDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// DreamTime 탭
class _DreamTimeTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(demoWalletBalanceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 잔액 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space6),
            decoration: BoxDecoration(
              color: AppColors.snowPure,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  '내 DreamTime',
                  style: AppTypography.body.copyWith(
                    color: AppColors.deepNight.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 32,
                      color: AppColors.deepNight,
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Text(
                      '$balance',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 40,
                        color: AppColors.deepNight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' DT',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.deepNight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.space6),

          // 충전 옵션
          Text('충전하기', style: AppTypography.heading3),
          const SizedBox(height: AppTheme.space3),

          _TopupOption(amount: 1000, price: 1100, bonus: 0),
          _TopupOption(amount: 3000, price: 3300, bonus: 100),
          _TopupOption(amount: 5000, price: 5500, bonus: 300, isPopular: true),
          _TopupOption(amount: 10000, price: 11000, bonus: 1000),
          _TopupOption(amount: 30000, price: 33000, bonus: 5000),
          _TopupOption(amount: 50000, price: 55000, bonus: 10000),

          const SizedBox(height: AppTheme.space6),

          // 설명
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: AppColors.deepShadow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DreamTime이란?',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.space2),
                Text(
                  '• 캐스트에게 후원할 때 사용됩니다\n• 프리미엄 콘텐츠 구매에 사용됩니다\n• 굿즈 구매 시 사용할 수 있습니다\n• 구매 후 환불이 불가합니다',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDarkSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 충전 옵션
class _TopupOption extends ConsumerWidget {
  final int amount;
  final int price;
  final int bonus;
  final bool isPopular;

  const _TopupOption({
    required this.amount,
    required this.price,
    required this.bonus,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showTopupConfirm(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space3),
        padding: const EdgeInsets.all(AppTheme.space4),
        decoration: BoxDecoration(
          color: AppColors.deepShadow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isPopular
                ? const Color(0xFF4ECDC4)
                : Colors.white.withOpacity(0.05),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF4ECDC4),
              ),
            ),
            const SizedBox(width: AppTheme.space4),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$amount DT',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (bonus > 0) ...[
                        const SizedBox(width: AppTheme.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccess.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+$bonus 보너스',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.statusSuccess,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (isPopular) ...[
                        const SizedBox(width: AppTheme.space2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'BEST',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '₩${_formatPrice(price)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),

            // 화살표
            const Icon(
              Icons.chevron_right,
              color: AppColors.textOnDarkMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _showTopupConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('DreamTime 충전'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$amount DT를 충전하시겠습니까?'),
            if (bonus > 0) ...[
              const SizedBox(height: 8),
              Text(
                '보너스 +$bonus DT가 함께 지급됩니다!',
                style: TextStyle(color: AppColors.statusSuccess),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '결제 금액: ₩${_formatPrice(price)}',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isDemoMode) {
                ref.read(demoWalletBalanceProvider.notifier).addBalance(amount + bonus);
                ref.read(demoTransactionsProvider.notifier).addTransaction(
                      type: 'topup',
                      amount: amount + bonus,
                      balanceAfter: ref.read(demoWalletBalanceProvider) + amount + bonus,
                      description: 'DreamTime 충전 (보너스 +$bonus)',
                    );
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${amount + bonus} DT가 충전되었습니다!'),
                  backgroundColor: AppColors.statusSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
            ),
            child: const Text('충전하기'),
          ),
        ],
      ),
    );
  }
}

/// 빈 상태
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textOnDarkMuted),
          const SizedBox(height: AppTheme.space4),
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            subtitle,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
