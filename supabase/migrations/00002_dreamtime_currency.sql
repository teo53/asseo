-- ============================================
-- DreamTime (DT) In-App Currency System
-- Version: 1.0.0
-- ============================================

-- ============================================
-- 1. CONFIGURATION TABLE
-- ============================================

CREATE TABLE public.dt_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Default configuration
INSERT INTO public.dt_config (key, value, description) VALUES
  ('face_value', '1', 'DT to KRW face value (1 DT = 1 KRW)'),
  ('vat_rate', '0.1', 'VAT rate (10%)'),
  ('vat_included', 'true', 'Whether VAT is included in displayed price'),
  ('expiry_years', '5', 'Years until DT lots expire'),
  ('daily_topup_limit', '1000000', 'Daily top-up limit per user in DT'),
  ('platform_fee_rate', '0.2', 'Platform fee rate for creator earnings (20%)'),
  ('promo_first', 'true', 'Spend promo DT before purchased DT'),
  ('refund_window_days', '7', 'Days within which refund is allowed');

-- ============================================
-- 2. EXTEND PROFILES (add role if not exists)
-- ============================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'profiles'
    AND column_name = 'role'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN role TEXT NOT NULL DEFAULT 'user';
  END IF;
END $$;

-- ============================================
-- 3. DT WALLETS
-- ============================================

CREATE TABLE public.dt_wallets (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_purchased BIGINT NOT NULL DEFAULT 0 CHECK (total_purchased >= 0),
  total_promo BIGINT NOT NULL DEFAULT 0 CHECK (total_promo >= 0),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to get or create wallet
CREATE OR REPLACE FUNCTION public.get_or_create_wallet(p_user_id UUID)
RETURNS public.dt_wallets AS $$
DECLARE
  wallet public.dt_wallets;
BEGIN
  SELECT * INTO wallet FROM public.dt_wallets WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.dt_wallets (user_id) VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING
    RETURNING * INTO wallet;

    IF NOT FOUND THEN
      SELECT * INTO wallet FROM public.dt_wallets WHERE user_id = p_user_id;
    END IF;
  END IF;

  RETURN wallet;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. DT LOTS (FIFO tracking)
-- ============================================

CREATE TYPE dt_lot_source AS ENUM ('topup', 'promo', 'adjustment');
CREATE TYPE dt_lot_bucket AS ENUM ('purchased', 'promo');
CREATE TYPE dt_lot_status AS ENUM ('active', 'expired', 'void');

CREATE TABLE public.dt_lots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  source_type dt_lot_source NOT NULL,
  source_id UUID NOT NULL,
  bucket dt_lot_bucket NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  remaining BIGINT NOT NULL CHECK (remaining >= 0),
  purchased_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  status dt_lot_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT remaining_lte_amount CHECK (remaining <= amount),
  CONSTRAINT unique_lot_source UNIQUE (source_type, source_id, user_id, bucket)
);

CREATE INDEX idx_dt_lots_user_bucket_purchased ON public.dt_lots(user_id, bucket, purchased_at ASC);
CREATE INDEX idx_dt_lots_user_expires ON public.dt_lots(user_id, expires_at ASC);
CREATE INDEX idx_dt_lots_active ON public.dt_lots(user_id, status) WHERE status = 'active';

-- ============================================
-- 5. DT TOPUP ORDERS
-- ============================================

CREATE TYPE dt_topup_status AS ENUM ('pending', 'paid', 'failed', 'canceled', 'refunded');
CREATE TYPE dt_payment_provider AS ENUM ('mock', 'portone', 'toss', 'stripe', 'iap_ios', 'iap_android');
CREATE TYPE dt_channel AS ENUM ('web', 'ios', 'android');

CREATE TABLE public.dt_topup_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel dt_channel NOT NULL,
  dt_amount BIGINT NOT NULL CHECK (dt_amount > 0),
  price_krw INTEGER NOT NULL CHECK (price_krw > 0),
  vat_included BOOLEAN NOT NULL DEFAULT true,
  status dt_topup_status NOT NULL DEFAULT 'pending',
  provider dt_payment_provider NOT NULL,
  provider_payment_id TEXT UNIQUE,
  idempotency_key TEXT UNIQUE NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ
);

CREATE INDEX idx_dt_topup_orders_user ON public.dt_topup_orders(user_id);
CREATE INDEX idx_dt_topup_orders_status ON public.dt_topup_orders(status);
CREATE INDEX idx_dt_topup_orders_user_paid ON public.dt_topup_orders(user_id, paid_at)
  WHERE status = 'paid';

-- ============================================
-- 6. DT LEDGER ENTRIES (Append-only audit log)
-- ============================================

CREATE TYPE dt_event_type AS ENUM (
  'topup_paid', 'donation_spend', 'refund', 'promo_grant', 'expire', 'adjust'
);
CREATE TYPE dt_ref_type AS ENUM ('topup', 'donation', 'refund_request', 'promo', 'system');
CREATE TYPE dt_direction AS ENUM ('credit', 'debit');

CREATE TABLE public.dt_ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_type dt_event_type NOT NULL,
  ref_type dt_ref_type NOT NULL,
  ref_id UUID NOT NULL,
  direction dt_direction NOT NULL,
  bucket dt_lot_bucket NOT NULL,
  lot_id UUID REFERENCES public.dt_lots(id),
  amount BIGINT NOT NULL CHECK (amount > 0),
  balance_after BIGINT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate entries
  CONSTRAINT unique_ledger_entry UNIQUE (event_type, ref_type, ref_id, direction, bucket, lot_id)
);

CREATE INDEX idx_dt_ledger_user_created ON public.dt_ledger_entries(user_id, created_at DESC);
CREATE INDEX idx_dt_ledger_ref ON public.dt_ledger_entries(ref_type, ref_id);

-- ============================================
-- 7. DT DONATIONS
-- ============================================

CREATE TYPE dt_donation_status AS ENUM ('completed', 'reversed');
CREATE TYPE dt_context_type AS ENUM ('dm', 'feed', 'content', 'live');

CREATE TABLE public.dt_donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES public.profiles(id),
  to_creator_id UUID NOT NULL REFERENCES public.profiles(id),
  context_type dt_context_type NOT NULL,
  context_id UUID NOT NULL,
  message TEXT,
  is_anonymous BOOLEAN NOT NULL DEFAULT false,
  dt_amount BIGINT NOT NULL CHECK (dt_amount > 0),
  spent_promo BIGINT NOT NULL DEFAULT 0 CHECK (spent_promo >= 0),
  spent_purchased BIGINT NOT NULL DEFAULT 0 CHECK (spent_purchased >= 0),
  status dt_donation_status NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT spent_equals_total CHECK (spent_promo + spent_purchased = dt_amount)
);

CREATE INDEX idx_dt_donations_from ON public.dt_donations(from_user_id, created_at DESC);
CREATE INDEX idx_dt_donations_to ON public.dt_donations(to_creator_id, created_at DESC);

-- ============================================
-- 8. CREATOR EARNINGS LEDGER
-- ============================================

CREATE TYPE earnings_status AS ENUM ('pending', 'payable', 'paid', 'held', 'reversed');

CREATE TABLE public.creator_earnings_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.profiles(id),
  donation_id UUID NOT NULL UNIQUE REFERENCES public.dt_donations(id),
  gross_krw INTEGER NOT NULL CHECK (gross_krw >= 0),
  platform_fee_krw INTEGER NOT NULL CHECK (platform_fee_krw >= 0),
  net_krw INTEGER NOT NULL CHECK (net_krw >= 0),
  status earnings_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fee_calculation CHECK (net_krw = gross_krw - platform_fee_krw)
);

CREATE INDEX idx_creator_earnings_creator ON public.creator_earnings_ledger(creator_id);
CREATE INDEX idx_creator_earnings_status ON public.creator_earnings_ledger(creator_id, status);

-- ============================================
-- 9. DT REFUND REQUESTS
-- ============================================

CREATE TYPE refund_status AS ENUM ('requested', 'approved', 'rejected', 'processed');

CREATE TABLE public.dt_refund_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  topup_order_id UUID NOT NULL UNIQUE REFERENCES public.dt_topup_orders(id),
  reason TEXT,
  status refund_status NOT NULL DEFAULT 'requested',
  admin_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processed_by UUID REFERENCES public.profiles(id)
);

CREATE INDEX idx_dt_refund_requests_user ON public.dt_refund_requests(user_id);
CREATE INDEX idx_dt_refund_requests_status ON public.dt_refund_requests(status);

-- ============================================
-- 10. RLS POLICIES
-- ============================================

ALTER TABLE public.dt_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_lots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_topup_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_earnings_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dt_refund_requests ENABLE ROW LEVEL SECURITY;

-- Config: read-only for all authenticated
CREATE POLICY "Config readable by authenticated" ON public.dt_config
  FOR SELECT TO authenticated USING (true);

-- Wallets: users can only view their own
CREATE POLICY "Users can view own wallet" ON public.dt_wallets
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Lots: users can view their own
CREATE POLICY "Users can view own lots" ON public.dt_lots
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Topup orders: users can view and create their own (pending only)
CREATE POLICY "Users can view own topup orders" ON public.dt_topup_orders
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can create own topup orders" ON public.dt_topup_orders
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Ledger: users can view their own entries
CREATE POLICY "Users can view own ledger" ON public.dt_ledger_entries
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Donations: sender can view their donations, creator can view donations to them
CREATE POLICY "Senders can view their donations" ON public.dt_donations
  FOR SELECT TO authenticated USING (auth.uid() = from_user_id);

CREATE POLICY "Creators can view donations to them" ON public.dt_donations
  FOR SELECT TO authenticated USING (auth.uid() = to_creator_id);

-- Creator earnings: creators can view their own
CREATE POLICY "Creators can view own earnings" ON public.creator_earnings_ledger
  FOR SELECT TO authenticated USING (auth.uid() = creator_id);

-- Refund requests: users can view and create their own
CREATE POLICY "Users can view own refund requests" ON public.dt_refund_requests
  FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can create refund requests" ON public.dt_refund_requests
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 11. REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.dt_wallets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dt_donations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dt_ledger_entries;
