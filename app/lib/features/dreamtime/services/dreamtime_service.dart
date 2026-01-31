import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';
import '../models/dt_models.dart';

/// DreamTime Service for wallet, topup, donation, and refund operations
class DreamTimeService {
  final SupabaseClient _supabase;

  DreamTimeService(this._supabase);

  // ============================================
  // WALLET
  // ============================================

  /// Get wallet summary with expiring lots info
  Future<DtWalletSummary> getWalletSummary() async {
    // 데모 모드
    if (isDemoMode) {
      return DtWalletSummary(
        totalPurchased: 4000,
        totalPromo: 500,
        totalBalance: 4500,
        expiringSoonAmount: 200,
        expiringSoonDate: DateTime.now().add(const Duration(days: 7)),
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final result = await _supabase.rpc('dt_get_wallet_summary', params: {
      'p_user_id': userId,
    });

    if (result == null || (result as List).isEmpty) {
      return DtWalletSummary(
        totalPurchased: 0,
        totalPromo: 0,
        totalBalance: 0,
        expiringSoonAmount: 0,
      );
    }

    return DtWalletSummary.fromJson(result[0]);
  }

  /// Get user's lots
  Future<List<DtLot>> getLots({bool activeOnly = true}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    var query = _supabase
        .from('dt_lots')
        .select()
        .eq('user_id', userId)
        .order('purchased_at', ascending: true);

    if (activeOnly) {
      query = query.eq('status', 'active');
    }

    final response = await query;
    return (response as List).map((e) => DtLot.fromJson(e)).toList();
  }

  /// Get ledger entries (transaction history)
  Future<List<DtLedgerEntry>> getLedgerEntries({
    int limit = 20,
    int offset = 0,
  }) async {
    // 데모 모드
    if (isDemoMode) {
      return _getDemoLedgerEntries();
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('dt_ledger_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => DtLedgerEntry.fromJson(e)).toList();
  }

  /// 데모 거래 내역
  List<DtLedgerEntry> _getDemoLedgerEntries() {
    return [
      DtLedgerEntry(
        id: 'ledger-1',
        userId: 'demo-user',
        eventType: DtEventType.topupPaid,
        refType: 'topup',
        refId: 'topup-1',
        direction: DtDirection.credit,
        bucket: 'purchased',
        amount: 5000,
        balanceAfter: 5000,
        description: '충전 (5,000 DT)',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      DtLedgerEntry(
        id: 'ledger-2',
        userId: 'demo-user',
        eventType: DtEventType.promoGrant,
        refType: 'promo',
        refId: 'promo-1',
        direction: DtDirection.credit,
        bucket: 'promo',
        amount: 500,
        balanceAfter: 5500,
        description: '가입 축하 보너스',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      DtLedgerEntry(
        id: 'ledger-3',
        userId: 'demo-user',
        eventType: DtEventType.donationSpend,
        refType: 'donation',
        refId: 'donation-1',
        direction: DtDirection.debit,
        bucket: 'purchased',
        amount: 500,
        balanceAfter: 5000,
        description: '유키에게 후원',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      DtLedgerEntry(
        id: 'ledger-4',
        userId: 'demo-user',
        eventType: DtEventType.donationSpend,
        refType: 'donation',
        refId: 'donation-2',
        direction: DtDirection.debit,
        bucket: 'purchased',
        amount: 300,
        balanceAfter: 4700,
        description: '하나에게 후원',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DtLedgerEntry(
        id: 'ledger-5',
        userId: 'demo-user',
        eventType: DtEventType.donationSpend,
        refType: 'donation',
        refId: 'donation-3',
        direction: DtDirection.debit,
        bucket: 'promo',
        amount: 200,
        balanceAfter: 4500,
        description: '미나에게 후원',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  // ============================================
  // TOPUP
  // ============================================

  /// Get current channel based on platform
  String get currentChannel {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'web';
  }

  /// Get price quote for top-up amount
  Future<DtPriceQuote> getTopupQuote(int dtAmount) async {
    final response = await _supabase.functions.invoke(
      'dt-topup',
      body: {
        'dtAmount': dtAmount,
        'channel': currentChannel,
      },
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to get quote');
    }

    return DtPriceQuote.fromJson(response.data);
  }

  /// Create a top-up order
  Future<DtTopupOrder> createTopupOrder({
    required int dtAmount,
    String? provider,
  }) async {
    final response = await _supabase.functions.invoke(
      'dt-topup/create',
      body: {
        'dtAmount': dtAmount,
        'channel': currentChannel,
        'provider': provider ?? 'mock',
      },
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to create order');
    }

    return DtTopupOrder.fromJson(response.data['order']);
  }

  /// Start payment process for an order
  Future<Map<String, dynamic>> startPayment(String orderId) async {
    final response = await _supabase.functions.invoke(
      'dt-topup/start',
      body: {'orderId': orderId},
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to start payment');
    }

    return response.data;
  }

  /// Complete mock payment (for testing)
  Future<void> completeMockPayment(String orderId) async {
    final response = await _supabase.functions.invoke(
      'dt-topup/mock-complete',
      body: {'orderId': orderId},
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to complete payment');
    }
  }

  /// Get topup order history
  Future<List<DtTopupOrder>> getTopupHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    // 데모 모드
    if (isDemoMode) {
      return [
        DtTopupOrder(
          id: 'topup-1',
          userId: 'demo-user',
          channel: DtChannel.web,
          dtAmount: 5000,
          priceKrw: 5500,
          vatIncluded: true,
          status: DtTopupStatus.paid,
          provider: DtProvider.mock,
          idempotencyKey: 'idem-1',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          paidAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('dt_topup_orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => DtTopupOrder.fromJson(e)).toList();
  }

  // ============================================
  // DONATION
  // ============================================

  /// Commit a donation
  Future<DtDonation> commitDonation({
    required String toCreatorId,
    required String contextType,
    required String contextId,
    String? message,
    bool isAnonymous = false,
    required int dtAmount,
  }) async {
    final response = await _supabase.functions.invoke(
      'dt-donation/commit',
      body: {
        'toCreatorId': toCreatorId,
        'contextType': contextType,
        'contextId': contextId,
        'message': message,
        'isAnonymous': isAnonymous,
        'dtAmount': dtAmount,
      },
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Failed to process donation';
      final reason = response.data['reason'];
      throw DonationException(error, reason: reason);
    }

    // Fetch the created donation
    final donation = await _supabase
        .from('dt_donations')
        .select()
        .eq('id', response.data['donationId'])
        .single();

    return DtDonation.fromJson(donation);
  }

  /// Get sent donation history
  Future<List<DtDonation>> getSentDonations({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.functions.invoke(
      'dt-donation/history',
      queryParameters: {
        'type': 'sent',
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
      method: HttpMethod.get,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch donations');
    }

    return (response.data['donations'] as List)
        .map((e) => DtDonation.fromJson(e))
        .toList();
  }

  /// Get received donation history (for creators)
  Future<List<DtDonation>> getReceivedDonations({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.functions.invoke(
      'dt-donation/history',
      queryParameters: {
        'type': 'received',
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
      method: HttpMethod.get,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch donations');
    }

    return (response.data['donations'] as List)
        .map((e) => DtDonation.fromJson(e))
        .toList();
  }

  // ============================================
  // REFUND
  // ============================================

  /// Check if a topup order is eligible for refund
  Future<RefundEligibility> checkRefundEligibility(String topupOrderId) async {
    final response = await _supabase.functions.invoke(
      'dt-refund/check-eligibility',
      body: {'topupOrderId': topupOrderId},
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to check eligibility');
    }

    return RefundEligibility(
      eligible: response.data['eligible'] ?? false,
      reason: response.data['reason'],
    );
  }

  /// Request a refund for a topup order
  Future<DtRefundRequest> requestRefund({
    required String topupOrderId,
    String? reason,
  }) async {
    final response = await _supabase.functions.invoke(
      'dt-refund/request',
      body: {
        'topupOrderId': topupOrderId,
        'reason': reason,
      },
      method: HttpMethod.post,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to request refund');
    }

    return DtRefundRequest.fromJson(response.data['refundRequest']);
  }

  /// Get refund request history
  Future<List<DtRefundRequest>> getRefundRequests() async {
    final response = await _supabase.functions.invoke(
      'dt-refund/requests',
      method: HttpMethod.get,
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to fetch refund requests');
    }

    return (response.data['requests'] as List)
        .map((e) => DtRefundRequest.fromJson(e))
        .toList();
  }

  // ============================================
  // CREATOR EARNINGS
  // ============================================

  /// Get creator earnings summary
  Future<CreatorEarningsSummary> getEarningsSummary() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('creator_earnings_ledger')
        .select()
        .eq('creator_id', userId);

    final earnings = (response as List).map((e) => CreatorEarning.fromJson(e)).toList();

    int totalGross = 0;
    int totalFees = 0;
    int totalNet = 0;
    int pendingAmount = 0;
    int payableAmount = 0;

    for (final earning in earnings) {
      totalGross += earning.grossKrw;
      totalFees += earning.platformFeeKrw;
      totalNet += earning.netKrw;

      if (earning.status == EarningsStatus.pending) {
        pendingAmount += earning.netKrw;
      } else if (earning.status == EarningsStatus.payable) {
        payableAmount += earning.netKrw;
      }
    }

    return CreatorEarningsSummary(
      totalGross: totalGross,
      totalFees: totalFees,
      totalNet: totalNet,
      pendingAmount: pendingAmount,
      payableAmount: payableAmount,
      earnings: earnings,
    );
  }

  // ============================================
  // REALTIME SUBSCRIPTIONS
  // ============================================

  /// Subscribe to wallet changes
  RealtimeChannel subscribeToWallet(void Function(Map<String, dynamic>) onUpdate) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .channel('wallet:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'dt_wallets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to new donations (for creators)
  RealtimeChannel subscribeToDonations(void Function(DtDonation) onDonation) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .channel('donations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dt_donations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'to_creator_id',
            value: userId,
          ),
          callback: (payload) => onDonation(DtDonation.fromJson(payload.newRecord)),
        )
        .subscribe();
  }
}

// Helper classes
class RefundEligibility {
  final bool eligible;
  final String? reason;

  RefundEligibility({required this.eligible, this.reason});
}

class CreatorEarningsSummary {
  final int totalGross;
  final int totalFees;
  final int totalNet;
  final int pendingAmount;
  final int payableAmount;
  final List<CreatorEarning> earnings;

  CreatorEarningsSummary({
    required this.totalGross,
    required this.totalFees,
    required this.totalNet,
    required this.pendingAmount,
    required this.payableAmount,
    required this.earnings,
  });
}

class DonationException implements Exception {
  final String message;
  final String? reason;

  DonationException(this.message, {this.reason});

  @override
  String toString() => reason != null ? '$message: $reason' : message;
}

// Providers
final dreamTimeServiceProvider = Provider<DreamTimeService>((ref) {
  return DreamTimeService(Supabase.instance.client);
});

// Wallet state
final walletSummaryProvider = FutureProvider<DtWalletSummary>((ref) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getWalletSummary();
});

// Ledger state
final ledgerEntriesProvider = FutureProvider.family<List<DtLedgerEntry>, int>((ref, limit) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getLedgerEntries(limit: limit);
});

// Topup history state
final topupHistoryProvider = FutureProvider<List<DtTopupOrder>>((ref) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getTopupHistory();
});

// Sent donations state
final sentDonationsProvider = FutureProvider<List<DtDonation>>((ref) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getSentDonations();
});

// Received donations state (for creators)
final receivedDonationsProvider = FutureProvider<List<DtDonation>>((ref) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getReceivedDonations();
});

// Creator earnings state
final creatorEarningsProvider = FutureProvider<CreatorEarningsSummary>((ref) async {
  final service = ref.watch(dreamTimeServiceProvider);
  return service.getEarningsSummary();
});
