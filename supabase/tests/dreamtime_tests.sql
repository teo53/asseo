-- ============================================
-- DreamTime Invariant Tests
-- Run these tests to verify system correctness
-- ============================================

-- Test Setup: Create test users
DO $$
DECLARE
  v_user1_id UUID := gen_random_uuid();
  v_user2_id UUID := gen_random_uuid();  -- Creator
  v_order_id UUID;
  v_lot_id UUID;
  v_donation_id UUID;
  v_wallet public.dt_wallets;
  v_result RECORD;
BEGIN
  -- Clean up any existing test data
  DELETE FROM public.profiles WHERE email LIKE 'test_%@example.com';

  -- Insert test users
  INSERT INTO public.profiles (id, email, nickname, role)
  VALUES
    (v_user1_id, 'test_user1@example.com', 'TestUser1', 'user'),
    (v_user2_id, 'test_creator@example.com', 'TestCreator', 'creator');

  RAISE NOTICE 'Test users created: % and %', v_user1_id, v_user2_id;

  -- ============================================
  -- TEST 1: Wallet creation
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 1: Wallet Creation ===';

  SELECT * INTO v_wallet FROM public.get_or_create_wallet(v_user1_id);

  ASSERT v_wallet.user_id = v_user1_id, 'Wallet user_id mismatch';
  ASSERT v_wallet.total_purchased = 0, 'Initial purchased should be 0';
  ASSERT v_wallet.total_promo = 0, 'Initial promo should be 0';

  RAISE NOTICE 'TEST 1 PASSED: Wallet created correctly';

  -- ============================================
  -- TEST 2: Topup order creation and credit
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 2: Topup Order and Credit ===';

  -- Create a topup order
  INSERT INTO public.dt_topup_orders (
    id, user_id, channel, dt_amount, price_krw, provider, idempotency_key
  ) VALUES (
    gen_random_uuid(), v_user1_id, 'web', 10000, 10000, 'mock',
    'test_idem_' || gen_random_uuid()
  )
  RETURNING id INTO v_order_id;

  RAISE NOTICE 'Created order: %', v_order_id;

  -- Credit the topup
  SELECT * INTO v_result FROM public.dt_credit_topup(v_order_id);

  ASSERT v_result.success = true, 'Credit should succeed: ' || COALESCE(v_result.error, '');

  v_lot_id := v_result.lot_id;
  RAISE NOTICE 'Created lot: %', v_lot_id;

  -- Verify wallet balance
  SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = v_user1_id;
  ASSERT v_wallet.total_purchased = 10000, 'Purchased balance should be 10000, got ' || v_wallet.total_purchased;

  -- Verify lot
  ASSERT EXISTS (
    SELECT 1 FROM public.dt_lots
    WHERE id = v_lot_id AND amount = 10000 AND remaining = 10000 AND status = 'active'
  ), 'Lot should exist with correct values';

  -- Verify ledger entry
  ASSERT EXISTS (
    SELECT 1 FROM public.dt_ledger_entries
    WHERE user_id = v_user1_id AND event_type = 'topup_paid' AND amount = 10000
  ), 'Ledger entry should exist';

  RAISE NOTICE 'TEST 2 PASSED: Topup credited correctly';

  -- ============================================
  -- TEST 3: Idempotency - double credit should not happen
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 3: Idempotency ===';

  -- Try to credit the same order again
  SELECT * INTO v_result FROM public.dt_credit_topup(v_order_id);

  -- Should succeed but return the existing lot (idempotent)
  ASSERT v_result.success = true, 'Second credit should be idempotent';
  ASSERT v_result.lot_id = v_lot_id, 'Should return same lot_id';

  -- Verify balance hasn't doubled
  SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = v_user1_id;
  ASSERT v_wallet.total_purchased = 10000, 'Balance should still be 10000, not doubled';

  RAISE NOTICE 'TEST 3 PASSED: Idempotency working correctly';

  -- ============================================
  -- TEST 4: FIFO Spending
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 4: FIFO Spending ===';

  -- Create a second lot to test FIFO
  INSERT INTO public.dt_topup_orders (
    id, user_id, channel, dt_amount, price_krw, provider, idempotency_key
  ) VALUES (
    gen_random_uuid(), v_user1_id, 'web', 5000, 5000, 'mock',
    'test_idem_2_' || gen_random_uuid()
  )
  RETURNING id INTO v_order_id;

  SELECT * INTO v_result FROM public.dt_credit_topup(v_order_id);
  ASSERT v_result.success = true, 'Second topup should succeed';

  -- Now balance should be 15000
  SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = v_user1_id;
  ASSERT v_wallet.total_purchased = 15000, 'Balance should be 15000';

  -- Make a donation that partially consumes the first lot
  SELECT * INTO v_result FROM public.dt_spend_donation(
    v_user1_id, v_user2_id, 'dm', gen_random_uuid(), 'Test donation', false, 8000
  );

  ASSERT v_result.success = true, 'Donation should succeed: ' || COALESCE(v_result.error, '');
  ASSERT v_result.spent_purchased = 8000, 'Should spend 8000 from purchased';

  -- Verify the first (oldest) lot was consumed first
  ASSERT EXISTS (
    SELECT 1 FROM public.dt_lots
    WHERE id = v_lot_id AND remaining = 2000  -- 10000 - 8000
  ), 'First lot should have 2000 remaining (FIFO)';

  -- Verify wallet balance
  SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = v_user1_id;
  ASSERT v_wallet.total_purchased = 7000, 'Balance should be 7000 after spending 8000';

  RAISE NOTICE 'TEST 4 PASSED: FIFO spending correct';

  -- ============================================
  -- TEST 5: Invariant - wallet total == sum(lot remaining)
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 5: Balance Invariant ===';

  DECLARE
    v_lot_sum BIGINT;
  BEGIN
    SELECT COALESCE(SUM(remaining), 0) INTO v_lot_sum
    FROM public.dt_lots
    WHERE user_id = v_user1_id AND bucket = 'purchased' AND status = 'active';

    SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = v_user1_id;

    ASSERT v_wallet.total_purchased = v_lot_sum,
      'INVARIANT VIOLATED: wallet.total_purchased (' || v_wallet.total_purchased ||
      ') != sum(lot.remaining) (' || v_lot_sum || ')';

    RAISE NOTICE 'TEST 5 PASSED: Balance invariant holds (% = %)', v_wallet.total_purchased, v_lot_sum;
  END;

  -- ============================================
  -- TEST 6: Refund eligibility - used lot
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 6: Refund Eligibility ===';

  -- The first topup lot has been partially used, should NOT be eligible
  SELECT * INTO v_result FROM public.dt_check_refund_eligibility(
    (SELECT id FROM public.dt_topup_orders WHERE user_id = v_user1_id ORDER BY created_at LIMIT 1)
  );

  ASSERT v_result.eligible = false, 'Partially used lot should NOT be refund eligible';
  RAISE NOTICE 'Refund eligibility reason: %', v_result.reason;

  RAISE NOTICE 'TEST 6 PASSED: Used lot correctly marked as non-refundable';

  -- ============================================
  -- TEST 7: Insufficient balance
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 7: Insufficient Balance ===';

  SELECT * INTO v_result FROM public.dt_spend_donation(
    v_user1_id, v_user2_id, 'dm', gen_random_uuid(), 'Too much', false, 100000
  );

  ASSERT v_result.success = false, 'Should fail with insufficient balance';
  ASSERT v_result.error LIKE '%Insufficient%', 'Error should mention insufficient balance';

  RAISE NOTICE 'TEST 7 PASSED: Insufficient balance handled correctly';

  -- ============================================
  -- TEST 8: Self-donation prevention
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 8: Self-Donation Prevention ===';

  SELECT * INTO v_result FROM public.dt_spend_donation(
    v_user1_id, v_user1_id, 'dm', gen_random_uuid(), 'Self', false, 100
  );

  ASSERT v_result.success = false, 'Self-donation should fail';
  ASSERT v_result.error LIKE '%yourself%', 'Error should mention self-donation';

  RAISE NOTICE 'TEST 8 PASSED: Self-donation prevented';

  -- ============================================
  -- TEST 9: Creator earnings
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== TEST 9: Creator Earnings ===';

  DECLARE
    v_earning creator_earnings_ledger;
  BEGIN
    SELECT * INTO v_earning FROM public.creator_earnings_ledger WHERE creator_id = v_user2_id LIMIT 1;

    ASSERT v_earning IS NOT NULL, 'Creator earning should exist';
    ASSERT v_earning.gross_krw = 8000, 'Gross should be 8000';
    ASSERT v_earning.net_krw = v_earning.gross_krw - v_earning.platform_fee_krw, 'Net calculation should be correct';

    RAISE NOTICE 'Creator earnings: gross=%, fee=%, net=%',
      v_earning.gross_krw, v_earning.platform_fee_krw, v_earning.net_krw;
  END;

  RAISE NOTICE 'TEST 9 PASSED: Creator earnings recorded correctly';

  -- ============================================
  -- Cleanup
  -- ============================================
  RAISE NOTICE '';
  RAISE NOTICE '=== Cleaning up test data ===';

  DELETE FROM public.profiles WHERE email LIKE 'test_%@example.com';

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'ALL TESTS PASSED!';
  RAISE NOTICE '========================================';

EXCEPTION
  WHEN OTHERS THEN
    -- Cleanup on failure
    DELETE FROM public.profiles WHERE email LIKE 'test_%@example.com';
    RAISE;
END $$;
