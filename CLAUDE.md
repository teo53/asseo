# CLAUDE.md - UNOA Codebase Guide

This document provides comprehensive guidance for AI assistants working with the UNOA codebase.

## Project Overview

**UNOA** (유노아) is a private fan communication app. It enables private messaging between fans and creators, subscription-based tiers, and an in-app currency system (DreamTime) for donations.

- **Version:** 1.0.0
- **Primary Language:** Dart (Flutter) + TypeScript (Edge Functions)
- **Documentation Language:** Korean (한국어)

## Technology Stack

### Frontend (Flutter)
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | >=3.2.0 | Cross-platform UI framework |
| Dart | >=3.2.0 | Programming language |
| flutter_riverpod | 2.4.9 | State management |
| go_router | 13.0.0 | Declarative routing |
| supabase_flutter | 2.3.0 | Backend SDK |

### Backend (Supabase)
| Component | Technology | Purpose |
|-----------|------------|---------|
| Database | PostgreSQL | Primary data store |
| Auth | Supabase Auth | JWT-based authentication |
| Realtime | Supabase Realtime | WebSocket subscriptions |
| Edge Functions | Deno/TypeScript | Serverless business logic |

## Directory Structure

```
/home/user/asseo/
├── app/                              # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart                 # App entry point (demo mode support)
│   │   ├── core/
│   │   │   ├── config/env.dart       # Environment variables
│   │   │   ├── router/app_router.dart # Go Router configuration
│   │   │   ├── services/
│   │   │   │   ├── auth_service.dart     # Authentication
│   │   │   │   └── supabase_service.dart # Database operations
│   │   │   └── theme/
│   │   │       ├── app_colors.dart       # Color palette
│   │   │       ├── app_typography.dart   # Typography scale
│   │   │       └── app_theme.dart        # Theme configuration
│   │   └── features/                 # Feature-based modules
│   │       ├── auth/                 # Login, register, splash
│   │       ├── home/                 # Home feed
│   │       ├── chat/                 # Private messaging
│   │       ├── discover/             # Cast discovery
│   │       ├── dreamtime/            # In-app currency
│   │       └── profile/              # User profile
│   ├── test/                         # Unit tests
│   ├── web/                          # Flutter web support
│   └── pubspec.yaml                  # Dependencies
├── supabase/
│   ├── migrations/                   # SQL migrations
│   │   ├── 00001_initial_schema.sql      # Core tables
│   │   ├── 00002_dreamtime_currency.sql  # DreamTime tables
│   │   └── 00003_dreamtime_functions.sql # Database functions
│   ├── functions/                    # Edge functions (TypeScript)
│   │   ├── dt-topup/                 # Payment processing
│   │   ├── dt-donation/              # Donation handling
│   │   └── dt-refund/                # Refund processing
│   └── tests/                        # Backend tests
└── docs/                             # Documentation (Korean)
    ├── ARCHITECTURE.md               # System design
    ├── DATABASE.md                   # Schema documentation
    └── DESIGN_SYSTEM.md              # UI/UX guidelines
```

## Development Commands

### Flutter App

```bash
# Navigate to app directory
cd /home/user/asseo/app

# Install dependencies
flutter pub get

# Run the app (requires emulator/device or web)
flutter run

# Run on web
flutter run -d chrome

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web

# Run tests
flutter test

# Generate Riverpod code
flutter pub run build_runner build

# Watch mode for code generation
flutter pub run build_runner watch

# Run with environment variables
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=xxx
```

### Supabase

```bash
# Navigate to supabase directory
cd /home/user/asseo/supabase

# Link to Supabase project (requires Supabase CLI)
supabase link --project-ref <project-id>

# Push migrations
supabase db push

# Deploy edge functions
supabase functions deploy dt-topup
supabase functions deploy dt-donation
supabase functions deploy dt-refund

# Serve functions locally
supabase functions serve
```

## Architecture Patterns

### Feature-Based Module Structure

Each feature follows this structure:
```
feature_name/
├── models/              # Data classes with fromJson/toJson
├── services/            # Business logic and API calls
└── presentation/
    ├── pages/           # Full-screen widgets
    └── widgets/         # Reusable components
```

### State Management (Riverpod)

Key providers pattern:
```dart
// Service providers (singleton instances)
final supabaseServiceProvider = Provider((ref) => SupabaseService());
final authServiceProvider = Provider((ref) => AuthService());
final dreamTimeServiceProvider = Provider((ref) => DreamTimeService());

// State providers (reactive data)
final authStateProvider = StreamProvider((ref) => ...);
final walletSummaryProvider = FutureProvider((ref) => ...);
```

### Routing (Go Router)

Route structure:
```
/              → SplashPage
/login         → LoginPage
/register      → RegisterPage
/home          → ShellRoute (bottom navigation)
  ├── /home       → HomePage
  ├── /chat       → ChatListPage
  │   └── /chat/:castId → ChatRoomPage
  ├── /discover   → DiscoverPage
  └── /profile    → ProfilePage
```

## Key Conventions

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `auth_service.dart` |
| Classes | PascalCase | `AuthService` |
| Variables/Functions | camelCase | `getUserProfile()` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Providers | suffix with `Provider` | `authStateProvider` |
| Enums | PascalCase values | `DtTopupStatus.paid` |

### Code Style

- **Null Safety:** Full migration to null-safe Dart
- **Const Constructors:** Use `const` for immutable widgets
- **Named Parameters:** Prefer named parameters for clarity
- **Avoid Magic Numbers:** Use constants or enums
- **Korean Comments:** Documentation is in Korean

### Error Handling

```dart
// Service layer: throw typed exceptions
throw DonationException('Insufficient balance');

// UI layer: catch and display user-friendly messages
try {
  await service.donate(amount);
} on DonationException catch (e) {
  showSnackBar(e.message);
}
```

## Database Schema

### Core Tables (15)

1. **profiles** - User accounts linked to Supabase Auth
2. **teams** - Creator organizations
3. **casts** - Individual creators/idols
4. **subscription_tiers** - Pricing tiers (Basic/Premium/Ultimate)
5. **subscriptions** - Fan-to-cast subscriptions
6. **subscription_milestones** - Loyalty reward thresholds
7. **messages** - Creator broadcasts
8. **message_reads** - Read receipts
9. **reply_tokens** - Per-message response tokens
10. **replies** - Fan responses
11. **contents** - Exclusive content
12. **blocked_patterns** - Content moderation patterns
13. **reports** - User reports
14. **notifications** - Push notification queue
15. **user_blocks** - User blocking

### DreamTime Currency Tables (8)

1. **dt_wallets** - User balance (purchased + promo)
2. **dt_lots** - FIFO currency lots with expiration
3. **dt_topup_orders** - Purchase orders
4. **dt_ledger_entries** - Immutable transaction log
5. **dt_donations** - Donation records
6. **creator_earnings_ledger** - Creator earnings
7. **dt_refund_requests** - Refund queue
8. **dt_config** - System configuration

### Row Level Security (RLS)

All tables have RLS policies. Key patterns:
- Users can only read/write their own data
- Subscribers can view cast messages
- Admins have elevated access for moderation

## Business Logic

### Subscription Tiers

| Tier | Price | Reply Tokens | Base Char Limit |
|------|-------|--------------|-----------------|
| Basic | ₩4,500/mo | 3 | 50 |
| Premium | ₩9,900/mo | 5 | 150 |
| Ultimate | ₩19,900/mo | 7 | 200 |

### DreamTime Currency

- **FIFO Consumption:** Promo DT spent before purchased DT
- **Lot Expiration:** Each lot has expiration date
- **Platform Fee:** 20% on creator earnings
- **Refund Window:** 7 days from purchase
- **VAT:** 10% included in KRW price

### Content Moderation

Automatic pattern blocking for:
- Phone numbers (Korean/international)
- Email addresses
- Social media handles
- External links
- Explicit content

## Environment Configuration

### Required Variables

```dart
// In app/lib/core/config/env.dart
SUPABASE_URL        // Supabase project URL
SUPABASE_ANON_KEY   // Supabase anonymous key
IS_PRODUCTION       // Boolean flag (default: false)
```

### Running with Config

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=IS_PRODUCTION=true
```

### Demo Mode

The app runs in demo mode when Supabase initialization fails. This shows a fallback UI without backend connectivity.

## Testing

### Test Files

- `app/test/dreamtime_test.dart` - DreamTime model tests
- `app/test/widget_test.dart` - Widget tests

### Running Tests

```bash
cd /home/user/asseo/app
flutter test                        # All tests
flutter test test/dreamtime_test.dart  # Specific file
flutter test --coverage             # With coverage
```

### Test Patterns

```dart
group('DreamTime Models', () {
  test('should parse from JSON correctly', () {
    final json = {...};
    final model = DtWalletSummary.fromJson(json);
    expect(model.totalBalance, 15000);
  });
});
```

## Common Tasks for AI Assistants

### Adding a New Feature

1. Create feature directory under `app/lib/features/<name>/`
2. Add models in `models/` subdirectory
3. Add services in `services/` subdirectory
4. Add pages/widgets in `presentation/` subdirectory
5. Register routes in `app/lib/core/router/app_router.dart`
6. Add providers if using Riverpod

### Adding a Database Table

1. Create new migration file in `supabase/migrations/`
2. Follow naming: `000XX_description.sql`
3. Include RLS policies
4. Add indexes for frequently queried columns
5. Update relevant Flutter models/services

### Adding an Edge Function

1. Create directory in `supabase/functions/<name>/`
2. Add `index.ts` with Deno handler
3. Handle CORS, auth verification
4. Deploy with `supabase functions deploy <name>`

### Modifying Theme

Theme files location:
- Colors: `app/lib/core/theme/app_colors.dart`
- Typography: `app/lib/core/theme/app_typography.dart`
- Theme: `app/lib/core/theme/app_theme.dart`

Design system reference: `docs/DESIGN_SYSTEM.md`

## Security Considerations

### Authentication
- JWT-based via Supabase Auth
- Tokens stored in flutter_secure_storage
- Auto-refresh before expiry

### Database Security
- RLS policies on all tables
- User isolation enforced at DB level
- Admin-only access for sensitive operations

### Content Safety
- Automatic moderation patterns
- Report mechanism with admin queue
- User blocking functionality

## Documentation References

| Document | Path | Content |
|----------|------|---------|
| Architecture | `docs/ARCHITECTURE.md` | System design, user roles, API design |
| Database | `docs/DATABASE.md` | Full schema with ERD, SQL definitions |
| Design System | `docs/DESIGN_SYSTEM.md` | Colors, typography, components, animations |

## Git Workflow

- Current branch: `claude/add-claude-documentation-4DcEo`
- Use conventional commits: `feat:`, `fix:`, `chore:`, `refactor:`
- Korean commit messages are acceptable

## Troubleshooting

### Common Issues

1. **Demo Mode Shown:** Supabase credentials not configured or network unavailable
2. **Build Errors:** Run `flutter pub get` and `flutter pub run build_runner build`
3. **Type Errors:** Ensure Dart SDK >=3.2.0
4. **Provider Errors:** Check provider scope and dependencies

### Useful Debug Commands

```bash
flutter doctor          # Check Flutter installation
flutter clean           # Clean build artifacts
flutter pub deps        # Show dependency tree
```

---

*Last updated: 2026-01-31*
