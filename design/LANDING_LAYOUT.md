# MOE BACKSTAGE - Landing Page Layout Guide

> 피그마에서 랜딩페이지 프레임 제작 시 참고하는 레이아웃 가이드

---

## 📱 Artboard Setup

### Frame Sizes
```
Desktop:  1440 x auto (content height)
Tablet:   768 x auto
Mobile:   375 x auto
```

### Safe Area (Padding)
```
Desktop:  48px horizontal (space12)
Tablet:   32px horizontal (space8)
Mobile:   16px horizontal (space4)
```

---

## 🏗️ Page Structure

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                   HERO SECTION                      │
│                   height: 100vh                     │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│                 FEATURES SECTION                    │
│               padding-y: 64px (PC)                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│                 PREVIEW SECTION                     │
│               padding-y: 64px (PC)                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│                   CTA SECTION                       │
│               padding-y: 64px (PC)                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                     FOOTER                          │
│               padding-y: 32px                       │
└─────────────────────────────────────────────────────┘
```

---

## 1️⃣ Hero Section

### Desktop Layout (1024px+)

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  padding: 48px                                                  │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  max-width: 1200px  (centered)                            │ │
│  │                                                           │ │
│  │  ┌──────────────────────┐   ┌─────────────────────────┐  │ │
│  │  │                      │   │                         │  │ │
│  │  │    LEFT CONTENT      │   │    REGISTRATION CARD    │  │ │
│  │  │    flex: 5           │   │    flex: 4              │  │ │
│  │  │                      │   │    max-width: 420px     │  │ │
│  │  │  [Logo] Brand        │   │                         │  │ │
│  │  │                      │   │                         │  │ │
│  │  │  Headline            │   │                         │  │ │
│  │  │  (52px)              │   │                         │  │ │
│  │  │                      │   │                         │  │ │
│  │  │  Subtext             │   │                         │  │ │
│  │  │                      │   │                         │  │ │
│  │  │  🟢 Count            │   │                         │  │ │
│  │  │                      │   │                         │  │ │
│  │  └──────────────────────┘   └─────────────────────────┘  │ │
│  │                                                           │ │
│  │                    gap: 48px (space12)                    │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│                      [Scroll Indicator]                         │
│                       bottom: 32px                              │
└─────────────────────────────────────────────────────────────────┘

Background: gradientVoid (vertical)
Snow Animation: 60 particles
Glow: top-right, 600x600px, radial gradient
```

### Mobile Layout (< 768px)

```
┌─────────────────────────────┐
│  padding: 16px              │
│                             │
│         [Logo 80px]         │
│            ↕ 24px           │
│       MOE BACKSTAGE         │
│            ↕ 16px           │
│      밤에 내린 눈처럼,       │
│     당신만의 특별한 순간     │
│            ↕ 12px           │
│     좋아하는 캐스트와...     │
│            ↕ 32px           │
│   ┌─────────────────────┐   │
│   │  Registration Card  │   │
│   │                     │   │
│   └─────────────────────┘   │
│            ↕ 24px           │
│      🟢 12,847명이...       │
│            ↕ 48px           │
│      [Scroll Indicator]     │
│                             │
└─────────────────────────────┘

Everything: center aligned
```

---

## 2️⃣ Features Section

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  padding: 48px horizontal, 64px vertical                        │
│  background: deep.shadow (#242428)                              │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  max-width: 1100px (centered)                             │ │
│  │                                                           │ │
│  │              [FEATURES]  ← section badge                  │ │
│  │                 ↕ 16px                                    │ │
│  │             특별한 기능들  ← displayMedium                │ │
│  │                 ↕ 8px                                     │ │
│  │        MOE BACKSTAGE만의 특별한 경험                      │ │
│  │                 ↕ 48px                                    │ │
│  │                                                           │ │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐         │ │
│  │  │Feature │  │Feature │  │Feature │  │Feature │         │ │
│  │  │  Card  │  │  Card  │  │  Card  │  │  Card  │         │ │
│  │  │   1    │  │   2    │  │   3    │  │   4    │         │ │
│  │  └────────┘  └────────┘  └────────┘  └────────┘         │ │
│  │                                                           │ │
│  │          gap: 12px (space3) between cards                 │ │
│  │          4 equal columns                                  │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Mobile Layout

```
┌─────────────────────────────┐
│  padding: 16px, 48px        │
│                             │
│        [FEATURES]           │
│           ↕ 16px            │
│       특별한 기능들          │
│           ↕ 8px             │
│     MOE BACKSTAGE만의...    │
│           ↕ 32px            │
│                             │
│  ┌───────────────────────┐  │
│  │ [Icon]  프라이빗 메시지 │  │  Compact row card
│  │         좋아하는...    │  │
│  └───────────────────────┘  │
│           ↕ 16px            │
│  ┌───────────────────────┐  │
│  │ [Icon]  구독 시스템    │  │
│  │         스탠다드...    │  │
│  └───────────────────────┘  │
│           ↕ 16px            │
│        ... 2 more           │
│                             │
└─────────────────────────────┘
```

---

## 3️⃣ Preview Section

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  padding: 48px horizontal, 64px vertical                        │
│  background: deep.night (#1A1A1D)                               │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  max-width: 1100px                                        │ │
│  │                                                           │ │
│  │              [PREVIEW]                                    │ │
│  │                 ↕ 16px                                    │ │
│  │          이런 경험이 기다려요                              │ │
│  │                 ↕ 8px                                     │ │
│  │      좋아하는 캐스트와 더 가까워지는 특별한 순간           │ │
│  │                 ↕ 48px                                    │ │
│  │                                                           │ │
│  │  ┌───────────────────────┐   ┌───────────────────────┐   │ │
│  │  │   프라이빗 채팅        │   │   독점 굿즈           │   │ │
│  │  │   캐스트가 보내는...  │   │   팬만을 위한...      │   │ │
│  │  │                       │   │                       │   │ │
│  │  │   ┌───────────────┐   │   │   ┌───────────────┐   │   │ │
│  │  │   │ Chat Mockup   │   │   │   │ Shop Mockup   │   │   │ │
│  │  │   │ height: 280px │   │   │   │ height: 280px │   │   │ │
│  │  │   └───────────────┘   │   │   └───────────────┘   │   │ │
│  │  └───────────────────────┘   └───────────────────────┘   │ │
│  │                                                           │ │
│  │                    gap: 24px (space6)                     │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4️⃣ CTA Section

### Desktop Layout

```
┌─────────────────────────────────────────────────────────────────┐
│  padding: 48px horizontal, 64px vertical                        │
│  background: gradientVoid                                       │
│  Snow Animation: 40 particles                                   │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │  max-width: 1100px                                        │ │
│  │                                                           │ │
│  │  ┌──────────────────────────┐  ┌─────────────────────┐   │ │
│  │  │                          │  │                     │   │ │
│  │  │  [🚀 LAUNCHING SOON]     │  │  Registration Card  │   │ │
│  │  │         ↕ 24px           │  │  (same as hero)     │   │ │
│  │  │                          │  │                     │   │ │
│  │  │   30 : 12 : 45 : 23     │  │  • 혜택 헤더        │   │ │
│  │  │  DAYS  HRS  MIN  SEC    │  │  • 혜택 목록        │   │ │
│  │  │  (64px numbers)          │  │  ─────────────      │   │ │
│  │  │         ↕ 32px           │  │  • 폼 또는 완료     │   │ │
│  │  │                          │  │                     │   │ │
│  │  │  지금 사전예약하고       │  │                     │   │ │
│  │  │  특별한 혜택을 받으세요  │  │                     │   │ │
│  │  │         ↕ 16px           │  │                     │   │ │
│  │  │  런칭 알림부터...        │  │                     │   │ │
│  │  │         ↕ 24px           │  │                     │   │ │
│  │  │  🟢 12,847명이...        │  │                     │   │ │
│  │  │                          │  │                     │   │ │
│  │  └──────────────────────────┘  └─────────────────────┘   │ │
│  │                                                           │ │
│  │                flex 5:4, gap: 48px                        │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5️⃣ Footer

```
┌─────────────────────────────────────────────────────────────────┐
│  padding: 32px                                                  │
│  background: deep.night                                         │
│  border-top: 1px solid rgba(255,255,255,0.05)                  │
│                                                                 │
│                    [Logo 36px]  MOE BACKSTAGE                   │
│                           ↕ 24px                                │
│              이용약관  ·  개인정보처리방침  ·  문의하기          │
│                           ↕ 16px                                │
│                      [🌐]  [💬]  [@]                            │
│                           ↕ 24px                                │
│           © 2024 MOE BACKSTAGE. All rights reserved.           │
│                           ↕ 8px                                 │
│                  📧 support@moebackstage.com                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎨 Color Reference Quick Guide

### Backgrounds
| Element | Color |
|---------|-------|
| Page BG | `#121214` (deepVoid) |
| Section Alt | `#242428` (deepShadow) |
| Card BG | `rgba(255,255,255,0.03)` |
| Card Hover | `rgba(255,255,255,0.05)` |
| Input BG | `rgba(255,255,255,0.05)` |

### Borders
| State | Color |
|-------|-------|
| Default | `rgba(255,255,255,0.08)` |
| Hover | `rgba(255,255,255,0.1)` |
| Focus | `rgba(255,255,255,0.3)` |

### Text
| Role | Color |
|------|-------|
| Primary | `#FFFFFF` |
| Secondary | `rgba(255,255,255,0.7)` |
| Muted | `rgba(255,255,255,0.5)` |

---

## 📐 Spacing Quick Reference

```
space1:  4px   ─  micro gaps
space2:  8px   ─  tight gaps, inline spacing
space3:  12px  ─  standard gaps
space4:  16px  ─  padding (mobile), small sections
space5:  20px  ─  card internal gaps
space6:  24px  ─  card padding, medium sections
space8:  32px  ─  tablet padding, large gaps
space10: 40px  ─
space12: 48px  ─  desktop padding, section spacing
space16: 64px  ─  section vertical padding (desktop)
```

---

## 🔗 Figma Setup Tips

### 1. Create Design System File
- Import `tokens.json` using Tokens Studio plugin
- Set up color styles, text styles, effect styles

### 2. Create Component Library
- Build atomic components first (buttons, inputs, badges)
- Then molecules (cards, forms)
- Finally organisms (sections)

### 3. Use Auto Layout
- All components should use auto layout
- Set proper spacing and padding
- Enable "Hug contents" for flexible components

### 4. Create Variants
- Button: default, hover, pressed, disabled
- Input: default, focus, error, filled
- Card: default, hover

### 5. Responsive Setup
- Create frames for Desktop (1440px), Tablet (768px), Mobile (375px)
- Use constraints for responsive behavior
- Or use Figma's new "Variables" for responsive values
