-- ============================================
-- DreamTime (DT) Database Functions
-- Critical transactional operations with row locks
-- ============================================

-- ============================================
-- HELPER: Get config value
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_get_config(p_key TEXT)
RETURNS JSONB AS $$
  SELECT value FROM public.dt_config WHERE key = p_key;
$$ LANGUAGE sql STABLE;

-- ============================================
-- HELPER: Check daily topup limit
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_check_daily_limit(
  p_user_id UUID,
  p_new_amount BIGINT
) RETURNS BOOLEAN AS $$
DECLARE
  v_daily_limit BIGINT;
  v_today_total BIGINT;
BEGIN
  v_daily_limit := (public.dt_get_config('daily_topup_limit'))::BIGINT;

  SELECT COALESCE(SUM(dt_amount), 0) INTO v_today_total
  FROM public.dt_topup_orders
  WHERE user_id = p_user_id
    AND status = 'paid'
    AND paid_at >= CURRENT_DATE
    AND paid_at < CURRENT_DATE + INTERVAL '1 day';

  RETURN (v_today_total + p_new_amount) <= v_daily_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================
-- HELPER: Mark expired lots
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_expire_lots(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_expired_count INTEGER;
  v_lot RECORD;
BEGIN
  v_expired_count := 0;

  FOR v_lot IN
    SELECT id, remaining, bucket
    FROM public.dt_lots
    WHERE user_id = p_user_id
      AND status = 'active'
      AND expires_at <= NOW()
    FOR UPDATE
  LOOP
    -- Mark lot as expired
    UPDATE public.dt_lots
    SET status = 'expired', remaining = 0
    WHERE id = v_lot.id;

    -- Update wallet totals
    IF v_lot.bucket = 'purchased' THEN
      UPDATE public.dt_wallets
      SET total_purchased = total_purchased - v_lot.remaining,
          updated_at = NOW()
      WHERE user_id = p_user_id;
    ELSE
      UPDATE public.dt_wallets
      SET total_promo = total_promo - v_lot.remaining,
          updated_at = NOW()
      WHERE user_id = p_user_id;
    END IF;

    -- Log expiration
    IF v_lot.remaining > 0 THEN
      INSERT INTO public.dt_ledger_entries (
        user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount, balance_after
      )
      SELECT
        p_user_id, 'expire', 'system', v_lot.id, 'debit', v_lot.bucket, v_lot.id, v_lot.remaining,
        CASE v_lot.bucket
          WHEN 'purchased' THEN (SELECT total_purchased FROM public.dt_wallets WHERE user_id = p_user_id)
          ELSE (SELECT total_promo FROM public.dt_wallets WHERE user_id = p_user_id)
        END;
    END IF;

    v_expired_count := v_expired_count + 1;
  END LOOP;

  RETURN v_expired_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- CREDIT: Topup paid -> Create lot + update wallet
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_credit_topup(
  p_order_id UUID
) RETURNS TABLE (
  success BOOLEAN,
  lot_id UUID,
  error TEXT
) AS $$
DECLARE
  v_order public.dt_topup_orders;
  v_wallet public.dt_wallets;
  v_lot_id UUID;
  v_expiry_years INTEGER;
  v_new_balance BIGINT;
BEGIN
  -- Lock and get order
  SELECT * INTO v_order
  FROM public.dt_topup_orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, NULL::UUID, 'Order not found';
    RETURN;
  END IF;

  -- Check if already processed (idempotency)
  IF v_order.status != 'pending' THEN
    -- If already paid, return the existing lot
    IF v_order.status = 'paid' THEN
      SELECT id INTO v_lot_id
      FROM public.dt_lots
      WHERE source_type = 'topup' AND source_id = p_order_id AND user_id = v_order.user_id;

      RETURN QUERY SELECT true, v_lot_id, NULL::TEXT;
      RETURN;
    END IF;

    RETURN QUERY SELECT false, NULL::UUID, 'Order already processed with status: ' || v_order.status::TEXT;
    RETURN;
  END IF;

  -- Check daily limit
  IF NOT public.dt_check_daily_limit(v_order.user_id, v_order.dt_amount) THEN
    RETURN QUERY SELECT false, NULL::UUID, 'Daily top-up limit exceeded';
    RETURN;
  END IF;

  -- Get or create wallet with lock
  PERFORM public.get_or_create_wallet(v_order.user_id);

  SELECT * INTO v_wallet
  FROM public.dt_wallets
  WHERE user_id = v_order.user_id
  FOR UPDATE;

  -- Get expiry config
  v_expiry_years := (public.dt_get_config('expiry_years'))::INTEGER;

  -- Create lot
  INSERT INTO public.dt_lots (
    user_id, source_type, source_id, bucket, amount, remaining, purchased_at, expires_at
  ) VALUES (
    v_order.user_id,
    'topup',
    p_order_id,
    'purchased',
    v_order.dt_amount,
    v_order.dt_amount,
    NOW(),
    NOW() + (v_expiry_years || ' years')::INTERVAL
  )
  RETURNING id INTO v_lot_id;

  -- Update wallet
  v_new_balance := v_wallet.total_purchased + v_order.dt_amount;

  UPDATE public.dt_wallets
  SET total_purchased = v_new_balance, updated_at = NOW()
  WHERE user_id = v_order.user_id;

  -- Update order status
  UPDATE public.dt_topup_orders
  SET status = 'paid', paid_at = NOW()
  WHERE id = p_order_id;

  -- Create ledger entry
  INSERT INTO public.dt_ledger_entries (
    user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount, balance_after, description
  ) VALUES (
    v_order.user_id,
    'topup_paid',
    'topup',
    p_order_id,
    'credit',
    'purchased',
    v_lot_id,
    v_order.dt_amount,
    v_new_balance,
    'Top-up ' || v_order.dt_amount || ' DT via ' || v_order.provider::TEXT
  );

  RETURN QUERY SELECT true, v_lot_id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SPEND: FIFO lot consumption for donation
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_spend_donation(
  p_from_user_id UUID,
  p_to_creator_id UUID,
  p_context_type dt_context_type,
  p_context_id UUID,
  p_message TEXT,
  p_is_anonymous BOOLEAN,
  p_dt_amount BIGINT
) RETURNS TABLE (
  success BOOLEAN,
  donation_id UUID,
  spent_promo BIGINT,
  spent_purchased BIGINT,
  error TEXT
) AS $$
DECLARE
  v_wallet public.dt_wallets;
  v_promo_first BOOLEAN;
  v_total_available BIGINT;
  v_remaining_to_spend BIGINT;
  v_spent_promo BIGINT := 0;
  v_spent_purchased BIGINT := 0;
  v_donation_id UUID;
  v_lot RECORD;
  v_consume_amount BIGINT;
  v_platform_fee_rate NUMERIC;
  v_gross_krw INTEGER;
  v_platform_fee INTEGER;
  v_net_krw INTEGER;
BEGIN
  -- Validate amount
  IF p_dt_amount <= 0 THEN
    RETURN QUERY SELECT false, NULL::UUID, 0::BIGINT, 0::BIGINT, 'Invalid amount';
    RETURN;
  END IF;

  -- Validate not self-donation
  IF p_from_user_id = p_to_creator_id THEN
    RETURN QUERY SELECT false, NULL::UUID, 0::BIGINT, 0::BIGINT, 'Cannot donate to yourself';
    RETURN;
  END IF;

  -- Get or create wallet with lock
  PERFORM public.get_or_create_wallet(p_from_user_id);

  -- Expire any expired lots first
  PERFORM public.dt_expire_lots(p_from_user_id);

  -- Lock wallet
  SELECT * INTO v_wallet
  FROM public.dt_wallets
  WHERE user_id = p_from_user_id
  FOR UPDATE;

  -- Check balance
  v_total_available := v_wallet.total_promo + v_wallet.total_purchased;
  IF v_total_available < p_dt_amount THEN
    RETURN QUERY SELECT false, NULL::UUID, 0::BIGINT, 0::BIGINT, 'Insufficient balance';
    RETURN;
  END IF;

  -- Get spending order config
  v_promo_first := (public.dt_get_config('promo_first'))::BOOLEAN;

  -- Create donation record first
  INSERT INTO public.dt_donations (
    from_user_id, to_creator_id, context_type, context_id,
    message, is_anonymous, dt_amount, spent_promo, spent_purchased
  ) VALUES (
    p_from_user_id, p_to_creator_id, p_context_type, p_context_id,
    p_message, p_is_anonymous, p_dt_amount, 0, 0
  )
  RETURNING id INTO v_donation_id;

  v_remaining_to_spend := p_dt_amount;

  -- FIFO consumption: promo first (if configured), then purchased
  IF v_promo_first AND v_wallet.total_promo > 0 THEN
    FOR v_lot IN
      SELECT id, remaining
      FROM public.dt_lots
      WHERE user_id = p_from_user_id
        AND bucket = 'promo'
        AND status = 'active'
        AND remaining > 0
        AND expires_at > NOW()
      ORDER BY purchased_at ASC
      FOR UPDATE
    LOOP
      EXIT WHEN v_remaining_to_spend <= 0;

      v_consume_amount := LEAST(v_lot.remaining, v_remaining_to_spend);

      -- Update lot
      UPDATE public.dt_lots
      SET remaining = remaining - v_consume_amount
      WHERE id = v_lot.id;

      -- Ledger entry
      INSERT INTO public.dt_ledger_entries (
        user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount,
        balance_after, description
      ) VALUES (
        p_from_user_id, 'donation_spend', 'donation', v_donation_id, 'debit', 'promo', v_lot.id,
        v_consume_amount, v_wallet.total_promo - v_spent_promo - v_consume_amount,
        'Donation to creator'
      );

      v_spent_promo := v_spent_promo + v_consume_amount;
      v_remaining_to_spend := v_remaining_to_spend - v_consume_amount;
    END LOOP;
  END IF;

  -- Consume purchased lots
  IF v_remaining_to_spend > 0 THEN
    FOR v_lot IN
      SELECT id, remaining
      FROM public.dt_lots
      WHERE user_id = p_from_user_id
        AND bucket = 'purchased'
        AND status = 'active'
        AND remaining > 0
        AND expires_at > NOW()
      ORDER BY purchased_at ASC
      FOR UPDATE
    LOOP
      EXIT WHEN v_remaining_to_spend <= 0;

      v_consume_amount := LEAST(v_lot.remaining, v_remaining_to_spend);

      -- Update lot
      UPDATE public.dt_lots
      SET remaining = remaining - v_consume_amount
      WHERE id = v_lot.id;

      -- Ledger entry
      INSERT INTO public.dt_ledger_entries (
        user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount,
        balance_after, description
      ) VALUES (
        p_from_user_id, 'donation_spend', 'donation', v_donation_id, 'debit', 'purchased', v_lot.id,
        v_consume_amount, v_wallet.total_purchased - v_spent_purchased - v_consume_amount,
        'Donation to creator'
      );

      v_spent_purchased := v_spent_purchased + v_consume_amount;
      v_remaining_to_spend := v_remaining_to_spend - v_consume_amount;
    END LOOP;
  END IF;

  -- Consume promo if not done first
  IF NOT v_promo_first AND v_remaining_to_spend > 0 THEN
    FOR v_lot IN
      SELECT id, remaining
      FROM public.dt_lots
      WHERE user_id = p_from_user_id
        AND bucket = 'promo'
        AND status = 'active'
        AND remaining > 0
        AND expires_at > NOW()
      ORDER BY purchased_at ASC
      FOR UPDATE
    LOOP
      EXIT WHEN v_remaining_to_spend <= 0;

      v_consume_amount := LEAST(v_lot.remaining, v_remaining_to_spend);

      UPDATE public.dt_lots
      SET remaining = remaining - v_consume_amount
      WHERE id = v_lot.id;

      INSERT INTO public.dt_ledger_entries (
        user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount,
        balance_after, description
      ) VALUES (
        p_from_user_id, 'donation_spend', 'donation', v_donation_id, 'debit', 'promo', v_lot.id,
        v_consume_amount, v_wallet.total_promo - v_spent_promo - v_consume_amount,
        'Donation to creator'
      );

      v_spent_promo := v_spent_promo + v_consume_amount;
      v_remaining_to_spend := v_remaining_to_spend - v_consume_amount;
    END LOOP;
  END IF;

  -- Should never happen if balance check passed
  IF v_remaining_to_spend > 0 THEN
    RAISE EXCEPTION 'Insufficient lot balance for spending';
  END IF;

  -- Update donation with actual spent amounts
  UPDATE public.dt_donations
  SET spent_promo = v_spent_promo, spent_purchased = v_spent_purchased
  WHERE id = v_donation_id;

  -- Update wallet totals
  UPDATE public.dt_wallets
  SET
    total_promo = total_promo - v_spent_promo,
    total_purchased = total_purchased - v_spent_purchased,
    updated_at = NOW()
  WHERE user_id = p_from_user_id;

  -- Create creator earnings
  v_platform_fee_rate := (public.dt_get_config('platform_fee_rate'))::NUMERIC;
  v_gross_krw := p_dt_amount; -- 1 DT = 1 KRW
  v_platform_fee := FLOOR(v_gross_krw * v_platform_fee_rate);
  v_net_krw := v_gross_krw - v_platform_fee;

  INSERT INTO public.creator_earnings_ledger (
    creator_id, donation_id, gross_krw, platform_fee_krw, net_krw
  ) VALUES (
    p_to_creator_id, v_donation_id, v_gross_krw, v_platform_fee, v_net_krw
  );

  RETURN QUERY SELECT true, v_donation_id, v_spent_promo, v_spent_purchased, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- REFUND: Check eligibility
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_check_refund_eligibility(
  p_topup_order_id UUID
) RETURNS TABLE (
  eligible BOOLEAN,
  reason TEXT
) AS $$
DECLARE
  v_order public.dt_topup_orders;
  v_lot public.dt_lots;
  v_refund_window INTEGER;
BEGIN
  -- Get refund window config
  v_refund_window := (public.dt_get_config('refund_window_days'))::INTEGER;

  -- Get order
  SELECT * INTO v_order
  FROM public.dt_topup_orders
  WHERE id = p_topup_order_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Order not found';
    RETURN;
  END IF;

  -- Check order status
  IF v_order.status != 'paid' THEN
    RETURN QUERY SELECT false, 'Order is not in paid status';
    RETURN;
  END IF;

  -- Check refund window
  IF v_order.paid_at < NOW() - (v_refund_window || ' days')::INTERVAL THEN
    RETURN QUERY SELECT false, 'Refund window has expired (must be within ' || v_refund_window || ' days)';
    RETURN;
  END IF;

  -- Check if lot is unused
  SELECT * INTO v_lot
  FROM public.dt_lots
  WHERE source_type = 'topup'
    AND source_id = p_topup_order_id
    AND user_id = v_order.user_id
    AND bucket = 'purchased';

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Lot not found for this order';
    RETURN;
  END IF;

  IF v_lot.status != 'active' THEN
    RETURN QUERY SELECT false, 'Lot is not active (status: ' || v_lot.status::TEXT || ')';
    RETURN;
  END IF;

  IF v_lot.remaining != v_lot.amount THEN
    RETURN QUERY SELECT false, 'Lot has been partially used (remaining: ' || v_lot.remaining || '/' || v_lot.amount || ')';
    RETURN;
  END IF;

  -- Check if refund already requested
  IF EXISTS (SELECT 1 FROM public.dt_refund_requests WHERE topup_order_id = p_topup_order_id) THEN
    RETURN QUERY SELECT false, 'Refund already requested for this order';
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Eligible for full refund';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- REFUND: Process (admin only)
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_process_refund(
  p_refund_request_id UUID,
  p_admin_id UUID
) RETURNS TABLE (
  success BOOLEAN,
  error TEXT
) AS $$
DECLARE
  v_request public.dt_refund_requests;
  v_order public.dt_topup_orders;
  v_lot public.dt_lots;
  v_wallet public.dt_wallets;
  v_eligibility RECORD;
BEGIN
  -- Lock refund request
  SELECT * INTO v_request
  FROM public.dt_refund_requests
  WHERE id = p_refund_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Refund request not found';
    RETURN;
  END IF;

  IF v_request.status != 'requested' AND v_request.status != 'approved' THEN
    RETURN QUERY SELECT false, 'Refund request is not in processable status';
    RETURN;
  END IF;

  -- Check eligibility again
  SELECT * INTO v_eligibility
  FROM public.dt_check_refund_eligibility(v_request.topup_order_id);

  IF NOT v_eligibility.eligible THEN
    -- Reject the request
    UPDATE public.dt_refund_requests
    SET status = 'rejected', admin_note = v_eligibility.reason, processed_at = NOW(), processed_by = p_admin_id
    WHERE id = p_refund_request_id;

    RETURN QUERY SELECT false, v_eligibility.reason;
    RETURN;
  END IF;

  -- Get order with lock
  SELECT * INTO v_order
  FROM public.dt_topup_orders
  WHERE id = v_request.topup_order_id
  FOR UPDATE;

  -- Get lot with lock
  SELECT * INTO v_lot
  FROM public.dt_lots
  WHERE source_type = 'topup'
    AND source_id = v_request.topup_order_id
    AND user_id = v_order.user_id
  FOR UPDATE;

  -- Get wallet with lock
  SELECT * INTO v_wallet
  FROM public.dt_wallets
  WHERE user_id = v_order.user_id
  FOR UPDATE;

  -- Void the lot
  UPDATE public.dt_lots
  SET status = 'void', remaining = 0
  WHERE id = v_lot.id;

  -- Update wallet
  UPDATE public.dt_wallets
  SET total_purchased = total_purchased - v_lot.amount, updated_at = NOW()
  WHERE user_id = v_order.user_id;

  -- Mark order as refunded
  UPDATE public.dt_topup_orders
  SET status = 'refunded', refunded_at = NOW()
  WHERE id = v_request.topup_order_id;

  -- Create ledger entry
  INSERT INTO public.dt_ledger_entries (
    user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount, balance_after, description
  ) VALUES (
    v_order.user_id, 'refund', 'refund_request', p_refund_request_id, 'debit', 'purchased', v_lot.id,
    v_lot.amount, v_wallet.total_purchased - v_lot.amount,
    'Refund for order ' || v_order.id::TEXT
  );

  -- Update refund request
  UPDATE public.dt_refund_requests
  SET status = 'processed', processed_at = NOW(), processed_by = p_admin_id
  WHERE id = p_refund_request_id;

  RETURN QUERY SELECT true, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PROMO: Grant promotional DT
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_grant_promo(
  p_user_id UUID,
  p_amount BIGINT,
  p_source_id UUID,
  p_description TEXT DEFAULT 'Promotional grant'
) RETURNS TABLE (
  success BOOLEAN,
  lot_id UUID,
  error TEXT
) AS $$
DECLARE
  v_wallet public.dt_wallets;
  v_lot_id UUID;
  v_expiry_years INTEGER;
  v_new_balance BIGINT;
BEGIN
  IF p_amount <= 0 THEN
    RETURN QUERY SELECT false, NULL::UUID, 'Invalid amount';
    RETURN;
  END IF;

  -- Get or create wallet with lock
  PERFORM public.get_or_create_wallet(p_user_id);

  SELECT * INTO v_wallet
  FROM public.dt_wallets
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Get expiry config
  v_expiry_years := (public.dt_get_config('expiry_years'))::INTEGER;

  -- Create promo lot
  INSERT INTO public.dt_lots (
    user_id, source_type, source_id, bucket, amount, remaining, purchased_at, expires_at
  ) VALUES (
    p_user_id, 'promo', p_source_id, 'promo', p_amount, p_amount, NOW(),
    NOW() + (v_expiry_years || ' years')::INTERVAL
  )
  RETURNING id INTO v_lot_id;

  -- Update wallet
  v_new_balance := v_wallet.total_promo + p_amount;

  UPDATE public.dt_wallets
  SET total_promo = v_new_balance, updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Ledger entry
  INSERT INTO public.dt_ledger_entries (
    user_id, event_type, ref_type, ref_id, direction, bucket, lot_id, amount, balance_after, description
  ) VALUES (
    p_user_id, 'promo_grant', 'promo', p_source_id, 'credit', 'promo', v_lot_id, p_amount, v_new_balance, p_description
  );

  RETURN QUERY SELECT true, v_lot_id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VIEW: Wallet summary with expiring lots
-- ============================================

CREATE OR REPLACE FUNCTION public.dt_get_wallet_summary(p_user_id UUID)
RETURNS TABLE (
  total_purchased BIGINT,
  total_promo BIGINT,
  total_balance BIGINT,
  expiring_soon_amount BIGINT,
  expiring_soon_date TIMESTAMPTZ
) AS $$
DECLARE
  v_wallet public.dt_wallets;
BEGIN
  -- Ensure wallet exists
  PERFORM public.get_or_create_wallet(p_user_id);

  -- Expire old lots
  PERFORM public.dt_expire_lots(p_user_id);

  -- Get wallet
  SELECT * INTO v_wallet FROM public.dt_wallets WHERE user_id = p_user_id;

  RETURN QUERY
  SELECT
    v_wallet.total_purchased,
    v_wallet.total_promo,
    v_wallet.total_purchased + v_wallet.total_promo,
    COALESCE((
      SELECT SUM(remaining)
      FROM public.dt_lots
      WHERE user_id = p_user_id
        AND status = 'active'
        AND expires_at <= NOW() + INTERVAL '30 days'
    ), 0)::BIGINT,
    (
      SELECT MIN(expires_at)
      FROM public.dt_lots
      WHERE user_id = p_user_id
        AND status = 'active'
        AND remaining > 0
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
