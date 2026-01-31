# MOE BACKSTAGE - 데이터베이스 설계

## 1. ERD (Entity Relationship Diagram)

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     users       │       │     casts       │       │     teams       │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │──┐    │ id (PK)         │──┐    │ id (PK)         │
│ email           │  │    │ user_id (FK)────│──┼───▶│ name            │
│ password_hash   │  │    │ team_id (FK)────│──┘    │ description     │
│ nickname        │  │    │ stage_name      │       │ manager_id (FK) │
│ role            │  │    │ bio             │       │ created_at      │
│ profile_image   │  │    │ profile_image   │       └─────────────────┘
│ created_at      │  │    │ is_active       │
│ updated_at      │  │    │ created_at      │
└─────────────────┘  │    └─────────────────┘
         │           │             │
         │           │             │
         ▼           │             ▼
┌─────────────────┐  │    ┌─────────────────┐
│  subscriptions  │  │    │    messages     │
├─────────────────┤  │    ├─────────────────┤
│ id (PK)         │  │    │ id (PK)         │
│ fan_id (FK)─────│──┘    │ cast_id (FK)────│───────┐
│ cast_id (FK)────│───────│ content         │       │
│ tier            │       │ type            │       │
│ started_at      │       │ media_url       │       │
│ expires_at      │       │ created_at      │       │
│ is_active       │       └─────────────────┘       │
│ created_at      │                │                │
└─────────────────┘                │                │
         │                         │                │
         │                         ▼                │
         │                ┌─────────────────┐       │
         │                │ message_reads   │       │
         │                ├─────────────────┤       │
         │                │ id (PK)         │       │
         │                │ message_id (FK) │       │
         └───────────────▶│ fan_id (FK)     │       │
                          │ read_at         │       │
                          └─────────────────┘       │
                                                    │
┌─────────────────┐       ┌─────────────────┐       │
│     replies     │       │  reply_tokens   │       │
├─────────────────┤       ├─────────────────┤       │
│ id (PK)         │       │ id (PK)         │       │
│ message_id (FK) │◀──────│ subscription_id │       │
│ fan_id (FK)     │       │ message_id (FK) │◀──────┘
│ content         │       │ total           │
│ created_at      │       │ used            │
└─────────────────┘       │ char_limit      │
                          │ expires_at      │
                          └─────────────────┘

┌─────────────────┐       ┌─────────────────┐
│    contents     │       │    reports      │
├─────────────────┤       ├─────────────────┤
│ id (PK)         │       │ id (PK)         │
│ cast_id (FK)    │       │ reporter_id(FK) │
│ type            │       │ target_type     │
│ title           │       │ target_id       │
│ media_url       │       │ reason          │
│ tier_required   │       │ description     │
│ created_at      │       │ status          │
└─────────────────┘       │ resolved_by(FK) │
                          │ created_at      │
                          └─────────────────┘
```

## 2. 테이블 상세 정의

### 2.1 users (사용자)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'FAN'
        CHECK (role IN ('FAN', 'CAST', 'MANAGER', 'ADMIN')),
    profile_image VARCHAR(500),
    phone VARCHAR(20),
    birth_date DATE,
    gender VARCHAR(10),
    language VARCHAR(10) DEFAULT 'ko',
    push_enabled BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

### 2.2 teams (팀/그룹)

```sql
CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    logo_image VARCHAR(500),
    cover_image VARCHAR(500),
    manager_id UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_teams_manager ON teams(manager_id);
```

### 2.3 casts (캐스트/아이돌)

```sql
CREATE TABLE casts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID REFERENCES teams(id),
    stage_name VARCHAR(50) NOT NULL,
    bio TEXT,
    profile_image VARCHAR(500),
    cover_image VARCHAR(500),
    greeting_message TEXT,
    subscriber_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id)
);

CREATE INDEX idx_casts_team ON casts(team_id);
CREATE INDEX idx_casts_active ON casts(is_active);
```

### 2.4 subscription_tiers (구독 티어 정의)

```sql
CREATE TABLE subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    price_monthly INTEGER NOT NULL,
    reply_tokens_per_message INTEGER DEFAULT 3,
    base_char_limit INTEGER DEFAULT 50,
    features JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 기본 티어 데이터
INSERT INTO subscription_tiers (name, code, price_monthly, reply_tokens_per_message, base_char_limit, features) VALUES
('Basic', 'BASIC', 4500, 3, 50, '{"exclusive_content": false}'),
('Premium', 'PREMIUM', 9900, 5, 150, '{"exclusive_content": true, "priority_notification": true}'),
('Ultimate', 'ULTIMATE', 19900, 7, 200, '{"exclusive_content": true, "priority_notification": true, "voice_video_priority": true}');
```

### 2.5 subscriptions (구독)

```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fan_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cast_id UUID NOT NULL REFERENCES casts(id) ON DELETE CASCADE,
    tier_id UUID NOT NULL REFERENCES subscription_tiers(id),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(fan_id, cast_id)
);

CREATE INDEX idx_subscriptions_fan ON subscriptions(fan_id);
CREATE INDEX idx_subscriptions_cast ON subscriptions(cast_id);
CREATE INDEX idx_subscriptions_active ON subscriptions(is_active);
```

### 2.6 messages (메시지)

```sql
CREATE TYPE message_type AS ENUM ('TEXT', 'IMAGE', 'VOICE', 'VIDEO');

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cast_id UUID NOT NULL REFERENCES casts(id) ON DELETE CASCADE,
    content TEXT,
    type message_type DEFAULT 'TEXT',
    media_url VARCHAR(500),
    media_thumbnail VARCHAR(500),
    tier_required VARCHAR(20) DEFAULT 'BASIC',
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_messages_cast ON messages(cast_id);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_cast_created ON messages(cast_id, created_at DESC);
```

### 2.7 message_reads (메시지 읽음)

```sql
CREATE TABLE message_reads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    fan_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(message_id, fan_id)
);

CREATE INDEX idx_message_reads_fan ON message_reads(fan_id);
```

### 2.8 reply_tokens (답장 토큰)

```sql
CREATE TABLE reply_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    total INTEGER NOT NULL DEFAULT 3,
    used INTEGER NOT NULL DEFAULT 0,
    char_limit INTEGER NOT NULL DEFAULT 50,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(subscription_id, message_id)
);

CREATE INDEX idx_reply_tokens_subscription ON reply_tokens(subscription_id);
CREATE INDEX idx_reply_tokens_message ON reply_tokens(message_id);
```

### 2.9 replies (답장)

```sql
CREATE TABLE replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    fan_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID NOT NULL REFERENCES subscriptions(id),
    content TEXT NOT NULL,
    is_read_by_cast BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    is_hidden BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_replies_message ON replies(message_id);
CREATE INDEX idx_replies_fan ON replies(fan_id);
CREATE INDEX idx_replies_cast_unread ON replies(message_id, is_read_by_cast)
    WHERE is_read_by_cast = false;
```

### 2.10 contents (콘텐츠)

```sql
CREATE TYPE content_type AS ENUM ('PHOTO', 'VIDEO', 'AUDIO', 'POST');

CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cast_id UUID NOT NULL REFERENCES casts(id) ON DELETE CASCADE,
    type content_type NOT NULL,
    title VARCHAR(200),
    description TEXT,
    media_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    tier_required VARCHAR(20) DEFAULT 'BASIC',
    view_count INTEGER DEFAULT 0,
    is_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_contents_cast ON contents(cast_id);
CREATE INDEX idx_contents_type ON contents(type);
CREATE INDEX idx_contents_created ON contents(created_at DESC);
```

### 2.11 reports (신고)

```sql
CREATE TYPE report_status AS ENUM ('PENDING', 'REVIEWING', 'RESOLVED', 'DISMISSED');
CREATE TYPE report_target_type AS ENUM ('MESSAGE', 'REPLY', 'USER', 'CONTENT');

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id),
    target_type report_target_type NOT NULL,
    target_id UUID NOT NULL,
    reason VARCHAR(50) NOT NULL,
    description TEXT,
    evidence_urls TEXT[],
    status report_status DEFAULT 'PENDING',
    severity INTEGER DEFAULT 1 CHECK (severity BETWEEN 1 AND 5),
    resolved_by UUID REFERENCES users(id),
    resolution_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_target ON reports(target_type, target_id);
CREATE INDEX idx_reports_created ON reports(created_at DESC);
```

### 2.12 blocked_patterns (차단 패턴)

```sql
CREATE TABLE blocked_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern VARCHAR(500) NOT NULL,
    pattern_type VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 기본 패턴 데이터
INSERT INTO blocked_patterns (pattern, pattern_type, description) VALUES
-- 전화번호 패턴
('010-?\d{4}-?\d{4}', 'PHONE_KR', '한국 휴대전화'),
('\+82-?\d{2}-?\d{4}-?\d{4}', 'PHONE_KR_INTL', '한국 국제전화'),
-- SNS 패턴
('@[a-zA-Z0-9_]{1,30}', 'SNS_HANDLE', 'SNS 핸들'),
('카[카톡|톡].*아이디', 'KAKAO_ID', '카카오톡 ID 요청'),
('인스타.*[아이디|계정]', 'INSTAGRAM', '인스타그램 계정 요청'),
-- 이메일 패턴
('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'EMAIL', '이메일 주소');
```

### 2.13 user_blocks (사용자 차단)

```sql
CREATE TABLE user_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(blocker_id, blocked_id)
);

CREATE INDEX idx_user_blocks_blocker ON user_blocks(blocker_id);
```

### 2.14 notifications (알림)

```sql
CREATE TYPE notification_type AS ENUM (
    'NEW_MESSAGE', 'NEW_REPLY', 'SUBSCRIPTION_EXPIRING',
    'SUBSCRIPTION_RENEWED', 'CONTENT_UPLOADED', 'SYSTEM'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read)
    WHERE is_read = false;
```

### 2.15 subscription_milestones (구독 마일스톤)

```sql
CREATE TABLE subscription_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    days INTEGER NOT NULL UNIQUE,
    char_limit_bonus INTEGER NOT NULL,
    badge_name VARCHAR(50),
    badge_image VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 기본 마일스톤 데이터
INSERT INTO subscription_milestones (days, char_limit_bonus, badge_name) VALUES
(7, 27, '일주일 친구'),
(30, 50, '한달 친구'),
(100, 150, '백일 친구'),
(365, 450, '일년 친구');
```

## 3. 뷰 (Views)

### 3.1 구독 상세 정보 뷰

```sql
CREATE VIEW v_subscription_details AS
SELECT
    s.id,
    s.fan_id,
    s.cast_id,
    s.started_at,
    s.is_active,
    st.code as tier_code,
    st.name as tier_name,
    st.reply_tokens_per_message,
    st.base_char_limit,
    EXTRACT(DAY FROM (NOW() - s.started_at)) as days_subscribed,
    COALESCE(
        st.base_char_limit + COALESCE(
            (SELECT MAX(char_limit_bonus)
             FROM subscription_milestones
             WHERE days <= EXTRACT(DAY FROM (NOW() - s.started_at))),
            0
        ),
        st.base_char_limit
    ) as current_char_limit
FROM subscriptions s
JOIN subscription_tiers st ON s.tier_id = st.id;
```

### 3.2 캐스트 통계 뷰

```sql
CREATE VIEW v_cast_stats AS
SELECT
    c.id as cast_id,
    c.stage_name,
    COUNT(DISTINCT s.id) FILTER (WHERE s.is_active) as active_subscribers,
    COUNT(DISTINCT m.id) as total_messages,
    COUNT(DISTINCT r.id) as total_replies_received,
    MAX(m.created_at) as last_message_at
FROM casts c
LEFT JOIN subscriptions s ON c.id = s.cast_id
LEFT JOIN messages m ON c.id = m.cast_id
LEFT JOIN replies r ON r.message_id = m.id
GROUP BY c.id, c.stage_name;
```

## 4. 함수 (Functions)

### 4.1 답장 토큰 생성 함수

```sql
CREATE OR REPLACE FUNCTION create_reply_tokens()
RETURNS TRIGGER AS $$
DECLARE
    sub RECORD;
    tier RECORD;
    milestone_bonus INTEGER;
    days_sub INTEGER;
BEGIN
    -- 해당 캐스트의 모든 활성 구독자에게 토큰 생성
    FOR sub IN
        SELECT s.*, v.current_char_limit, v.days_subscribed
        FROM subscriptions s
        JOIN v_subscription_details v ON s.id = v.id
        WHERE s.cast_id = NEW.cast_id AND s.is_active = true
    LOOP
        SELECT * INTO tier FROM subscription_tiers WHERE id = sub.tier_id;

        INSERT INTO reply_tokens (
            subscription_id,
            message_id,
            total,
            char_limit,
            expires_at
        ) VALUES (
            sub.id,
            NEW.id,
            tier.reply_tokens_per_message,
            sub.current_char_limit,
            NEW.created_at + INTERVAL '7 days'
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_reply_tokens
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION create_reply_tokens();
```

### 4.2 구독자 수 갱신 함수

```sql
CREATE OR REPLACE FUNCTION update_subscriber_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.is_active != OLD.is_active) THEN
        UPDATE casts
        SET subscriber_count = (
            SELECT COUNT(*) FROM subscriptions
            WHERE cast_id = NEW.cast_id AND is_active = true
        )
        WHERE id = NEW.cast_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_subscriber_count
AFTER INSERT OR UPDATE ON subscriptions
FOR EACH ROW
EXECUTE FUNCTION update_subscriber_count();
```

## 5. 인덱스 전략

### 5.1 성능 최적화 인덱스

```sql
-- 자주 조회되는 복합 조건
CREATE INDEX idx_messages_cast_tier_created
    ON messages(cast_id, tier_required, created_at DESC);

-- 구독자 메시지 피드 최적화
CREATE INDEX idx_subscriptions_fan_active
    ON subscriptions(fan_id) WHERE is_active = true;

-- 답장 토큰 잔여 확인 최적화
CREATE INDEX idx_reply_tokens_available
    ON reply_tokens(subscription_id, message_id)
    WHERE used < total;
```

## 6. 마이그레이션 순서

1. Enum 타입 생성
2. users 테이블
3. teams 테이블
4. casts 테이블
5. subscription_tiers 테이블
6. subscriptions 테이블
7. messages 테이블
8. message_reads 테이블
9. reply_tokens 테이블
10. replies 테이블
11. contents 테이블
12. reports 테이블
13. blocked_patterns 테이블
14. user_blocks 테이블
15. notifications 테이블
16. subscription_milestones 테이블
17. Views 생성
18. Functions 및 Triggers 생성
19. 추가 인덱스 생성
20. 초기 데이터 삽입
