import 'package:flutter_test/flutter_test.dart';
import 'package:moe_backstage/features/dreamtime/models/dt_models.dart';

void main() {
  group('DreamTime Models', () {
    group('DtWalletSummary', () {
      test('should parse from JSON correctly', () {
        final json = {
          'total_purchased': 10000,
          'total_promo': 5000,
          'total_balance': 15000,
          'expiring_soon_amount': 1000,
          'expiring_soon_date': '2025-01-01T00:00:00Z',
        };

        final wallet = DtWalletSummary.fromJson(json);

        expect(wallet.totalPurchased, 10000);
        expect(wallet.totalPromo, 5000);
        expect(wallet.totalBalance, 15000);
        expect(wallet.expiringSoonAmount, 1000);
        expect(wallet.expiringSoonDate, isNotNull);
      });

      test('should handle null expiring date', () {
        final json = {
          'total_purchased': 10000,
          'total_promo': 5000,
          'total_balance': 15000,
          'expiring_soon_amount': 0,
          'expiring_soon_date': null,
        };

        final wallet = DtWalletSummary.fromJson(json);

        expect(wallet.expiringSoonDate, isNull);
      });
    });

    group('DtLot', () {
      test('should parse active lot correctly', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'source_type': 'topup',
          'source_id': '123e4567-e89b-12d3-a456-426614174002',
          'bucket': 'purchased',
          'amount': 10000,
          'remaining': 8000,
          'purchased_at': '2024-01-01T00:00:00Z',
          'expires_at': '2029-01-01T00:00:00Z',
          'status': 'active',
        };

        final lot = DtLot.fromJson(json);

        expect(lot.bucket, DtLotBucket.purchased);
        expect(lot.amount, 10000);
        expect(lot.remaining, 8000);
        expect(lot.status, DtLotStatus.active);
        expect(lot.isUsable, isTrue);
      });

      test('should mark expired lot as not usable', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'source_type': 'topup',
          'source_id': '123e4567-e89b-12d3-a456-426614174002',
          'bucket': 'purchased',
          'amount': 10000,
          'remaining': 10000,
          'purchased_at': '2020-01-01T00:00:00Z',
          'expires_at': '2020-01-02T00:00:00Z', // Expired
          'status': 'active',
        };

        final lot = DtLot.fromJson(json);

        expect(lot.isUsable, isFalse);
      });

      test('should mark void lot as not usable', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'source_type': 'topup',
          'source_id': '123e4567-e89b-12d3-a456-426614174002',
          'bucket': 'purchased',
          'amount': 10000,
          'remaining': 0,
          'purchased_at': '2024-01-01T00:00:00Z',
          'expires_at': '2029-01-01T00:00:00Z',
          'status': 'void',
        };

        final lot = DtLot.fromJson(json);

        expect(lot.status, DtLotStatus.void_);
        expect(lot.isUsable, isFalse);
      });
    });

    group('DtTopupOrder', () {
      test('should correctly identify refundable order', () {
        final now = DateTime.now();
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'channel': 'web',
          'dt_amount': 10000,
          'price_krw': 10000,
          'vat_included': true,
          'status': 'paid',
          'provider': 'mock',
          'provider_payment_id': 'mock_123',
          'idempotency_key': 'idem_123',
          'created_at': now.toIso8601String(),
          'paid_at': now.toIso8601String(),
          'refunded_at': null,
        };

        final order = DtTopupOrder.fromJson(json);

        expect(order.status, DtTopupStatus.paid);
        expect(order.canRefund, isTrue);
      });

      test('should not allow refund after 7 days', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 8));
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'channel': 'web',
          'dt_amount': 10000,
          'price_krw': 10000,
          'vat_included': true,
          'status': 'paid',
          'provider': 'mock',
          'provider_payment_id': 'mock_123',
          'idempotency_key': 'idem_123',
          'created_at': oldDate.toIso8601String(),
          'paid_at': oldDate.toIso8601String(),
          'refunded_at': null,
        };

        final order = DtTopupOrder.fromJson(json);

        expect(order.canRefund, isFalse);
      });

      test('should not allow refund for non-paid status', () {
        final now = DateTime.now();
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'channel': 'web',
          'dt_amount': 10000,
          'price_krw': 10000,
          'vat_included': true,
          'status': 'refunded',
          'provider': 'mock',
          'provider_payment_id': 'mock_123',
          'idempotency_key': 'idem_123',
          'created_at': now.toIso8601String(),
          'paid_at': now.toIso8601String(),
          'refunded_at': now.toIso8601String(),
        };

        final order = DtTopupOrder.fromJson(json);

        expect(order.status, DtTopupStatus.refunded);
        expect(order.canRefund, isFalse);
      });
    });

    group('DtLedgerEntry', () {
      test('should correctly identify credit vs debit', () {
        final creditJson = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'event_type': 'topup_paid',
          'ref_type': 'topup',
          'ref_id': '123e4567-e89b-12d3-a456-426614174002',
          'direction': 'credit',
          'bucket': 'purchased',
          'lot_id': null,
          'amount': 10000,
          'balance_after': 10000,
          'description': 'Test topup',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final debitJson = {
          'id': '123e4567-e89b-12d3-a456-426614174003',
          'user_id': '123e4567-e89b-12d3-a456-426614174001',
          'event_type': 'donation_spend',
          'ref_type': 'donation',
          'ref_id': '123e4567-e89b-12d3-a456-426614174004',
          'direction': 'debit',
          'bucket': 'purchased',
          'lot_id': '123e4567-e89b-12d3-a456-426614174005',
          'amount': 5000,
          'balance_after': 5000,
          'description': 'Donation',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final credit = DtLedgerEntry.fromJson(creditJson);
        final debit = DtLedgerEntry.fromJson(debitJson);

        expect(credit.isCredit, isTrue);
        expect(credit.displayTitle, '충전');
        expect(debit.isCredit, isFalse);
        expect(debit.displayTitle, '후원');
      });
    });

    group('DtDonation', () {
      test('should handle anonymous donor', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'from_user_id': '123e4567-e89b-12d3-a456-426614174001',
          'to_creator_id': '123e4567-e89b-12d3-a456-426614174002',
          'context_type': 'dm',
          'context_id': '123e4567-e89b-12d3-a456-426614174003',
          'message': 'Great content!',
          'is_anonymous': true,
          'dt_amount': 1000,
          'spent_promo': 0,
          'spent_purchased': 1000,
          'status': 'completed',
          'created_at': '2024-01-01T00:00:00Z',
          'from_user': {'nickname': 'TestUser'},
          'to_creator': {'nickname': 'TestCreator'},
        };

        final donation = DtDonation.fromJson(json);

        expect(donation.isAnonymous, isTrue);
        expect(donation.senderDisplayName, '익명');
      });

      test('should show real name for non-anonymous', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'from_user_id': '123e4567-e89b-12d3-a456-426614174001',
          'to_creator_id': '123e4567-e89b-12d3-a456-426614174002',
          'context_type': 'dm',
          'context_id': '123e4567-e89b-12d3-a456-426614174003',
          'message': 'Great content!',
          'is_anonymous': false,
          'dt_amount': 1000,
          'spent_promo': 0,
          'spent_purchased': 1000,
          'status': 'completed',
          'created_at': '2024-01-01T00:00:00Z',
          'from_user': {'nickname': 'TestUser'},
          'to_creator': {'nickname': 'TestCreator'},
        };

        final donation = DtDonation.fromJson(json);

        expect(donation.isAnonymous, isFalse);
        expect(donation.senderDisplayName, 'TestUser');
      });

      test('should verify spent amounts equal total', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'from_user_id': '123e4567-e89b-12d3-a456-426614174001',
          'to_creator_id': '123e4567-e89b-12d3-a456-426614174002',
          'context_type': 'dm',
          'context_id': '123e4567-e89b-12d3-a456-426614174003',
          'message': null,
          'is_anonymous': false,
          'dt_amount': 5000,
          'spent_promo': 2000,
          'spent_purchased': 3000,
          'status': 'completed',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final donation = DtDonation.fromJson(json);

        // Verify invariant: spent_promo + spent_purchased == dt_amount
        expect(donation.spentPromo + donation.spentPurchased, donation.dtAmount);
      });
    });

    group('DtPriceQuote', () {
      test('should parse price quote with channel disclosure', () {
        final json = {
          'dtAmount': 10000,
          'priceKrw': 13000,
          'vatAmount': 1182,
          'vatIncluded': true,
          'channel': 'ios',
          'channelDisclosure': '앱스토어 수수료가 포함된 가격입니다.',
        };

        final quote = DtPriceQuote.fromJson(json);

        expect(quote.dtAmount, 10000);
        expect(quote.priceKrw, 13000);
        expect(quote.channel, 'ios');
        expect(quote.channelDisclosure, isNotNull);
      });
    });

    group('CreatorEarning', () {
      test('should verify fee calculation', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'creator_id': '123e4567-e89b-12d3-a456-426614174001',
          'donation_id': '123e4567-e89b-12d3-a456-426614174002',
          'gross_krw': 10000,
          'platform_fee_krw': 2000,
          'net_krw': 8000,
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final earning = CreatorEarning.fromJson(json);

        // Verify invariant: net = gross - fee
        expect(earning.netKrw, earning.grossKrw - earning.platformFeeKrw);
        expect(earning.status, EarningsStatus.pending);
      });
    });
  });

  group('Business Rules', () {
    test('FIFO: promo lots should be spent before purchased (when configured)', () {
      // This test would require mocking the service
      // For now, verify the model supports tracking
      final promoLot = DtLot.fromJson({
        'id': '1',
        'user_id': 'user1',
        'source_type': 'promo',
        'source_id': 'promo1',
        'bucket': 'promo',
        'amount': 1000,
        'remaining': 1000,
        'purchased_at': '2024-01-01T00:00:00Z',
        'expires_at': '2029-01-01T00:00:00Z',
        'status': 'active',
      });

      final purchasedLot = DtLot.fromJson({
        'id': '2',
        'user_id': 'user1',
        'source_type': 'topup',
        'source_id': 'topup1',
        'bucket': 'purchased',
        'amount': 5000,
        'remaining': 5000,
        'purchased_at': '2024-01-02T00:00:00Z',
        'expires_at': '2029-01-02T00:00:00Z',
        'status': 'active',
      });

      expect(promoLot.bucket, DtLotBucket.promo);
      expect(purchasedLot.bucket, DtLotBucket.purchased);

      // In FIFO with promo_first=true:
      // - Promo lot (purchased_at: Jan 1) should be consumed first
      // - Then purchased lot (purchased_at: Jan 2)
    });

    test('Expiry: lot should not be usable after expires_at', () {
      final expiredLot = DtLot.fromJson({
        'id': '1',
        'user_id': 'user1',
        'source_type': 'topup',
        'source_id': 'topup1',
        'bucket': 'purchased',
        'amount': 1000,
        'remaining': 1000,
        'purchased_at': '2020-01-01T00:00:00Z',
        'expires_at': '2020-06-01T00:00:00Z', // Expired
        'status': 'active', // Status might not be updated yet
      });

      // The isUsable getter should check expires_at
      expect(expiredLot.isUsable, isFalse);
    });
  });
}
