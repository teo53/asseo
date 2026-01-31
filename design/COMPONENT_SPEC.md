# MOE BACKSTAGE - Component Specification

> 피그마에서 컴포넌트 제작 시 참고하는 상세 스펙 문서

---

## 📐 Grid System

### Breakpoints
| Name | Min Width | Max Width | Container Padding |
|------|-----------|-----------|-------------------|
| Mobile | 0px | 767px | 16px (space4) |
| Tablet | 768px | 1023px | 32px (space8) |
| Desktop | 1024px+ | - | 48px (space12) |

### Max Content Width
- **1100px** (일반 콘텐츠)
- **1200px** (풀 섹션)

---

## 🎨 Component Specifications

### 1. Hero Section

#### Desktop (1024px+)
```
┌─────────────────────────────────────────────────────┐
│  [Logo 56px]  MOE BACKSTAGE                         │
│                                                     │
│  밤에 내린 눈처럼              ┌─────────────────┐ │
│  당신만의 특별한 순간          │   사전예약 카드   │ │
│                                │   max-w: 420px  │ │
│  좋아하는 캐스트와 나누는...   │                 │ │
│                                │   [폼 컴포넌트]  │ │
│  🟢 12,847명이 기다리고...     │                 │ │
│                                └─────────────────┘ │
└─────────────────────────────────────────────────────┘

Layout:
- Row (flex: 5:4 ratio)
- Left: text-align left
- Right: registration card

Typography:
- Brand: heading2 (24px), weight 300, letter-spacing 3px
- Headline: 52px, weight 200, line-height 1.2
- Subtext: bodyLarge (18px), color text.onDark.secondary
```

#### Mobile (< 768px)
```
┌───────────────────────┐
│       [Logo 80px]     │
│                       │
│    MOE BACKSTAGE      │
│                       │
│   밤에 내린 눈처럼,   │
│  당신만의 특별한 순간  │
│                       │
│  ┌─────────────────┐  │
│  │  사전예약 카드   │  │
│  │                 │  │
│  └─────────────────┘  │
│                       │
│  🟢 12,847명이...     │
└───────────────────────┘

Layout:
- Column, center aligned
- Vertical spacing: space6~8
```

---

### 2. Registration Card

```
┌─────────────────────────────────────┐
│            사전예약                  │  heading3, weight 500
│     런칭 시 가장 먼저 알려드려요     │  bodySmall, muted
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📱 010-0000-0000            │   │  Input Field
│  └─────────────────────────────┘   │  height: 48px
│                                     │  bg: rgba(255,255,255,0.05)
│  ┌─────────────────────────────┐   │  border: rgba(255,255,255,0.1)
│  │ ✉️ email@example.com (선택) │   │  radius: md (12px)
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │        사전예약하기          │   │  Primary Button
│  └─────────────────────────────┘   │  height: 48px
│                                     │  bg: snow.pure
│  ─────────────────────────────────  │  text: deep.night
│                                     │  radius: full
│  ✓ 첫 달 무료  ✓ 한정판 배지  ✓ 굿즈│
└─────────────────────────────────────┘

Dimensions:
- max-width: 420px
- padding: 24px (space6)
- border-radius: xl (24px)
- background: rgba(255, 255, 255, 0.03)
- border: 1px solid rgba(255, 255, 255, 0.08)
```

---

### 3. Feature Card

#### Desktop
```
┌─────────────────────┐
│  ┌────┐             │
│  │ 🔮 │  accent bg  │  Icon Container
│  └────┘             │  52x52px
│                     │  radius: 12px (size * 0.24)
│  프라이빗 메시지     │  heading3, weight 500
│                     │
│  좋아하는 캐스트와   │  bodySmall
│  1:1 채팅처럼...    │  color: text.onDark.secondary
└─────────────────────┘

Dimensions:
- padding: 24px (space6)
- gap between icon and title: 20px (space5)
- gap between title and desc: 8px (space2)

Hover State:
- background: rgba(255, 255, 255, 0.05)
- border: 1px solid rgba(255, 255, 255, 0.1)
- icon: translateY(-4px)
```

#### Mobile (Compact)
```
┌────────────────────────────────────┐
│  [Icon 44px]  프라이빗 메시지       │
│               좋아하는 캐스트와...  │
└────────────────────────────────────┘

- Row layout
- padding: 16px (space4)
- radius: md (12px)
```

---

### 4. Countdown Timer

#### Desktop
```
  30  :  12  :  45  :  23
 DAYS    HRS    MIN    SEC

Typography:
- Numbers: 64px, weight 200, tabular-figures
- Labels: caption (12px), letter-spacing 2px, muted

Separator:
- ":" character
- 48px, weight 200
- color: text.onDark.muted
- horizontal padding: 16px (space4)
```

#### Mobile
```
  30 : 12 : 45 : 23
  일   시간  분   초

Typography:
- Numbers: 32px
- Labels: caption (10px)
- Separator padding: 8px (space2)
```

---

### 5. Section Label Badge

```
┌──────────────────┐
│ 🚀 LAUNCHING SOON │
└──────────────────┘

Dimensions:
- padding: 4px 12px (space1, space3)
- border: 1px solid rgba(255, 255, 255, 0.15)
- border-radius: full (9999px)
- background: transparent

Typography:
- caption (12px)
- letter-spacing: 1.5px ~ 2px
- weight: 500
- color: text.onDark.muted

Icon:
- size: 14px
- color: snow.pure
- gap to text: 6px
```

---

### 6. Preview Card (Chat Mockup)

```
┌─────────────────────────────────────┐
│  프라이빗 채팅                      │  heading3
│  캐스트가 보내는 특별한 메시지...   │  bodySmall, secondary
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Avatar] 윈터      [VIP]    │   │
│  │ ─────────────────────────── │   │
│  │ ┌─────────────────────┐     │   │
│  │ │ 오늘 연습 끝났어요~ 💪 │     │   │
│  │ └─────────────────────┘     │   │
│  │ 오후 6:42                   │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

Card:
- padding: 20px (space5)
- radius: xl (24px)
- background: rgba(255, 255, 255, 0.02)
- hover bg: rgba(255, 255, 255, 0.04)

Mockup Inner:
- height: 280px
- padding: 16px (space4)
- radius: md (12px)
- background: deep.shadow (#242428)

Chat Bubble:
- padding: 8px 12px
- radius: md (12px)
- background: rgba(255, 255, 255, 0.06)

VIP Badge:
- padding: 4px 8px
- radius: full
- background: rgba(139, 92, 246, 0.2)
- text color: #8B5CF6
```

---

### 7. Footer

```
┌─────────────────────────────────────────────────────┐
│              [Logo]  MOE BACKSTAGE                  │
│                                                     │
│       이용약관  ·  개인정보처리방침  ·  문의하기     │
│                                                     │
│              [🌐]  [💬]  [@]                        │
│                                                     │
│     © 2024 MOE BACKSTAGE. All rights reserved.     │
│              📧 support@moebackstage.com           │
└─────────────────────────────────────────────────────┘

Dimensions:
- padding-y: 32px (space8)
- border-top: 1px solid rgba(255, 255, 255, 0.05)
- background: deep.night (#1A1A1D)

Logo:
- size: 36x36px
- radius: md (12px)

Social Button:
- size: 40x40px
- radius: full (circle)
- background: rgba(255, 255, 255, 0.05)
- hover: rgba(255, 255, 255, 0.1)
```

---

### 8. Scroll to Top Button

```
┌────┐
│ ⬆️ │
└────┘

Dimensions:
- size: 48x48px
- radius: md (12px)
- background: rgba(255, 255, 255, 0.1)
- border: 1px solid rgba(255, 255, 255, 0.2)

Position:
- fixed
- right: 24px (space6)
- bottom: 24px (space6)

Animation:
- opacity: 0 → 1
- scale: 0.8 → 1
- duration: 200ms
```

---

## 🎭 States

### Button States
| State | Background | Border | Scale |
|-------|------------|--------|-------|
| Default | snow.pure | - | 1 |
| Hover | snow.soft | - | 1 |
| Pressed | snow.mist | - | 0.98 |
| Disabled | rgba(255,255,255,0.3) | - | 1 |

### Input States
| State | Border Color | Background |
|-------|--------------|------------|
| Default | rgba(255,255,255,0.1) | rgba(255,255,255,0.05) |
| Focus | rgba(255,255,255,0.3) | rgba(255,255,255,0.08) |
| Error | status.error | rgba(248,113,113,0.1) |
| Filled | rgba(255,255,255,0.2) | rgba(255,255,255,0.05) |

### Card Hover
| Property | Default | Hover |
|----------|---------|-------|
| Background | rgba(255,255,255,0.02~0.03) | rgba(255,255,255,0.04~0.05) |
| Border | rgba(255,255,255,0.05~0.08) | rgba(255,255,255,0.1) |
| Transform | - | translateY(-4px) for icons |

---

## 📱 Responsive Behavior

### Typography Scaling
| Style | Mobile | Desktop |
|-------|--------|---------|
| Section Title | heading1 (30px) | displayMedium (36px) |
| Hero Headline | displayMedium (36px) | 52px custom |
| Card Title | heading3 (20px) | heading3 (20px) |

### Layout Changes
| Component | Mobile | Desktop |
|-----------|--------|---------|
| Hero | Column (centered) | Row (5:4 flex) |
| Features | 1 column (compact) | 4 columns |
| Preview | 1 column | 2 columns |
| CTA | Column (centered) | Row (5:4 flex) |
| Countdown | 32px numbers | 64px numbers |

---

## 🌟 Animation Guidelines

### Micro Interactions
- **Duration**: 200ms ~ 250ms
- **Easing**: ease-out (standard), ease-in-out (bouncing)
- **Hover lift**: translateY(-4px)
- **Scale on press**: scale(0.98)

### Page Transitions
- **Scroll indicator bounce**:
  - Duration: 1500ms
  - Movement: 8px vertical
  - Easing: ease-in-out
  - Loop: infinite, reverse

### Snow Animation
- **Desktop**: 60 particles
- **Mobile**: 30 particles
- **Animation duration**: 20s continuous
