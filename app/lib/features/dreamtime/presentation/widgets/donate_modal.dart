import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/dt_models.dart';
import '../../services/dreamtime_service.dart';

/// 후원 모달
class DonateModal extends ConsumerStatefulWidget {
  final String creatorId;
  final String creatorName;
  final String? creatorImage;
  final String contextType;
  final String contextId;

  const DonateModal({
    super.key,
    required this.creatorId,
    required this.creatorName,
    this.creatorImage,
    required this.contextType,
    required this.contextId,
  });

  @override
  ConsumerState<DonateModal> createState() => _DonateModalState();
}

class _DonateModalState extends ConsumerState<DonateModal> {
  int _selectedAmount = 0;
  int _customAmount = 0;
  String _message = '';
  bool _isAnonymous = false;
  bool _isProcessing = false;
  String? _error;

  final _customController = TextEditingController();
  final _messageController = TextEditingController();

  // 프리셋 금액
  static const List<int> _presetAmounts = [
    100,
    500,
    1000,
    5000,
    10000,
    50000,
  ];

  @override
  void dispose() {
    _customController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _customAmount = 0;
      _customController.clear();
      _error = null;
    });
  }

  void _setCustomAmount(String value) {
    final amount = int.tryParse(value.replaceAll(',', '')) ?? 0;
    setState(() {
      _customAmount = amount;
      _selectedAmount = 0;
      _error = null;
    });
  }

  Future<void> _processDonation() async {
    final amount = _selectedAmount > 0 ? _selectedAmount : _customAmount;
    if (amount < 1) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final service = ref.read(dreamTimeServiceProvider);

      await service.commitDonation(
        toCreatorId: widget.creatorId,
        contextType: widget.contextType,
        contextId: widget.contextId,
        message: _message.isNotEmpty ? _message : null,
        isAnonymous: _isAnonymous,
        dtAmount: amount,
      );

      // 지갑 데이터 새로고침
      ref.invalidate(walletSummaryProvider);
      ref.invalidate(ledgerEntriesProvider(50));
      ref.invalidate(sentDonationsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.creatorName}님에게 ${NumberFormat('#,###').format(amount)} DT를 후원했습니다!',
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } on DonationException catch (e) {
      setState(() {
        _error = e.reason ?? e.message;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final currentAmount = _selectedAmount > 0 ? _selectedAmount : _customAmount;
    final walletAsync = ref.watch(walletSummaryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.deepAsh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space6),

              // Creator info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.creatorImage != null
                        ? NetworkImage(widget.creatorImage!)
                        : null,
                    backgroundColor: AppColors.deepShadow,
                    child: widget.creatorImage == null
                        ? const Icon(Icons.person, color: AppColors.textOnDarkMuted)
                        : null,
                  ),
                  const SizedBox(width: AppTheme.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.creatorName,
                          style: AppTypography.heading3,
                        ),
                        const Text(
                          '에게 후원하기',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space6),

              // Current balance
              walletAsync.maybeWhen(
                data: (wallet) => Container(
                  padding: const EdgeInsets.all(AppTheme.space3),
                  decoration: BoxDecoration(
                    color: AppColors.deepShadow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.diamond_outlined,
                        size: 16,
                        color: AppColors.textOnDarkMuted,
                      ),
                      const SizedBox(width: AppTheme.space2),
                      Text(
                        '보유: ${formatter.format(wallet.totalBalance)} DT',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppTheme.space4),

              // Preset amounts grid
              Wrap(
                spacing: AppTheme.space2,
                runSpacing: AppTheme.space2,
                children: _presetAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
                  return _AmountChip(
                    amount: amount,
                    isSelected: isSelected,
                    onTap: () => _selectAmount(amount),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppTheme.space4),

              // Custom amount input
              TextField(
                controller: _customController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '직접 입력',
                  suffixText: 'DT',
                ),
                onChanged: _setCustomAmount,
              ),
              const SizedBox(height: AppTheme.space4),

              // Message input
              TextField(
                controller: _messageController,
                maxLength: 100,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '응원 메시지 (선택)',
                  counterText: '',
                ),
                onChanged: (value) => setState(() => _message = value),
              ),
              const SizedBox(height: AppTheme.space4),

              // Anonymous toggle
              InkWell(
                onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  decoration: BoxDecoration(
                    color: AppColors.deepShadow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAnonymous
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textOnDarkSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '익명으로 후원',
                              style: AppTypography.body,
                            ),
                            Text(
                              _isAnonymous
                                  ? '닉네임이 표시되지 않습니다'
                                  : '닉네임이 크리에이터에게 표시됩니다',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textOnDarkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (value) => setState(() => _isAnonymous = value),
                        activeColor: AppColors.snowPure,
                      ),
                    ],
                  ),
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: AppTheme.space4),
                Container(
                  padding: const EdgeInsets.all(AppTheme.space3),
                  decoration: BoxDecoration(
                    color: AppColors.statusError.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.statusError,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space2),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.statusError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.space6),

              // Confirm button
              ElevatedButton(
                onPressed: currentAmount >= 1 && !_isProcessing
                    ? _processDonation
                    : null,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        currentAmount >= 1
                            ? '${formatter.format(currentAmount)} DT 후원하기'
                            : '금액을 선택하세요',
                      ),
              ),

              const SizedBox(height: AppTheme.space2),

              // Info text
              Text(
                '• 후원 메시지에 연락처, SNS 계정 등 개인정보를 포함할 수 없습니다\n• 후원 후 취소는 불가능합니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textOnDarkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final int amount;
  final bool isSelected;
  final VoidCallback onTap;

  const _AmountChip({
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Material(
      color: isSelected ? AppColors.snowPure : AppColors.deepShadow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space3,
          ),
          child: Text(
            '${formatter.format(amount)} DT',
            style: AppTypography.body.copyWith(
              color: isSelected ? AppColors.deepNight : AppColors.snowPure,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
