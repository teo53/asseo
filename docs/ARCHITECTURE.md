# MOE BACKSTAGE - 시스템 아키텍처 설계서

## 1. 개요

### 1.1 제품 정의
지하아이돌·메이드 문화 특화 팬 커뮤니케이션 앱으로, 버블/프롬 스타일의 "1:1처럼 보이는 프라이빗 메시지" 경험을 제공합니다.

### 1.2 핵심 가치
- **프라이빗 메시지**: 캐스트가 보내는 메시지를 1:1 채팅 UI로 수신
- **답장 제한/보상**: 관계 지속에 따른 답장 권한 확대
- **안전한 친밀감**: 강력한 모더레이션과 개인정보 보호

### 1.3 제외 범위 (현장 기능)
- 특전회/체키 타임슬롯 예약
- 현장 체크인 (QR)
- 매장/공연장 운영자 역할
- 입장권/슬롯권
- 노쇼 방지 시스템

## 2. 사용자 역할

| 역할 | 설명 | 주요 기능 |
|------|------|----------|
| Fan (팬) | 구독자, 메시지 수신자 | 채팅방 구독, 메시지 수신, 답장, 콘텐츠 열람 |
| Cast (캐스트) | 아이돌/메이드 | 메시지 발송, 콘텐츠 업로드, 답장 확인 |
| Manager (매니지먼트) | 팀/그룹 운영 | 캐스트 관리, 상품 등록, 정산 확인 |
| Admin (관리자) | 시스템 운영 | 신고 처리, 정책 관리, 시스템 모니터링 |

## 3. 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                         Client Layer                            │
├─────────────────┬─────────────────┬─────────────────────────────┤
│  iOS/Android    │  iOS/Android    │      Web Console            │
│   Fan App       │   Cast App      │   (Manager/Admin)           │
│ (React Native)  │ (React Native)  │      (Next.js)              │
└────────┬────────┴────────┬────────┴─────────────┬───────────────┘
         │                 │                      │
         └─────────────────┼──────────────────────┘
                           │
                    ┌──────▼──────┐
                    │ API Gateway │
                    │  (nginx)    │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
┌────────▼────────┐ ┌──────▼──────┐ ┌───────▼───────┐
│   Auth Service  │ │ Core API    │ │ WebSocket     │
│   (JWT/OAuth)   │ │ (NestJS)    │ │ Server        │
└────────┬────────┘ └──────┬──────┘ └───────┬───────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
┌────────▼────────┐ ┌──────▼──────┐ ┌───────▼───────┐
│   PostgreSQL    │ │    Redis    │ │  S3/MinIO     │
│   (Primary DB)  │ │ (Cache/Pub) │ │  (Media)      │
└─────────────────┘ └─────────────┘ └───────────────┘
```

## 4. 핵심 기능 상세

### 4.1 프라이빗 메시징 시스템

#### 메시지 발송 흐름
```
Cast → API → Message Queue → Fan Inbox (broadcast)
                  ↓
           Store in DB
                  ↓
         Push Notification
```

#### 메시지 유형
- `TEXT`: 텍스트 메시지
- `IMAGE`: 이미지 (워터마크 적용)
- `VOICE`: 음성 메시지
- `VIDEO`: 영상 메시지

### 4.2 답장 시스템

#### 답장 토큰 규칙
| 조건 | 토큰 | 글자 수 |
|------|------|---------|
| 기본 | 3개/메시지 | 50자 |
| 7일 구독 | 3개/메시지 | 77자 |
| 30일 구독 | 3개/메시지 | 100자 |
| 100일 구독 | 3개/메시지 | 200자 |
| 365일 구독 | 3개/메시지 | 500자 |
| Premium 등급 | 5개/메시지 | 기본 150자 |

#### 토큰 회복
- 캐스트의 새 메시지 수신 시: +3 토큰
- 마지막 메시지 후 7일 경과: 토큰 리셋

### 4.3 구독 시스템

#### 구독 티어
| 티어 | 가격 (월) | 혜택 |
|------|----------|------|
| Basic | ₩4,500 | 메시지 수신, 기본 답장 |
| Premium | ₩9,900 | 글자수 상향, 토큰 추가, 전용 콘텐츠 |
| Ultimate | ₩19,900 | 모든 Premium + 음성/영상 우선 |

### 4.4 콘텐츠 모더레이션

#### 자동 필터링 대상
- 연락처 패턴: 전화번호, 이메일
- SNS 계정: @username, 카카오ID, 인스타그램
- 개인정보: 주소 패턴, 실명 유도
- 금지어: 욕설, 성희롱, 혐오 표현

#### 신고 처리 흐름
```
신고 접수 → 자동 분류 → 검토 대기열 → 관리자 검토 → 조치
                              ↓
                     심각도 높음: 즉시 숨김
```

## 5. 기술 스택

### 5.1 선택 및 근거

| 영역 | 기술 | 선택 이유 |
|------|------|----------|
| Mobile | React Native | 크로스플랫폼, 빠른 개발, 풍부한 생태계 |
| Backend | NestJS (Node.js) | TypeScript, 모듈화, 실시간 지원 우수 |
| Database | PostgreSQL | 관계형 데이터, JSON 지원, 안정성 |
| Cache | Redis | 세션, 실시간 pub/sub, 토큰 관리 |
| Realtime | Socket.IO | 양방향 통신, 재연결 처리, 룸 지원 |
| Storage | S3/MinIO | 미디어 저장, CDN 연동 |
| Search | PostgreSQL FTS | MVP 단계 충분, 확장 시 Elasticsearch |

### 5.2 인프라

- **Container**: Docker + Docker Compose (개발), Kubernetes (운영)
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack

## 6. 보안 설계

### 6.1 인증/인가

```typescript
// JWT 페이로드 구조
interface JWTPayload {
  sub: string;        // user ID
  role: UserRole;     // FAN | CAST | MANAGER | ADMIN
  permissions: string[];
  iat: number;
  exp: number;
}
```

### 6.2 RBAC 권한 매트릭스

| 리소스 | Fan | Cast | Manager | Admin |
|--------|-----|------|---------|-------|
| 메시지 수신 | ✓ (구독) | ✓ | ✓ | ✓ |
| 메시지 발송 | - | ✓ | - | ✓ |
| 답장 발송 | ✓ | - | - | ✓ |
| 답장 열람 | - | ✓ (본인) | ✓ | ✓ |
| 캐스트 관리 | - | - | ✓ | ✓ |
| 신고 처리 | - | - | - | ✓ |

### 6.3 데이터 보호

- **전송 암호화**: TLS 1.3
- **저장 암호화**: AES-256 (민감 데이터)
- **워터마크**: 이미지/영상에 사용자 ID 해시 삽입
- **로그 감사**: 모든 관리자 행위 기록

## 7. API 설계 (REST)

### 7.1 인증 API

```
POST   /api/v1/auth/register     # 회원가입
POST   /api/v1/auth/login        # 로그인
POST   /api/v1/auth/refresh      # 토큰 갱신
POST   /api/v1/auth/logout       # 로그아웃
```

### 7.2 사용자 API

```
GET    /api/v1/users/me          # 내 정보
PATCH  /api/v1/users/me          # 정보 수정
GET    /api/v1/users/:id/profile # 공개 프로필
```

### 7.3 캐스트 API

```
GET    /api/v1/casts             # 캐스트 목록
GET    /api/v1/casts/:id         # 캐스트 상세
GET    /api/v1/casts/:id/content # 캐스트 콘텐츠
POST   /api/v1/casts/:id/subscribe   # 구독
DELETE /api/v1/casts/:id/subscribe   # 구독 해지
```

### 7.4 메시징 API

```
GET    /api/v1/chatrooms                    # 내 채팅방 목록
GET    /api/v1/chatrooms/:castId/messages   # 메시지 목록
POST   /api/v1/chatrooms/:castId/messages   # 답장 발송 (Fan)
POST   /api/v1/casts/me/messages            # 메시지 발송 (Cast)
GET    /api/v1/casts/me/replies             # 받은 답장 목록 (Cast)
```

### 7.5 구독 API

```
GET    /api/v1/subscriptions           # 내 구독 목록
POST   /api/v1/subscriptions           # 구독 생성
DELETE /api/v1/subscriptions/:id       # 구독 취소
GET    /api/v1/subscriptions/:id/stats # 구독 통계 (관계일수 등)
```

### 7.6 신고 API

```
POST   /api/v1/reports                 # 신고 접수
GET    /api/v1/admin/reports           # 신고 목록 (Admin)
PATCH  /api/v1/admin/reports/:id       # 신고 처리 (Admin)
```

## 8. WebSocket 이벤트

### 8.1 클라이언트 → 서버

```typescript
// 채팅방 입장
socket.emit('join_room', { castId: string });

// 채팅방 퇴장
socket.emit('leave_room', { castId: string });

// 답장 발송
socket.emit('send_reply', { castId: string, content: string });

// 읽음 처리
socket.emit('mark_read', { messageIds: string[] });
```

### 8.2 서버 → 클라이언트

```typescript
// 새 메시지 수신
socket.on('new_message', (message: Message) => {});

// 답장 확인 (Cast)
socket.on('new_reply', (reply: Reply) => {});

// 구독 상태 변경
socket.on('subscription_updated', (subscription: Subscription) => {});

// 토큰 갱신 알림
socket.on('tokens_refreshed', (tokens: { available: number }) => {});
```

## 9. 테스트 전략

### 9.1 테스트 피라미드

```
        ┌───────────┐
        │   E2E     │  10%
        ├───────────┤
        │Integration│  30%
        ├───────────┤
        │   Unit    │  60%
        └───────────┘
```

### 9.2 핵심 테스트 케이스

#### Unit Tests
- 답장 토큰 계산 로직
- 글자 수 제한 검증
- 개인정보 필터링 패턴 매칭
- 워터마크 삽입 로직

#### Integration Tests
- 메시지 발송 → 구독자 수신 흐름
- 구독 생성 → 권한 부여 흐름
- 신고 접수 → 자동 필터링 흐름

#### E2E Tests
- 회원가입 → 구독 → 메시지 수신 → 답장 전체 흐름
- 캐스트 메시지 발송 → 팬 실시간 수신
