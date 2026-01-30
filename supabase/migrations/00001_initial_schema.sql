-- MOE BACKSTAGE - Initial Database Schema for Supabase
-- Supabase + Flutter 기반 팬 커뮤니케이션 앱

-- ============================================
-- 1. ENUM TYPES
-- ============================================

CREATE TYPE user_role AS ENUM ('FAN', 'CAST', 'MANAGER', 'ADMIN');
CREATE TYPE message_type AS ENUM ('TEXT', 'IMAGE', 'VOICE', 'VIDEO');
CREATE TYPE content_type AS ENUM ('PHOTO', 'VIDEO', 'AUDIO', 'POST');
CREATE TYPE report_status AS ENUM ('PENDING', 'REVIEWING', 'RESOLVED', 'DISMISSED');
CREATE TYPE report_target_type AS ENUM ('MESSAGE', 'REPLY', 'USER', 'CONTENT');
CREATE TYPE notification_type AS ENUM (
  'NEW_MESSAGE', 'NEW_REPLY', 'SUBSCRIPTION_EXPIRING',
  'SUBSCRIPTION_RENEWED', 'CONTENT_UPLOADED', 'SYSTEM'
);

-- ============================================
-- 2. USERS (Supabase Auth 연동)
-- ============================================

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  nickname TEXT NOT NULL,
  role user_role DEFAULT 'FAN',
  profile_image TEXT,
  phone TEXT,
  birth_date DATE,
  gender TEXT,
  language TEXT DEFAULT 'ko',
  push_enabled BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 프로필 정책
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================
-- 3. TEAMS
-- ============================================

CREATE TABLE public.teams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  logo_image TEXT,
  cover_image TEXT,
  manager_id UUID REFERENCES public.profiles(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teams are viewable by everyone"
  ON public.teams FOR SELECT
  USING (is_active = true);

-- ============================================
-- 4. CASTS (캐스트/아이돌)
-- ============================================

CREATE TABLE public.casts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
  team_id UUID REFERENCES public.teams(id),
  stage_name TEXT NOT NULL,
  bio TEXT,
  profile_image TEXT,
  cover_image TEXT,
  greeting_message TEXT,
  subscriber_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.casts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active casts are viewable by everyone"
  ON public.casts FOR SELECT
  USING (is_active = true);

CREATE POLICY "Cast can update own profile"
  ON public.casts FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- 5. SUBSCRIPTION TIERS
-- ============================================

CREATE TABLE public.subscription_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  price_monthly INTEGER NOT NULL,
  reply_tokens_per_message INTEGER DEFAULT 3,
  base_char_limit INTEGER DEFAULT 50,
  features JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 티어 데이터
INSERT INTO public.subscription_tiers (name, code, price_monthly, reply_tokens_per_message, base_char_limit, features) VALUES
  ('Basic', 'BASIC', 4500, 3, 50, '{"exclusive_content": false}'),
  ('Premium', 'PREMIUM', 9900, 5, 150, '{"exclusive_content": true, "priority_notification": true}'),
  ('Ultimate', 'ULTIMATE', 19900, 7, 200, '{"exclusive_content": true, "priority_notification": true, "voice_video_priority": true}');

ALTER TABLE public.subscription_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tiers are viewable by everyone"
  ON public.subscription_tiers FOR SELECT
  USING (is_active = true);

-- ============================================
-- 6. SUBSCRIPTION MILESTONES
-- ============================================

CREATE TABLE public.subscription_milestones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  days INTEGER NOT NULL UNIQUE,
  char_limit_bonus INTEGER NOT NULL,
  badge_name TEXT,
  badge_image TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 마일스톤 데이터
INSERT INTO public.subscription_milestones (days, char_limit_bonus, badge_name) VALUES
  (7, 27, '일주일 친구'),
  (30, 50, '한달 친구'),
  (100, 150, '백일 친구'),
  (365, 450, '일년 친구');

ALTER TABLE public.subscription_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Milestones are viewable by everyone"
  ON public.subscription_milestones FOR SELECT
  USING (true);

-- ============================================
-- 7. SUBSCRIPTIONS
-- ============================================

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fan_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cast_id UUID NOT NULL REFERENCES public.casts(id) ON DELETE CASCADE,
  tier_id UUID NOT NULL REFERENCES public.subscription_tiers(id),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(fan_id, cast_id)
);

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own subscriptions"
  ON public.subscriptions FOR SELECT
  USING (auth.uid() = fan_id);

CREATE POLICY "Users can create subscriptions"
  ON public.subscriptions FOR INSERT
  WITH CHECK (auth.uid() = fan_id);

CREATE POLICY "Users can update own subscriptions"
  ON public.subscriptions FOR UPDATE
  USING (auth.uid() = fan_id);

-- ============================================
-- 8. MESSAGES
-- ============================================

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cast_id UUID NOT NULL REFERENCES public.casts(id) ON DELETE CASCADE,
  content TEXT,
  type message_type DEFAULT 'TEXT',
  media_url TEXT,
  media_thumbnail TEXT,
  tier_required TEXT DEFAULT 'BASIC',
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 구독자만 메시지 조회 가능
CREATE POLICY "Subscribers can view messages"
  ON public.messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.fan_id = auth.uid()
        AND s.cast_id = messages.cast_id
        AND s.is_active = true
    )
    OR
    EXISTS (
      SELECT 1 FROM public.casts c
      WHERE c.id = messages.cast_id
        AND c.user_id = auth.uid()
    )
  );

-- 캐스트만 메시지 작성 가능
CREATE POLICY "Casts can create messages"
  ON public.messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.casts c
      WHERE c.id = cast_id AND c.user_id = auth.uid()
    )
  );

-- ============================================
-- 9. MESSAGE READS
-- ============================================

CREATE TABLE public.message_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  fan_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, fan_id)
);

ALTER TABLE public.message_reads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own reads"
  ON public.message_reads FOR SELECT
  USING (auth.uid() = fan_id);

CREATE POLICY "Users can mark as read"
  ON public.message_reads FOR INSERT
  WITH CHECK (auth.uid() = fan_id);

-- ============================================
-- 10. REPLY TOKENS
-- ============================================

CREATE TABLE public.reply_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  total INTEGER DEFAULT 3,
  used INTEGER DEFAULT 0,
  char_limit INTEGER DEFAULT 50,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subscription_id, message_id)
);

ALTER TABLE public.reply_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tokens"
  ON public.reply_tokens FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.id = reply_tokens.subscription_id
        AND s.fan_id = auth.uid()
    )
  );

-- ============================================
-- 11. REPLIES
-- ============================================

CREATE TABLE public.replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  fan_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id),
  content TEXT NOT NULL,
  is_read_by_cast BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  is_hidden BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fans can view own replies"
  ON public.replies FOR SELECT
  USING (auth.uid() = fan_id);

CREATE POLICY "Casts can view replies to their messages"
  ON public.replies FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.messages m
      JOIN public.casts c ON c.id = m.cast_id
      WHERE m.id = replies.message_id
        AND c.user_id = auth.uid()
    )
  );

CREATE POLICY "Fans can create replies"
  ON public.replies FOR INSERT
  WITH CHECK (auth.uid() = fan_id);

-- ============================================
-- 12. CONTENTS
-- ============================================

CREATE TABLE public.contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cast_id UUID NOT NULL REFERENCES public.casts(id) ON DELETE CASCADE,
  type content_type NOT NULL,
  title TEXT,
  description TEXT,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  tier_required TEXT DEFAULT 'BASIC',
  view_count INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.contents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Subscribers can view contents"
  ON public.contents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.subscriptions s
      WHERE s.fan_id = auth.uid()
        AND s.cast_id = contents.cast_id
        AND s.is_active = true
    )
  );

-- ============================================
-- 13. BLOCKED PATTERNS (모더레이션)
-- ============================================

CREATE TABLE public.blocked_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern TEXT NOT NULL,
  pattern_type TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 패턴 데이터
INSERT INTO public.blocked_patterns (pattern, pattern_type, description) VALUES
  ('010-?\d{4}-?\d{4}', 'PHONE_KR', '한국 휴대전화'),
  ('\+82-?\d{2}-?\d{4}-?\d{4}', 'PHONE_KR_INTL', '한국 국제전화'),
  ('@[a-zA-Z0-9_]{1,30}', 'SNS_HANDLE', 'SNS 핸들'),
  ('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'EMAIL', '이메일 주소');

ALTER TABLE public.blocked_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patterns viewable by admins"
  ON public.blocked_patterns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'ADMIN'
    )
  );

-- ============================================
-- 14. REPORTS
-- ============================================

CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.profiles(id),
  target_type report_target_type NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  evidence_urls TEXT[],
  status report_status DEFAULT 'PENDING',
  severity INTEGER DEFAULT 1 CHECK (severity BETWEEN 1 AND 5),
  resolved_by UUID REFERENCES public.profiles(id),
  resolution_note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports"
  ON public.reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view own reports"
  ON public.reports FOR SELECT
  USING (auth.uid() = reporter_id);

-- ============================================
-- 15. NOTIFICATIONS
-- ============================================

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- 16. INDEXES
-- ============================================

CREATE INDEX idx_casts_team ON public.casts(team_id);
CREATE INDEX idx_casts_active ON public.casts(is_active);
CREATE INDEX idx_subscriptions_fan ON public.subscriptions(fan_id);
CREATE INDEX idx_subscriptions_cast ON public.subscriptions(cast_id);
CREATE INDEX idx_subscriptions_active ON public.subscriptions(is_active);
CREATE INDEX idx_messages_cast ON public.messages(cast_id);
CREATE INDEX idx_messages_created ON public.messages(created_at DESC);
CREATE INDEX idx_replies_message ON public.replies(message_id);
CREATE INDEX idx_replies_fan ON public.replies(fan_id);
CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- 17. FUNCTIONS
-- ============================================

-- 프로필 자동 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nickname)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nickname', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 구독자 수 업데이트 함수
CREATE OR REPLACE FUNCTION public.update_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.is_active != OLD.is_active) THEN
    UPDATE public.casts
    SET subscriber_count = (
      SELECT COUNT(*) FROM public.subscriptions
      WHERE cast_id = NEW.cast_id AND is_active = true
    )
    WHERE id = NEW.cast_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_subscription_change
  AFTER INSERT OR UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_subscriber_count();

-- 답장 토큰 생성 함수
CREATE OR REPLACE FUNCTION public.create_reply_tokens_for_message()
RETURNS TRIGGER AS $$
DECLARE
  sub RECORD;
  tier RECORD;
  milestone RECORD;
  days_sub INTEGER;
  char_limit INTEGER;
BEGIN
  FOR sub IN
    SELECT s.*, t.reply_tokens_per_message, t.base_char_limit
    FROM public.subscriptions s
    JOIN public.subscription_tiers t ON t.id = s.tier_id
    WHERE s.cast_id = NEW.cast_id AND s.is_active = true
  LOOP
    days_sub := EXTRACT(DAY FROM (NOW() - sub.started_at));
    char_limit := sub.base_char_limit;

    -- 마일스톤 보너스 적용
    SELECT char_limit_bonus INTO milestone
    FROM public.subscription_milestones
    WHERE days <= days_sub
    ORDER BY days DESC
    LIMIT 1;

    IF milestone IS NOT NULL THEN
      char_limit := sub.base_char_limit + milestone.char_limit_bonus;
    END IF;

    INSERT INTO public.reply_tokens (subscription_id, message_id, total, char_limit, expires_at)
    VALUES (
      sub.id,
      NEW.id,
      sub.reply_tokens_per_message,
      char_limit,
      NEW.created_at + INTERVAL '7 days'
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_message_created
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.create_reply_tokens_for_message();

-- ============================================
-- 18. REALTIME 활성화
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.replies;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
