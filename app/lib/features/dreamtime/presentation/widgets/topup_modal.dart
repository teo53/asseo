import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/dt_models.dart';
import '../../services/dreamtime_service.dart';

/// 충전 모달
class TopupModal extends ConsumerStatefulWidget {
  const TopupModal({super.key});

  @override
  ConsumerState<TopupModal> createState() => _TopupModalState();
}

class _TopupModalState extends ConsumerState<TopupModal> {
  int _selectedAmount = 0;
  int _customAmount = 0;
  DtPriceQuote? _quote;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;

  final _customController = TextEditingController();

  // 프리셋 금액
  static const List<int> _presetAmounts = [
    1000,
    5000,
    10000,
    30000,
    50000,
    100000,
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _selectAmount(int amount) async {
    setState(() {
      _selectedAmount = amount;
      _customAmount = 0;
      _customController.clear();
      _quote = null;
      _error = null;
    });

    await _loadQuote(amount);
  }

  Future<void> _setCustomAmount(String value) async {
    final amount = int.tryParse(value.replaceAll(',', '')) ?? 0;
    setState(() {
      _customAmount = amount;
      _selectedAmount = 0;
      _quote = null;
      _error = null;
    });

    if (amount >= 100) {
      await _loadQuote(amount);
    }
  }

  Future<void> _loadQuote(int amount) async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(dreamTimeServiceProvider);
      final quote = await service.getTopupQuote(amount);
      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _processTopup() async {
    final amount = _selectedAmount > 0 ? _selectedAmount : _customAmount;
    if (amount < 100) return;

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(dreamTimeServiceProvider);

      // 1. 주문 생성
      final order = await service.createTopupOrder(dtAmount: amount);

      // 2. 결제 시작
      final paymentInfo = await service.startPayment(order.id);

      // 3. Mock 결제의 경우 바로 완료 처리 (실제로는 결제 화면으로 이동)
      if (order.provider == DtProvider.mock) {
        await service.completeMockPayment(order.id);

        // 지갑 데이터 새로고침
        ref.invalidate(walletSummaryProvider);
        ref.invalidate(ledgerEntriesProvider(50));
        ref.invalidate(topupHistoryProvider);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${NumberFormat('#,###').format(amount)} DT가 충전되었습니다!'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      } else {
        // 실제 결제의 경우 결제 URL로 이동
        // TODO: 웹뷰 또는 외부 브라우저로 checkoutUrl 열기
        debugPrint('Checkout URL: ${paymentInfo['checkoutUrl']}');
      }
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

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepNight,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius2xl),
        ),
      ),
      child: SafeArea(
        child: Padding(
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

              // Title
              const Text(
                'DreamTime 충전',
                style: AppTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space6),

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
                  hintText: '직접 입력 (최소 100 DT)',
                  suffixText: 'DT',
                ),
                onChanged: _setCustomAmount,
              ),

              const SizedBox(height: AppTheme.space6),

              // Price quote
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.space4),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_quote != null)
                _PriceQuoteCard(quote: _quote!),

              // Channel disclosure
              if (_quote?.channelDisclosure != null) ...[
                const SizedBox(height: AppTheme.space2),
                Text(
                  _quote!.channelDisclosure!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: AppTheme.space4),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.statusError,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppTheme.space6),

              // Confirm button
              ElevatedButton(
                onPressed: currentAmount >= 100 && !_isProcessing
                    ? _processTopup
                    : null,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _quote != null
                            ? '${formatter.format(_quote!.priceKrw)}원 결제하기'
                            : '금액을 선택하세요',
                      ),
              ),

              const SizedBox(height: AppTheme.space2),

              // Info text
              Text(
                '• 충전된 DT는 5년간 유효합니다\n• 일일 충전 한도: 1,000,000 DT',
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

class _PriceQuoteCard extends StatelessWidget {
  final DtPriceQuote quote;

  const _PriceQuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('충전 DT', style: AppTypography.body),
              Text(
                '${formatter.format(quote.dtAmount)} DT',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                quote.vatIncluded ? '결제 금액 (VAT 포함)' : '결제 금액',
                style: AppTypography.body,
              ),
              Text(
                '${formatter.format(quote.priceKrw)}원',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.statusSuccess,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
