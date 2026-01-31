import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';
import '../widgets/donation_modal.dart';

/// 캐스트 프로필 페이지 (이미지 UI 참고한 전면 개편)
class CastProfilePage extends ConsumerStatefulWidget {
  final String castId;

  const CastProfilePage({super.key, required this.castId});

  @override
  ConsumerState<CastProfilePage> createState() => _CastProfilePageState();
}

class _CastProfilePageState extends ConsumerState<CastProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(supabaseServiceProvider);
    final isSubscribed = isDemoMode
        ? ref.watch(demoSubscriptionsProvider).contains(widget.castId)
        : false;

    return Scaffold(
      body: FutureBuilder(
        future: service.getCast(widget.castId),
        builder: (context, snapshot) {
          final cast = snapshot.data;

          return CustomScrollView(
            slivers: [
              // 프로필 헤더 (이미지 + 기본 정보)
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  cast: cast,
                  isSubscribed: isSubscribed,
                  castId: widget.castId,
                ),
              ),

              // 퀵 액션 버튼들
              SliverToBoxAdapter(
                child: _QuickActions(
                  cast: cast,
                  castId: widget.castId,
                  isSubscribed: isSubscribed,
                ),
              ),

              // 서포터 랭킹 (내 순위)
              SliverToBoxAdapter(
                child: _SupporterRank(),
              ),

              // 최신 드롭 (굿즈)
              SliverToBoxAdapter(
                child: _LatestDrops(),
              ),

              // 다가오는 이벤트
              SliverToBoxAdapter(
                child: _UpcomingEvents(),
              ),

              // 탭 (하이라이트, 공지사항, 오타 레터)
              SliverToBoxAdapter(
                child: _ContentTabs(tabController: _tabController),
              ),

              // 탭 콘텐츠
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _HighlightsTab(castId: widget.castId),
                    _NoticesTab(),
                    _LettersTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 프로필 헤더
class _ProfileHeader extends ConsumerWidget {
  final Map<String, dynamic>? cast;
  final bool isSubscribed;
  final String castId;

  const _ProfileHeader({
    required this.cast,
    required this.isSubscribed,
    required this.castId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 배경 이미지
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.deepSlate,
                AppColors.deepVoid,
              ],
            ),
          ),
          child: cast?['cover_image'] != null
              ? ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.network(
                    cast!['cover_image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : null,
        ),

        // 상단 네비게이션
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.3),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 프로필 정보
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 + 인증 배지
                Row(
                  children: [
                    Text(
                      cast?['stage_name'] ?? '로딩 중...',
                      style: AppTypography.heading1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.statusInfo,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.space1),

                // 그룹명
                Text(
                  cast?['group_name'] ?? 'Underground Idol',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),

                const SizedBox(height: AppTheme.space3),

                // 통계
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.trending_up,
                      label: '주간랭킹: ${cast?['weekly_rank'] ?? 12}위',
                      color: AppColors.statusSuccess,
                    ),
                    const SizedBox(width: AppTheme.space3),
                    _StatBadge(
                      icon: Icons.people_outline,
                      label: '팬 ${_formatNumber(cast?['subscriber_count'] ?? 0)}',
                      color: AppColors.textOnDarkMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int num) {
    if (num >= 10000) {
      return '${(num / 10000).toStringAsFixed(1)}만';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}천';
    }
    return num.toString();
  }
}

/// 통계 배지
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTheme.space1),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 퀵 액션 버튼들
class _QuickActions extends ConsumerWidget {
  final Map<String, dynamic>? cast;
  final String castId;
  final bool isSubscribed;

  const _QuickActions({
    required this.cast,
    required this.castId,
    required this.isSubscribed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // 스토리 아이콘들 (상단)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StoryCircle(label: "Today's OOTD", isNew: true),
              _StoryCircle(label: 'Rehearsal', isNew: false),
              _StoryCircle(label: 'Q&A', isNew: false),
              _StoryCircle(label: 'V-log', isNew: false),
            ],
          ),

          const SizedBox(height: AppTheme.space4),
          Divider(color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: AppTheme.space4),

          // 액션 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'DM',
                onTap: () {
                  if (isSubscribed) {
                    context.push('/chat/$castId');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('구독 후 DM을 이용할 수 있습니다')),
                    );
                  }
                },
              ),
              _ActionButton(
                icon: Icons.currency_yen,
                label: '후원',
                isPrimary: true,
                onTap: () => _showDonationModal(context, ref, cast, castId),
              ),
              _ActionButton(
                icon: Icons.card_giftcard,
                label: '굿즈',
                onTap: () {},
              ),
              _ActionButton(
                icon: Icons.event,
                label: '오프회',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDonationModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? cast,
    String castId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DonationModal(
        cast: cast,
        castId: castId,
      ),
    );
  }
}

/// 스토리 원형 버튼
class _StoryCircle extends StatelessWidget {
  final String label;
  final bool isNew;

  const _StoryCircle({
    required this.label,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isNew ? AppColors.snowPure : AppColors.deepSlate,
            border: isNew
                ? null
                : Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(
            _getIconForLabel(label),
            color: isNew ? AppColors.deepNight : AppColors.textOnDarkMuted,
          ),
        ),
        const SizedBox(height: AppTheme.space2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Today's OOTD":
        return Icons.checkroom;
      case 'Rehearsal':
        return Icons.videocam_outlined;
      case 'Q&A':
        return Icons.question_answer_outlined;
      case 'V-log':
        return Icons.camera_alt_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

/// 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isPrimary ? const Color(0xFF4ECDC4) : AppColors.deepSlate,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textOnDarkSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 서포터 랭킹
class _SupporterRank extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space2),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 서포터 랭킹: 12위',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Gold Member · 상위 5%',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (v) {},
            activeColor: const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }
}

/// 최신 굿즈
class _LatestDrops extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('굿즈', style: AppTypography.heading3),
              TextButton(
                onPressed: () {},
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _GoodsItem(
                  title: '1st Anniversary T-shirt',
                  price: '35,000 KRW',
                  isSoldOut: true,
                ),
                _GoodsItem(
                  title: 'Winter Photo Set A',
                  price: '12,000 KRW',
                  isNew: true,
                ),
                _GoodsItem(
                  title: 'Gold Membership Card',
                  price: '5,000 KRW',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 굿즈 아이템
class _GoodsItem extends StatelessWidget {
  final String title;
  final String price;
  final bool isSoldOut;
  final bool isNew;

  const _GoodsItem({
    required this.title,
    required this.price,
    this.isSoldOut = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: AppTheme.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.deepSlate,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Icon(
                    Icons.checkroom,
                    size: 40,
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ),
              if (isSoldOut)
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
                      'SOLD OUT',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (isNew)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'NEW',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            price,
            style: AppTypography.caption.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 다가오는 이벤트
class _UpcomingEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('다가오는 이벤트', style: AppTypography.heading3),
          const SizedBox(height: AppTheme.space3),
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: AppColors.deepShadow,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.deepSlate,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.event,
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'OFFLINE',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space2),
                          Text(
                            '12월 24일 (토)',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starlight Christmas Live',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '홍대 롤링홀',
                        style: AppTypography.caption,
                      ),
                    ],
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

/// 콘텐츠 탭 바
class _ContentTabs extends StatelessWidget {
  final TabController tabController;

  const _ContentTabs({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.space4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.snowPure,
        indicatorWeight: 2,
        labelColor: AppColors.snowPure,
        unselectedLabelColor: AppColors.textOnDarkMuted,
        tabs: const [
          Tab(text: '하이라이트'),
          Tab(text: '공지사항'),
          Tab(text: '오타 레터'),
        ],
      ),
    );
  }
}

/// 하이라이트 탭
class _HighlightsTab extends StatelessWidget {
  final String castId;

  const _HighlightsTab({required this.castId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.space4),
      children: [
        _PostCard(
          authorName: '리나 (Rina)',
          timeAgo: '2시간 전',
          content: '오늘 라이브 와주신 분들 너무 감사해요! 💕\n덕분에 정말 행복한 하루였어요. 다음 주 오프회에서 또 만나요!\n#Starlight #Rina #OOTD',
          hasImage: true,
          likes: 1200,
          comments: 86,
        ),
        _PostCard(
          authorName: '리나 (Rina)',
          timeAgo: '어제',
          content: '연습실에서 셀카 한 장 📸\n새로운 안무 기대해주세요!',
          hasImage: false,
          likes: 890,
          comments: 42,
        ),
      ],
    );
  }
}

/// 포스트 카드
class _PostCard extends StatelessWidget {
  final String authorName;
  final String timeAgo;
  final String content;
  final bool hasImage;
  final int likes;
  final int comments;

  const _PostCard({
    required this.authorName,
    required this.timeAgo,
    required this.content,
    this.hasImage = false,
    required this.likes,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.profileBackground,
                  border: Border.all(
                    color: AppColors.profileBorder,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textOnDarkMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space3),

          // 콘텐츠
          Text(content, style: AppTypography.body),

          if (hasImage) ...[
            const SizedBox(height: AppTheme.space3),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.deepSlate,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: AppColors.textOnDarkMuted,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.space3),

          // 액션 바
          Row(
            children: [
              Icon(Icons.favorite, color: AppColors.statusError, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatNumber(likes),
                style: AppTypography.caption,
              ),
              const SizedBox(width: AppTheme.space4),
              Icon(Icons.chat_bubble_outline,
                  color: AppColors.textOnDarkMuted, size: 18),
              const SizedBox(width: 4),
              Text(
                comments.toString(),
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    }
    return num.toString();
  }
}

/// 공지사항 탭
class _NoticesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '등록된 공지사항이 없습니다',
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 오타 레터 탭
class _LettersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mail_outline,
            size: 48,
            color: AppColors.textOnDarkMuted,
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            '구독자 전용 콘텐츠입니다',
            style: AppTypography.body.copyWith(
              color: AppColors.textOnDarkMuted,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          ElevatedButton(
            onPressed: () {},
            child: const Text('구독하고 확인하기'),
          ),
        ],
      ),
    );
  }
}
