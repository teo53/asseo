import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 구독 티어 선택 모달
class SubscriptionTierModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> cast;

  const SubscriptionTierModal({super.key, required this.cast});

  @override
  ConsumerState<SubscriptionTierModal> createState() => _SubscriptionTierModalState();
}

class _SubscriptionTierModalState extends ConsumerState<SubscriptionTierModal> {
  String? _selectedTier;

  static const List<Map<String, dynamic>> _tiers = [
    {
      'code': 'STANDARD',
      'name': '스탠다드',
      'price': 5900,
      'description': '프라이빗 메시지 열람',
      'features': ['전용 메시지 열람', '특별 이모지 사용'],
      'color': Color(0xFF6B7280),
    },
    {
      'code': 'PREMIUM',
      'name': '프리미엄',
      'price': 9900,
      'description': '답장 가능 + 추가 혜택',
      'features': ['스탠다드 혜택 포함', '메시지에 답장 가능', '프리미엄 배지'],
      'recommended': true,
      'color': Color(0xFF8B5CF6),
    },
    {
      'code': 'VIP',
      'name': 'VIP',
      'price': 19900,
      'description': '독점 콘텐츠 + 모든 혜택',
      'features': ['프리미엄 혜택 포함', '독점 콘텐츠 접근', 'VIP 전용 이벤트', '월간 특별 선물'],
      'color': Color(0xFFEAB308),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final isSubscribed = isDemoMode
        ? ref.watch(demoSubscriptionsProvider).contains(widget.cast['id'])
        : false;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            const SizedBox(height: AppTheme.space2),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.space6),

            // 캐스트 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
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
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.textOnDarkMuted,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cast['stage_name'] ?? '알 수 없음',
                          style: AppTypography.heading3,
                        ),
                        if (widget.cast['team'] != null)
                          Text(
                            widget.cast['team']['name'] ?? '',
                            style: AppTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (isSubscribed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space3,
                        vertical: AppTheme.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccess.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        '구독 중',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space6),

            if (isSubscribed) ...[
              // 이미 구독 중인 경우
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppColors.statusSuccess.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.statusSuccess),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Text(
                          '이미 구독 중입니다. 채팅방에서 메시지를 확인하세요!',
                          style: AppTypography.body.copyWith(
                            color: AppColors.statusSuccess,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/chat/${widget.cast['id']}');
                    },
                    child: const Text('채팅방 가기'),
                  ),
                ),
              ),
            ] else ...[
              // 구독 티어 선택
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
                child: Column(
                  children: _tiers.map((tier) {
                    final isSelected = _selectedTier == tier['code'];
                    final isRecommended = tier['recommended'] == true;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedTier = tier['code']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.space3),
                        padding: const EdgeInsets.all(AppTheme.space4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (tier['color'] as Color).withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: isSelected
                                ? tier['color'] as Color
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // 라디오 버튼
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? tier['color'] as Color
                                          : Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: tier['color'] as Color,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppTheme.space3),
                                Text(
                                  tier['name'] as String,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? tier['color'] as Color
                                        : AppColors.textOnDark,
                                  ),
                                ),
                                if (isRecommended) ...[
                                  const SizedBox(width: AppTheme.space2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space2,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tier['color'] as Color,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      '추천',
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Text(
                                  '${formatter.format(tier['price'])}원/월',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              tier['description'] as String,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textOnDarkSecondary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: AppTheme.space3),
                              ...(tier['features'] as List<String>).map((feature) => Padding(
                                padding: const EdgeInsets.only(bottom: AppTheme.space1),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 14,
                                      color: tier['color'] as Color,
                                    ),
                                    const SizedBox(width: AppTheme.space2),
                                    Text(
                                      feature,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textOnDarkSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 구독 버튼
              Padding(
                padding: const EdgeInsets.all(AppTheme.space4),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedTier != null ? () => _subscribe() : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                      disabledBackgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    child: Text(
                      _selectedTier != null
                          ? '${_getSelectedTierName()} 구독하기'
                          : '구독 티어를 선택하세요',
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppTheme.space2),
          ],
        ),
      ),
    );
  }

  String _getSelectedTierName() {
    final tier = _tiers.firstWhere(
      (t) => t['code'] == _selectedTier,
      orElse: () => {'name': ''},
    );
    return tier['name'] as String;
  }

  void _subscribe() {
    if (_selectedTier == null) return;

    if (isDemoMode) {
      // 데모 모드: 로컬 상태에 구독 추가
      ref.read(demoSubscriptionsProvider.notifier).subscribe(widget.cast['id']);

      Navigator.pop(context);

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.cast['stage_name']}님을 구독했습니다!'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          action: SnackBarAction(
            label: '채팅방 가기',
            textColor: Colors.white,
            onPressed: () {
              context.push('/chat/${widget.cast['id']}');
            },
          ),
        ),
      );
    } else {
      // 실제 모드: 결제 플로우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('실제 결제 연동이 필요합니다')),
      );
    }
  }
}
