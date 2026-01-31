# MOE BACKSTAGE - Design System

## 1. 디자인 철학

### 1.1 컨셉: "Dreamlike Snow" (몽환적인 눈)

고급스럽고 몽환적인 꿈속에 있는 듯한 경험을 제공합니다.
- **눈처럼 부드러운 흰색**: 펄 효과와 미세한 그라디언트
- **깊은 어둠의 대비**: 검정에 가까운 짙은 회색
- **유기적 곡선**: 딱딱한 직선보다 부드럽게 흐르는 형태
- **은은한 빛**: 과하지 않은 글로우와 섀도우

### 1.2 무드 키워드
- Ethereal (천상의)
- Luxurious (고급스러운)
- Dreamy (몽환적인)
- Intimate (친밀한)
- Mysterious (신비로운)

## 2. 컬러 시스템

### 2.1 Primary Palette

```css
:root {
  /* Snow White - 눈처럼 부드러운 흰색 계열 */
  --snow-pure: #FFFFFF;
  --snow-soft: #F8F9FA;
  --snow-pearl: #F0F1F3;
  --snow-mist: #E8EAED;

  /* Deep Gray - 짙은 회색/검정 계열 */
  --deep-void: #121214;
  --deep-night: #1A1A1D;
  --deep-shadow: #242428;
  --deep-slate: #2E2E33;
  --deep-ash: #3A3A40;

  /* Accent - 포인트 컬러 (최소한으로 사용) */
  --accent-pearl: rgba(255, 255, 255, 0.85);
  --accent-glow: rgba(255, 255, 255, 0.15);
  --accent-shimmer: rgba(200, 200, 220, 0.3);
}
```

### 2.2 Gradient Definitions

```css
:root {
  /* Snow Gradients - 눈/펄 효과 */
  --gradient-snow-primary: linear-gradient(
    135deg,
    rgba(255, 255, 255, 1) 0%,
    rgba(248, 249, 250, 0.95) 50%,
    rgba(240, 241, 243, 0.9) 100%
  );

  --gradient-snow-pearl: linear-gradient(
    145deg,
    rgba(255, 255, 255, 1) 0%,
    rgba(245, 245, 250, 0.98) 30%,
    rgba(240, 240, 248, 0.95) 60%,
    rgba(235, 235, 245, 0.92) 100%
  );

  --gradient-snow-shimmer: linear-gradient(
    120deg,
    rgba(255, 255, 255, 0.9) 0%,
    rgba(255, 255, 255, 1) 25%,
    rgba(248, 248, 255, 0.95) 50%,
    rgba(255, 255, 255, 1) 75%,
    rgba(250, 250, 255, 0.9) 100%
  );

  /* Dark Gradients - 배경용 */
  --gradient-void: linear-gradient(
    180deg,
    #121214 0%,
    #1A1A1D 50%,
    #121214 100%
  );

  --gradient-night-radial: radial-gradient(
    ellipse at 50% 0%,
    #2E2E33 0%,
    #1A1A1D 50%,
    #121214 100%
  );
}
```

### 2.3 Semantic Colors

```css
:root {
  /* Text */
  --text-on-dark: var(--snow-pure);
  --text-on-dark-secondary: rgba(255, 255, 255, 0.7);
  --text-on-dark-muted: rgba(255, 255, 255, 0.5);
  --text-on-light: var(--deep-night);
  --text-on-light-secondary: rgba(26, 26, 29, 0.7);

  /* Surfaces */
  --surface-dark: var(--deep-night);
  --surface-dark-elevated: var(--deep-shadow);
  --surface-light: var(--snow-soft);
  --surface-light-elevated: var(--snow-pure);

  /* Interactive States */
  --interactive-hover: rgba(255, 255, 255, 0.08);
  --interactive-pressed: rgba(255, 255, 255, 0.12);
  --interactive-focus: rgba(255, 255, 255, 0.2);

  /* Status Colors (절제된 사용) */
  --status-success: #4ADE80;
  --status-warning: #FBBF24;
  --status-error: #F87171;
  --status-info: #60A5FA;
}
```

## 3. 타이포그래피

### 3.1 Font Family

```css
:root {
  /* Primary: 한글 + 영문 조합 */
  --font-primary: 'Pretendard Variable', 'Pretendard', -apple-system,
                  BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;

  /* Display: 타이틀/강조용 */
  --font-display: 'Noto Serif KR', 'Times New Roman', serif;

  /* Mono: 숫자/코드 */
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
}
```

### 3.2 Type Scale

```css
:root {
  /* Size Scale */
  --text-xs: 0.75rem;     /* 12px */
  --text-sm: 0.875rem;    /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg: 1.125rem;    /* 18px */
  --text-xl: 1.25rem;     /* 20px */
  --text-2xl: 1.5rem;     /* 24px */
  --text-3xl: 1.875rem;   /* 30px */
  --text-4xl: 2.25rem;    /* 36px */
  --text-5xl: 3rem;       /* 48px */

  /* Weight */
  --font-light: 300;
  --font-regular: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;

  /* Line Height */
  --leading-tight: 1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;

  /* Letter Spacing */
  --tracking-tight: -0.025em;
  --tracking-normal: 0;
  --tracking-wide: 0.025em;
}
```

### 3.3 Text Styles

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Display Large | 48px | 300 | 1.25 | 스플래시, 히어로 |
| Display Medium | 36px | 300 | 1.25 | 섹션 타이틀 |
| Heading 1 | 30px | 600 | 1.25 | 페이지 타이틀 |
| Heading 2 | 24px | 600 | 1.35 | 카드 타이틀 |
| Heading 3 | 20px | 500 | 1.4 | 서브섹션 |
| Body Large | 18px | 400 | 1.5 | 강조 본문 |
| Body | 16px | 400 | 1.5 | 기본 본문 |
| Body Small | 14px | 400 | 1.5 | 보조 텍스트 |
| Caption | 12px | 400 | 1.4 | 레이블, 힌트 |

## 4. 공간 시스템

### 4.1 Spacing Scale

```css
:root {
  --space-0: 0;
  --space-1: 0.25rem;   /* 4px */
  --space-2: 0.5rem;    /* 8px */
  --space-3: 0.75rem;   /* 12px */
  --space-4: 1rem;      /* 16px */
  --space-5: 1.25rem;   /* 20px */
  --space-6: 1.5rem;    /* 24px */
  --space-8: 2rem;      /* 32px */
  --space-10: 2.5rem;   /* 40px */
  --space-12: 3rem;     /* 48px */
  --space-16: 4rem;     /* 64px */
  --space-20: 5rem;     /* 80px */
  --space-24: 6rem;     /* 96px */
}
```

### 4.2 Border Radius

```css
:root {
  --radius-none: 0;
  --radius-sm: 0.375rem;   /* 6px - 작은 요소 */
  --radius-md: 0.75rem;    /* 12px - 버튼, 인풋 */
  --radius-lg: 1rem;       /* 16px - 카드 */
  --radius-xl: 1.5rem;     /* 24px - 모달, 바텀시트 */
  --radius-2xl: 2rem;      /* 32px - 큰 카드 */
  --radius-full: 9999px;   /* 완전 둥근 */
}
```

## 5. 효과 시스템

### 5.1 Shadow (그림자)

```css
:root {
  /* Elevation - 부드럽고 은은한 그림자 */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.1);

  --shadow-md:
    0 4px 6px -1px rgba(0, 0, 0, 0.1),
    0 2px 4px -2px rgba(0, 0, 0, 0.1);

  --shadow-lg:
    0 10px 15px -3px rgba(0, 0, 0, 0.15),
    0 4px 6px -4px rgba(0, 0, 0, 0.1);

  --shadow-xl:
    0 20px 25px -5px rgba(0, 0, 0, 0.15),
    0 8px 10px -6px rgba(0, 0, 0, 0.1);

  /* Glow - 몽환적 빛 효과 */
  --glow-soft: 0 0 20px rgba(255, 255, 255, 0.1);
  --glow-medium: 0 0 40px rgba(255, 255, 255, 0.15);
  --glow-strong: 0 0 60px rgba(255, 255, 255, 0.2);

  /* Inner Glow - 내부 빛 */
  --inner-glow: inset 0 1px 0 rgba(255, 255, 255, 0.1);
}
```

### 5.2 Blur (블러)

```css
:root {
  --blur-sm: blur(4px);
  --blur-md: blur(8px);
  --blur-lg: blur(16px);
  --blur-xl: blur(24px);

  /* Backdrop Blur - 유리 효과 */
  --backdrop-blur: blur(20px);
}
```

### 5.3 Pearl Effect (펄 효과)

```css
/* 펄 효과를 위한 의사 요소 */
.pearl-effect {
  position: relative;
  overflow: hidden;
}

.pearl-effect::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: linear-gradient(
    45deg,
    transparent 30%,
    rgba(255, 255, 255, 0.1) 50%,
    transparent 70%
  );
  animation: pearl-shimmer 3s ease-in-out infinite;
}

@keyframes pearl-shimmer {
  0%, 100% { transform: translateX(-100%) rotate(45deg); }
  50% { transform: translateX(100%) rotate(45deg); }
}
```

### 5.4 Snow Particle Effect (눈 입자 효과)

```css
/* 배경 눈 효과 */
.snow-particles {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  pointer-events: none;
  overflow: hidden;
  z-index: 0;
}

.snow-particle {
  position: absolute;
  background: radial-gradient(
    circle,
    rgba(255, 255, 255, 0.8) 0%,
    rgba(255, 255, 255, 0) 70%
  );
  border-radius: 50%;
  animation: snow-fall linear infinite;
}

@keyframes snow-fall {
  0% {
    transform: translateY(-10vh) translateX(0);
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    transform: translateY(100vh) translateX(20px);
    opacity: 0;
  }
}
```

## 6. 컴포넌트 스타일

### 6.1 Button

```css
/* Primary Button - 흰색 눈 버튼 */
.btn-primary {
  background: var(--gradient-snow-pearl);
  color: var(--deep-night);
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-full);
  font-weight: var(--font-medium);
  box-shadow: var(--shadow-md), var(--glow-soft);
  transition: all 0.3s ease;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg), var(--glow-medium);
}

.btn-primary:active {
  transform: translateY(0);
}

/* Secondary Button - 투명 테두리 */
.btn-secondary {
  background: transparent;
  color: var(--snow-pure);
  padding: var(--space-3) var(--space-6);
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: var(--radius-full);
  backdrop-filter: var(--backdrop-blur);
  transition: all 0.3s ease;
}

.btn-secondary:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.5);
}

/* Ghost Button - 최소 스타일 */
.btn-ghost {
  background: transparent;
  color: var(--snow-pure);
  padding: var(--space-2) var(--space-4);
  transition: all 0.3s ease;
}

.btn-ghost:hover {
  background: var(--interactive-hover);
}
```

### 6.2 Card

```css
/* Dark Card - 어두운 배경 위 카드 */
.card-dark {
  background: var(--deep-shadow);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-lg);
}

/* Glass Card - 유리 효과 카드 */
.card-glass {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: var(--backdrop-blur);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
}

/* Snow Card - 흰색 카드 (밝은 모드) */
.card-snow {
  background: var(--gradient-snow-pearl);
  border-radius: var(--radius-xl);
  padding: var(--space-6);
  box-shadow: var(--shadow-lg);
}
```

### 6.3 Input

```css
/* Text Input */
.input {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: var(--radius-md);
  padding: var(--space-3) var(--space-4);
  color: var(--snow-pure);
  font-size: var(--text-base);
  transition: all 0.2s ease;
}

.input::placeholder {
  color: var(--text-on-dark-muted);
}

.input:focus {
  outline: none;
  border-color: rgba(255, 255, 255, 0.3);
  background: rgba(255, 255, 255, 0.08);
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.1);
}
```

### 6.4 Chat Bubble

```css
/* 캐스트 메시지 버블 */
.bubble-cast {
  background: var(--gradient-snow-pearl);
  color: var(--deep-night);
  padding: var(--space-4);
  border-radius: var(--radius-lg);
  border-bottom-left-radius: var(--radius-sm);
  max-width: 80%;
  box-shadow: var(--shadow-md), var(--glow-soft);
}

/* 팬 답장 버블 */
.bubble-fan {
  background: var(--deep-slate);
  color: var(--snow-pure);
  padding: var(--space-4);
  border-radius: var(--radius-lg);
  border-bottom-right-radius: var(--radius-sm);
  max-width: 80%;
  margin-left: auto;
}
```

### 6.5 Navigation

```css
/* Bottom Tab Bar */
.tab-bar {
  background: var(--deep-night);
  border-top: 1px solid rgba(255, 255, 255, 0.05);
  padding: var(--space-2) var(--space-4);
  padding-bottom: env(safe-area-inset-bottom);
}

.tab-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-2);
  color: var(--text-on-dark-muted);
  transition: all 0.2s ease;
}

.tab-item.active {
  color: var(--snow-pure);
}

.tab-item.active .tab-icon {
  filter: drop-shadow(0 0 8px rgba(255, 255, 255, 0.5));
}
```

## 7. 애니메이션

### 7.1 Timing Functions

```css
:root {
  --ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-out-quart: cubic-bezier(0.25, 1, 0.5, 1);
  --ease-in-out-quart: cubic-bezier(0.76, 0, 0.24, 1);
  --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

### 7.2 Standard Animations

```css
/* Fade In */
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* Slide Up */
@keyframes slide-up {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Scale In */
@keyframes scale-in {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* Float - 몽환적 떠있는 효과 */
@keyframes float {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

/* Pulse Glow */
@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 20px rgba(255, 255, 255, 0.1);
  }
  50% {
    box-shadow: 0 0 40px rgba(255, 255, 255, 0.2);
  }
}
```

### 7.3 Animation Classes

```css
.animate-fade-in {
  animation: fade-in 0.3s var(--ease-out-quart);
}

.animate-slide-up {
  animation: slide-up 0.4s var(--ease-out-expo);
}

.animate-scale-in {
  animation: scale-in 0.3s var(--ease-spring);
}

.animate-float {
  animation: float 3s ease-in-out infinite;
}

.animate-pulse-glow {
  animation: pulse-glow 2s ease-in-out infinite;
}
```

## 8. 아이콘 시스템

### 8.1 Icon Specifications

- **Size**: 20px (기본), 24px (강조), 16px (작은)
- **Stroke**: 1.5px (기본), 2px (강조)
- **Style**: Rounded, Outlined (Lucide 또는 Phosphor Icons 권장)
- **Color**: 상위 요소 색상 상속 (`currentColor`)

### 8.2 Custom Icons

채팅, 하트, 스타 등 핵심 아이콘은 커스텀 디자인 권장:
- 더 부드러운 곡선
- 눈/꿈 테마에 맞는 디테일

## 9. 레이아웃 가이드

### 9.1 Screen Structure

```
┌─────────────────────────────────┐
│         Status Bar              │
├─────────────────────────────────┤
│         Header (56px)           │
│   ┌─────────────────────────┐   │
│   │      Title / Actions    │   │
│   └─────────────────────────┘   │
├─────────────────────────────────┤
│                                 │
│                                 │
│         Content Area            │
│     (Scrollable if needed)      │
│                                 │
│                                 │
├─────────────────────────────────┤
│       Bottom Tab Bar (83px)     │
│   ┌───┬───┬───┬───┬───┐        │
│   │ 홈│채팅│검색│보관│내정보│   │
│   └───┴───┴───┴───┴───┘        │
│      Safe Area Bottom           │
└─────────────────────────────────┘
```

### 9.2 Safe Areas

```css
:root {
  --safe-top: env(safe-area-inset-top);
  --safe-bottom: env(safe-area-inset-bottom);
  --header-height: 56px;
  --tab-bar-height: 83px;
}
```

## 10. 반응형 디자인

### 10.1 Breakpoints

```css
:root {
  --breakpoint-sm: 640px;   /* 모바일 */
  --breakpoint-md: 768px;   /* 태블릿 세로 */
  --breakpoint-lg: 1024px;  /* 태블릿 가로 */
  --breakpoint-xl: 1280px;  /* 데스크톱 */
}
```

## 11. 접근성

### 11.1 Color Contrast

- 본문 텍스트: 최소 4.5:1 대비율
- 큰 텍스트 (18px+): 최소 3:1 대비율
- 인터랙티브 요소: 최소 3:1 대비율

### 11.2 Touch Targets

- 최소 터치 영역: 44x44px
- 인접 터치 요소 간격: 최소 8px

## 12. 다크/라이트 모드

기본적으로 다크 모드를 메인으로 사용하되, 채팅 화면 등 특정 영역에서 라이트 요소를 조합합니다.

```css
/* 시스템 설정 존중 (선택적) */
@media (prefers-color-scheme: light) {
  :root {
    /* Light mode overrides if needed */
  }
}
```

## 13. 이미지/미디어 가이드라인

### 13.1 Profile Images
- 형태: 원형 (border-radius: 50%)
- 크기: 40px (목록), 80px (상세), 120px (프로필)
- 테두리: 2px solid rgba(255, 255, 255, 0.1)

### 13.2 Content Images
- 비율: 1:1 (정사각형), 4:5 (세로), 16:9 (가로 영상)
- 모서리: var(--radius-lg)
- 로딩: Shimmer placeholder 사용

### 13.3 Watermark (워터마크)
- 위치: 우하단
- 투명도: 30-40%
- 크기: 이미지 너비의 15-20%
