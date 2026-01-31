import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/demo_providers.dart';
import '../../../../main.dart';

/// 후원 모달
class DonationModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? cast;
  final String castId;

  const DonationModal({
    super.key,
    required this.cast,
    required this.castId,
  });

  @override
  ConsumerState<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends ConsumerState<DonationModal> {
  int _selectedAmount = 0;
  final _customController = TextEditingController();
  bool _isCustom = false;
  String _message = '';

  final List<int> _presetAmounts = [100, 300, 500, 1000, 3000, 5000];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = ref.watch(demoWalletBalanceProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepNight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 드래그 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space6),

              // 헤더
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.cast?['stage_name'] ?? '캐스트'}에게 후원하기',
                          style: AppTypography.heading3,
                        ),
                        Text(
                          '후원하면 하트가 표시됩니다',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space6),

              // 잔액 표시
              Container(
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppColors.deepShadow,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: AppColors.snowPearl,
                        ),
                        const SizedBox(width: AppTheme.space2),
                        Text(
                          '내 DreamTime',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                    Text(
                      '$walletBalance DT',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.snowPure,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.space6),

              // 금액 선택
              Text(
                '후원 금액 선택',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space3),

              // 프리셋 금액 버튼
              Wrap(
                spacing: AppTheme.space2,
                runSpacing: AppTheme.space2,
                children: _presetAmounts.map((amount) {
                  final isSelected = !_isCustom && _selectedAmount == amount;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAmount = amount;
                        _isCustom = false;
                        _customController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space4,
                        vertical: AppTheme.space3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.snowPure : AppColors.deepShadow,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: isSelected
                                ? AppColors.deepNight
                                : AppColors.textOnDarkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$amount',
                            style: AppTypography.body.copyWith(
                              color: isSelected
                                  ? AppColors.deepNight
                                  : AppColors.textOnDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppTheme.space3),

              // 직접 입력
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: '직접 입력',
                        prefixIcon: const Icon(Icons.auto_awesome, size: 18),
                        suffixText: 'DT',
                        filled: true,
                        fillColor: _isCustom
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                            color: _isCustom
                                ? AppColors.snowPure
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                            color: _isCustom
                                ? AppColors.snowPure
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isCustom = value.isNotEmpty;
                          _selectedAmount = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.space6),

              // 메시지 입력
              Text(
                '응원 메시지 (선택)',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space3),
              TextField(
                style: AppTypography.body,
                maxLines: 2,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: '응원 메시지를 남겨주세요 💕',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                onChanged: (value) {
                  _message = value;
                },
              ),

              const SizedBox(height: AppTheme.space6),

              // 후원 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAmount > 0 && _selectedAmount <= walletBalance
                      ? () => _donate(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.space4),
                    backgroundColor: const Color(0xFF4ECDC4),
                    disabledBackgroundColor: AppColors.deepSlate,
                  ),
                  child: Text(
                    _selectedAmount > 0
                        ? '$_selectedAmount DT 후원하기'
                        : '금액을 선택해주세요',
                    style: AppTypography.button.copyWith(
                      color: _selectedAmount > 0 && _selectedAmount <= walletBalance
                          ? Colors.white
                          : AppColors.textOnDarkMuted,
                    ),
                  ),
                ),
              ),

              if (_selectedAmount > walletBalance && _selectedAmount > 0) ...[
                const SizedBox(height: AppTheme.space2),
                Center(
                  child: Text(
                    '잔액이 부족합니다. DreamTime을 충전해주세요.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.statusError,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.space4),
            ],
          ),
        ),
      ),
    );
  }

  void _donate(BuildContext context) {
    if (isDemoMode) {
      // 잔액 차감
      ref.read(demoWalletBalanceProvider.notifier).spend(_selectedAmount);

      // 거래 내역 추가
      ref.read(demoTransactionsProvider.notifier).addTransaction(
            type: 'donation',
            amount: -_selectedAmount,
            balanceAfter:
                ref.read(demoWalletBalanceProvider) - _selectedAmount,
            description: '${widget.cast?['stage_name'] ?? '캐스트'}에게 후원',
          );

      Navigator.pop(context);

      // 성공 피드백
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$_selectedAmount DT를 후원했습니다!'),
            ],
          ),
          backgroundColor: const Color(0xFF4ECDC4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      );
    }
  }
}

/// 채팅방용 간단 후원 버튼
class QuickDonationButton extends ConsumerWidget {
  final String castId;
  final Map<String, dynamic>? cast;

  const QuickDonationButton({
    super.key,
    required this.castId,
    this.cast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DonationModal(
            cast: cast,
            castId: castId,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space2),
        decoration: BoxDecoration(
          color: const Color(0xFF4ECDC4).withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: const Icon(
          Icons.currency_yen,
          color: Color(0xFF4ECDC4),
          size: 24,
        ),
      ),
    );
  }
}
