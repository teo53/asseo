import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/dt_models.dart';
import '../../services/dreamtime_service.dart';
import '../widgets/topup_modal.dart';

/// DreamTime 지갑 페이지
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletSummaryProvider);
    final ledgerAsync = ref.watch(ledgerEntriesProvider(50));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: const Text('내 지갑'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      // TODO: Navigate to full history
                    },
                  ),
                ],
              ),

              // Wallet Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: walletAsync.when(
                    data: (wallet) => _WalletCard(wallet: wallet),
                    loading: () => const _WalletCardSkeleton(),
                    error: (e, _) => _WalletCardError(error: e.toString()),
                  ),
                ),
              ),

              // Expiring Soon Warning
              walletAsync.maybeWhen(
                data: (wallet) {
                  if (wallet.expiringSoonAmount > 0) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
                        child: _ExpiringWarning(
                          amount: wallet.expiringSoonAmount,
                          date: wallet.expiringSoonDate,
                        ),
                      ),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
                orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Action Buttons
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_circle_outline,
                          label: '충전하기',
                          onTap: () => _showTopupModal(context),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space3),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.receipt_long_outlined,
                          label: '환불 신청',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RefundPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction History Header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.space4,
                    AppTheme.space6,
                    AppTheme.space4,
                    AppTheme.space3,
                  ),
                  child: Text(
                    '거래 내역',
                    style: AppTypography.heading3,
                  ),
                ),
              ),

              // Transaction List
              ledgerAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          '거래 내역이 없습니다',
                          style: AppTypography.body,
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TransactionItem(entry: entries[index]),
                      childCount: entries.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('오류: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTopupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TopupModal(),
    );
  }
}

/// 지갑 카드
class _WalletCard extends StatelessWidget {
  final DtWalletSummary wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppColors.snowPure,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space2),
                decoration: BoxDecoration(
                  color: AppColors.deepNight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: AppColors.deepNight,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space3),
              const Text(
                'DreamTime',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepNight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space6),
          Text(
            '${formatter.format(wallet.totalBalance)} DT',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNight,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Row(
            children: [
              _BalanceChip(
                label: '충전',
                amount: wallet.totalPurchased,
                color: AppColors.deepSlate,
              ),
              const SizedBox(width: AppTheme.space2),
              _BalanceChip(
                label: '프로모션',
                amount: wallet.totalPromo,
                color: AppColors.statusSuccess.withOpacity(0.8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _BalanceChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$label ${formatter.format(amount)}',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _WalletCardSkeleton extends StatelessWidget {
  const _WalletCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _WalletCardError extends StatelessWidget {
  final String error;

  const _WalletCardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      ),
      child: Text('오류: $error', style: AppTypography.body),
    );
  }
}

/// 만료 임박 경고
class _ExpiringWarning extends StatelessWidget {
  final int amount;
  final DateTime? date;

  const _ExpiringWarning({required this.amount, this.date});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final dateStr = date != null
        ? DateFormat('yyyy.MM.dd').format(date!)
        : '곧';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppColors.statusWarning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.statusWarning,
            size: 20,
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              '${formatter.format(amount)} DT가 $dateStr 까지 만료됩니다',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 액션 버튼
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepShadow,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.snowPure, size: 20),
              const SizedBox(width: AppTheme.space2),
              Text(label, style: AppTypography.body),
            ],
          ),
        ),
      ),
    );
  }
}

/// 거래 내역 아이템
class _TransactionItem extends StatelessWidget {
  final DtLedgerEntry entry;

  const _TransactionItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final isCredit = entry.isCredit;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space1,
      ),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppColors.deepShadow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.statusSuccess.withOpacity(0.15)
                  : AppColors.statusError.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              isCredit ? Icons.add : Icons.remove,
              color: isCredit ? AppColors.statusSuccess : AppColors.statusError,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayTitle,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MM.dd HH:mm').format(entry.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textOnDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${formatter.format(entry.amount)} DT',
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: isCredit ? AppColors.statusSuccess : AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// 환불 페이지 (간단한 버전)
class RefundPage extends ConsumerWidget {
  const RefundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topupHistoryAsync = ref.watch(topupHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('환불 신청'),
        backgroundColor: AppColors.deepVoid,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientVoid,
        ),
        child: topupHistoryAsync.when(
          data: (orders) {
            final refundableOrders = orders.where((o) => o.canRefund).toList();

            if (refundableOrders.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppColors.textOnDarkMuted,
                      ),
                      SizedBox(height: AppTheme.space4),
                      Text(
                        '환불 가능한 충전 내역이 없습니다',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.space2),
                      Text(
                        '환불은 결제 후 7일 이내,\n해당 충전분을 전혀 사용하지 않은 경우에만 가능합니다.',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.space4),
              itemCount: refundableOrders.length,
              itemBuilder: (context, index) {
                final order = refundableOrders[index];
                return _RefundableOrderCard(order: order);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('오류: $e')),
        ),
      ),
    );
  }
}

class _RefundableOrderCard extends ConsumerWidget {
  final DtTopupOrder order;

  const _RefundableOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${formatter.format(order.dtAmount)} DT',
                  style: AppTypography.heading3,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                    vertical: AppTheme.space1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    '환불 가능',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.statusSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              '결제금액: ${formatter.format(order.priceKrw)}원',
              style: AppTypography.bodySmall,
            ),
            Text(
              '결제일: ${DateFormat('yyyy.MM.dd HH:mm').format(order.paidAt!)}',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppTheme.space4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _requestRefund(context, ref, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusError.withOpacity(0.15),
                  foregroundColor: AppColors.statusError,
                ),
                child: const Text('환불 신청'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestRefund(
    BuildContext context,
    WidgetRef ref,
    DtTopupOrder order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.deepShadow,
        title: const Text('환불 신청'),
        content: Text(
          '${NumberFormat('#,###').format(order.dtAmount)} DT 충전 건을 환불 신청하시겠습니까?\n\n환불 처리까지 영업일 기준 3-5일이 소요될 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusError,
            ),
            child: const Text('환불 신청'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(dreamTimeServiceProvider);
        await service.requestRefund(topupOrderId: order.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('환불 신청이 접수되었습니다.')),
          );
          ref.invalidate(topupHistoryProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('환불 신청 실패: $e')),
          );
        }
      }
    }
  }
}
