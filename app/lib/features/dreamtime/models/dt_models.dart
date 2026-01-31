/// DreamTime (DT) Currency Models

// Wallet Summary
class DtWalletSummary {
  final int totalPurchased;
  final int totalPromo;
  final int totalBalance;
  final int expiringSoonAmount;
  final DateTime? expiringSoonDate;

  DtWalletSummary({
    required this.totalPurchased,
    required this.totalPromo,
    required this.totalBalance,
    required this.expiringSoonAmount,
    this.expiringSoonDate,
  });

  factory DtWalletSummary.fromJson(Map<String, dynamic> json) {
    return DtWalletSummary(
      totalPurchased: json['total_purchased'] ?? 0,
      totalPromo: json['total_promo'] ?? 0,
      totalBalance: json['total_balance'] ?? 0,
      expiringSoonAmount: json['expiring_soon_amount'] ?? 0,
      expiringSoonDate: json['expiring_soon_date'] != null
          ? DateTime.parse(json['expiring_soon_date'])
          : null,
    );
  }
}

// Lot
enum DtLotStatus { active, expired, void_ }
enum DtLotBucket { purchased, promo }

class DtLot {
  final String id;
  final String userId;
  final String sourceType;
  final String sourceId;
  final DtLotBucket bucket;
  final int amount;
  final int remaining;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final DtLotStatus status;

  DtLot({
    required this.id,
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.bucket,
    required this.amount,
    required this.remaining,
    required this.purchasedAt,
    required this.expiresAt,
    required this.status,
  });

  factory DtLot.fromJson(Map<String, dynamic> json) {
    return DtLot(
      id: json['id'],
      userId: json['user_id'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      bucket: json['bucket'] == 'promo' ? DtLotBucket.promo : DtLotBucket.purchased,
      amount: json['amount'],
      remaining: json['remaining'],
      purchasedAt: DateTime.parse(json['purchased_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      status: _parseStatus(json['status']),
    );
  }

  static DtLotStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return DtLotStatus.active;
      case 'expired':
        return DtLotStatus.expired;
      case 'void':
        return DtLotStatus.void_;
      default:
        return DtLotStatus.active;
    }
  }

  bool get isUsable => status == DtLotStatus.active && remaining > 0 && expiresAt.isAfter(DateTime.now());
}

// Topup Order
enum DtTopupStatus { pending, paid, failed, canceled, refunded }
enum DtChannel { web, ios, android }
enum DtProvider { mock, portone, toss, stripe, iapIos, iapAndroid }

class DtTopupOrder {
  final String id;
  final String userId;
  final DtChannel channel;
  final int dtAmount;
  final int priceKrw;
  final bool vatIncluded;
  final DtTopupStatus status;
  final DtProvider provider;
  final String? providerPaymentId;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  DtTopupOrder({
    required this.id,
    required this.userId,
    required this.channel,
    required this.dtAmount,
    required this.priceKrw,
    required this.vatIncluded,
    required this.status,
    required this.provider,
    this.providerPaymentId,
    required this.idempotencyKey,
    required this.createdAt,
    this.paidAt,
    this.refundedAt,
  });

  factory DtTopupOrder.fromJson(Map<String, dynamic> json) {
    return DtTopupOrder(
      id: json['id'],
      userId: json['user_id'],
      channel: _parseChannel(json['channel']),
      dtAmount: json['dt_amount'],
      priceKrw: json['price_krw'],
      vatIncluded: json['vat_included'] ?? true,
      status: _parseTopupStatus(json['status']),
      provider: _parseProvider(json['provider']),
      providerPaymentId: json['provider_payment_id'],
      idempotencyKey: json['idempotency_key'],
      createdAt: DateTime.parse(json['created_at']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      refundedAt: json['refunded_at'] != null ? DateTime.parse(json['refunded_at']) : null,
    );
  }

  static DtChannel _parseChannel(String channel) {
    switch (channel) {
      case 'ios':
        return DtChannel.ios;
      case 'android':
        return DtChannel.android;
      default:
        return DtChannel.web;
    }
  }

  static DtTopupStatus _parseTopupStatus(String status) {
    switch (status) {
      case 'pending':
        return DtTopupStatus.pending;
      case 'paid':
        return DtTopupStatus.paid;
      case 'failed':
        return DtTopupStatus.failed;
      case 'canceled':
        return DtTopupStatus.canceled;
      case 'refunded':
        return DtTopupStatus.refunded;
      default:
        return DtTopupStatus.pending;
    }
  }

  static DtProvider _parseProvider(String provider) {
    switch (provider) {
      case 'mock':
        return DtProvider.mock;
      case 'portone':
        return DtProvider.portone;
      case 'toss':
        return DtProvider.toss;
      case 'stripe':
        return DtProvider.stripe;
      case 'iap_ios':
        return DtProvider.iapIos;
      case 'iap_android':
        return DtProvider.iapAndroid;
      default:
        return DtProvider.mock;
    }
  }

  bool get canRefund =>
      status == DtTopupStatus.paid &&
      paidAt != null &&
      paidAt!.isAfter(DateTime.now().subtract(const Duration(days: 7)));
}

// Ledger Entry
enum DtEventType { topupPaid, donationSpend, refund, promoGrant, expire, adjust }
enum DtDirection { credit, debit }

class DtLedgerEntry {
  final String id;
  final String userId;
  final DtEventType eventType;
  final String refType;
  final String refId;
  final DtDirection direction;
  final String bucket;
  final String? lotId;
  final int amount;
  final int balanceAfter;
  final String? description;
  final DateTime createdAt;

  DtLedgerEntry({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.refType,
    required this.refId,
    required this.direction,
    required this.bucket,
    this.lotId,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  factory DtLedgerEntry.fromJson(Map<String, dynamic> json) {
    return DtLedgerEntry(
      id: json['id'],
      userId: json['user_id'],
      eventType: _parseEventType(json['event_type']),
      refType: json['ref_type'],
      refId: json['ref_id'],
      direction: json['direction'] == 'credit' ? DtDirection.credit : DtDirection.debit,
      bucket: json['bucket'],
      lotId: json['lot_id'],
      amount: json['amount'],
      balanceAfter: json['balance_after'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static DtEventType _parseEventType(String type) {
    switch (type) {
      case 'topup_paid':
        return DtEventType.topupPaid;
      case 'donation_spend':
        return DtEventType.donationSpend;
      case 'refund':
        return DtEventType.refund;
      case 'promo_grant':
        return DtEventType.promoGrant;
      case 'expire':
        return DtEventType.expire;
      case 'adjust':
        return DtEventType.adjust;
      default:
        return DtEventType.adjust;
    }
  }

  String get displayTitle {
    switch (eventType) {
      case DtEventType.topupPaid:
        return '충전';
      case DtEventType.donationSpend:
        return '후원';
      case DtEventType.refund:
        return '환불';
      case DtEventType.promoGrant:
        return '프로모션 지급';
      case DtEventType.expire:
        return '만료';
      case DtEventType.adjust:
        return '조정';
    }
  }

  bool get isCredit => direction == DtDirection.credit;
}

// Donation
enum DtDonationStatus { completed, reversed }
enum DtContextType { dm, feed, content, live }

class DtDonation {
  final String id;
  final String fromUserId;
  final String toCreatorId;
  final DtContextType contextType;
  final String contextId;
  final String? message;
  final bool isAnonymous;
  final int dtAmount;
  final int spentPromo;
  final int spentPurchased;
  final DtDonationStatus status;
  final DateTime createdAt;

  // Joined data
  final Map<String, dynamic>? fromUser;
  final Map<String, dynamic>? toCreator;

  DtDonation({
    required this.id,
    required this.fromUserId,
    required this.toCreatorId,
    required this.contextType,
    required this.contextId,
    this.message,
    required this.isAnonymous,
    required this.dtAmount,
    required this.spentPromo,
    required this.spentPurchased,
    required this.status,
    required this.createdAt,
    this.fromUser,
    this.toCreator,
  });

  factory DtDonation.fromJson(Map<String, dynamic> json) {
    return DtDonation(
      id: json['id'],
      fromUserId: json['from_user_id'],
      toCreatorId: json['to_creator_id'],
      contextType: _parseContextType(json['context_type']),
      contextId: json['context_id'],
      message: json['message'],
      isAnonymous: json['is_anonymous'] ?? false,
      dtAmount: json['dt_amount'],
      spentPromo: json['spent_promo'] ?? 0,
      spentPurchased: json['spent_purchased'] ?? 0,
      status: json['status'] == 'reversed' ? DtDonationStatus.reversed : DtDonationStatus.completed,
      createdAt: DateTime.parse(json['created_at']),
      fromUser: json['from_user'],
      toCreator: json['to_creator'],
    );
  }

  static DtContextType _parseContextType(String type) {
    switch (type) {
      case 'dm':
        return DtContextType.dm;
      case 'feed':
        return DtContextType.feed;
      case 'content':
        return DtContextType.content;
      case 'live':
        return DtContextType.live;
      default:
        return DtContextType.dm;
    }
  }

  String get senderDisplayName {
    if (isAnonymous) return '익명';
    return fromUser?['nickname'] ?? '알 수 없음';
  }
}

// Creator Earnings
enum EarningsStatus { pending, payable, paid, held, reversed }

class CreatorEarning {
  final String id;
  final String creatorId;
  final String donationId;
  final int grossKrw;
  final int platformFeeKrw;
  final int netKrw;
  final EarningsStatus status;
  final DateTime createdAt;

  CreatorEarning({
    required this.id,
    required this.creatorId,
    required this.donationId,
    required this.grossKrw,
    required this.platformFeeKrw,
    required this.netKrw,
    required this.status,
    required this.createdAt,
  });

  factory CreatorEarning.fromJson(Map<String, dynamic> json) {
    return CreatorEarning(
      id: json['id'],
      creatorId: json['creator_id'],
      donationId: json['donation_id'],
      grossKrw: json['gross_krw'],
      platformFeeKrw: json['platform_fee_krw'],
      netKrw: json['net_krw'],
      status: _parseEarningsStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static EarningsStatus _parseEarningsStatus(String status) {
    switch (status) {
      case 'pending':
        return EarningsStatus.pending;
      case 'payable':
        return EarningsStatus.payable;
      case 'paid':
        return EarningsStatus.paid;
      case 'held':
        return EarningsStatus.held;
      case 'reversed':
        return EarningsStatus.reversed;
      default:
        return EarningsStatus.pending;
    }
  }
}

// Refund Request
enum RefundStatus { requested, approved, rejected, processed }

class DtRefundRequest {
  final String id;
  final String userId;
  final String topupOrderId;
  final String? reason;
  final RefundStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  // Joined data
  final DtTopupOrder? topupOrder;

  DtRefundRequest({
    required this.id,
    required this.userId,
    required this.topupOrderId,
    this.reason,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
    this.topupOrder,
  });

  factory DtRefundRequest.fromJson(Map<String, dynamic> json) {
    return DtRefundRequest(
      id: json['id'],
      userId: json['user_id'],
      topupOrderId: json['topup_order_id'],
      reason: json['reason'],
      status: _parseRefundStatus(json['status']),
      adminNote: json['admin_note'],
      createdAt: DateTime.parse(json['created_at']),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      topupOrder: json['topup_order'] != null ? DtTopupOrder.fromJson(json['topup_order']) : null,
    );
  }

  static RefundStatus _parseRefundStatus(String status) {
    switch (status) {
      case 'requested':
        return RefundStatus.requested;
      case 'approved':
        return RefundStatus.approved;
      case 'rejected':
        return RefundStatus.rejected;
      case 'processed':
        return RefundStatus.processed;
      default:
        return RefundStatus.requested;
    }
  }
}

// Price Quote
class DtPriceQuote {
  final int dtAmount;
  final int priceKrw;
  final int vatAmount;
  final bool vatIncluded;
  final String channel;
  final String? channelDisclosure;

  DtPriceQuote({
    required this.dtAmount,
    required this.priceKrw,
    required this.vatAmount,
    required this.vatIncluded,
    required this.channel,
    this.channelDisclosure,
  });

  factory DtPriceQuote.fromJson(Map<String, dynamic> json) {
    return DtPriceQuote(
      dtAmount: json['dtAmount'],
      priceKrw: json['priceKrw'],
      vatAmount: json['vatAmount'],
      vatIncluded: json['vatIncluded'] ?? true,
      channel: json['channel'],
      channelDisclosure: json['channelDisclosure'],
    );
  }
}
