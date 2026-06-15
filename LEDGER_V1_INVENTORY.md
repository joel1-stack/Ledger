# LEDGER V1 — Complete Inventory

## Project
- **Name**: Ledger — The record your community keeps forever
- **Package**: com.ledgerapp.ke
- **Firebase**: ledger-45f58 (Spark plan)
- **Framework**: Flutter 3.10.8+, Riverpod + GoRouter
- **Auth**: Phone Auth (Firebase) + Email/Password bypass fallback

## Screen-by-Screen Flow

| # | Screen | File | Illustrations | Purpose |
|---|--------|------|---------------|---------|
| 1 | **Splash** | `splash_screen.dart` | community (full, no opacity) | App logo, gradient bg, auto-navigate after 2s |
| 2 | **Welcome** | `welcome_screen.dart` | community | Tagline, "Get Started" button → How It Works |
| 3 | **How It Works** | `how_it_works_screen.dart` | teamWork → wallet → timeline | 3 auto-sliding cards (5s each), dot indicators |
| 4 | **Phone Input** | `phone_input_screen.dart` | mobileApp / security | Frictionless auth waterfall: SIM verify → SMS auto-read → manual OTP |
| 5 | **Profile Setup** | `profile_setup_screen.dart` | profile | Name entry, create Firestore profile |
| 6 | **Group Models** | `group_model_screen.dart` | goal, mobileMarketing, teamSpirit, wallet, groupChat | 5 templates: Funeral Welfare, Chama, Church, SACCO, Custom |
| 7 | **Group Create** | `group_create_screen.dart` | groupCreate, wallet, teamWork | 3-step wizard (details → contributions → roles) |
| 8 | **Invite Members** | `invite_members_screen.dart` | confirmation | Share invite code after creation |
| 9 | **Group List** | `group_list_screen.dart` | community (empty state) | List user's groups, Create/Join buttons |
| 10 | **Home Dashboard** | `home_screen.dart` | dashboard (empty state) | 5-tab bottom nav: Home, Members, Contrib, Timeline, More |
| 11 | **Member Detail** | `member_detail_screen.dart` | emptyState | Member info + contribution history |
| 12 | **Record Payment** | `record_payment_screen.dart` | recordPayment | Select type, member, amount, method |
| 13 | **Create Event** | `create_event_screen.dart` | events | Event type, title, amount, deadline |
| 14 | **Generate Report** | `generate_report_screen.dart` | report | Month/year picker → PDF generation |
| 15 | **Report List** | `report_list_screen.dart` | report | Report type selector |
| 16 | **OTP Verify** | `otp_verify_screen.dart` | security | Fallback manual OTP screen (kept for backward compat) |

## Auth Flow — Frictionless Waterfall

```
Phone Input → Verifying (0-2s SIM check) → Auto-read (2-8s SMS) → Manual OTP (after 15s)
         ↘                                      ↙
     Firebase Phone Auth (or Email bypass)
              ↓
   Profile exists? → Yes → Home Dashboard (with groups)
              ↓ No
        Profile Setup → Group List → Group Models → Group Create → Invite → Home
```

## Data Models (Firestore)

| Collection | Key Document Fields |
|-----------|-------------------|
| `groups` | name, description, inviteCode, createdBy, createdAt, stats, enabledFeatures |
| `members` | userId, name, phone, role, groupId, memberNumber, status, joinedAt |
| `contribution_types` | name, amount, frequency, mandatory, groupId |
| `contributions` | memberId, memberName, typeId, typeName, amount, status, method, paidAt |
| `events` | type, title, description, targetAmount, requiredPerMember, deadline, status |
| `timeline` | type, description, actorName, groupId, createdAt |
| `approvals` | title, description, amount, requestedBy, status, groupId |
| `announcements` | title, message, sentBy, sentByName, readBy |
| `documents` | name, url, uploadedBy, groupId |

## Group Models (Templates)

| Model | Contribution Types | Key Features |
|-------|-------------------|--------------|
| **Funeral Welfare** | Monthly Fee (KES 500), Death Contribution (KES 2000), Emergency Levy | Death benefits, welfare, emergency |
| **Investment Chama** | Share Purchase (KES 1000), Project Contribution, Loan Payment | Shares, dividends, projects |
| **Church Group** | Tithe (open), Offering (open), Building Fund (KES 2000), Ministry Project | Tithes, offerings, building fund |
| **SACCO** | Share Contribution (KES 500), Loan Repayment, Savings Deposit | Shares, loans, savings |
| **Custom** | User-defined | Full flexibility |

## Key Technical Decisions

- Member doc ID = Firebase Auth UID (enables `isGroupMember()` in Firestore rules)
- `sms_autofill` for SIM phone hint + SMS auto-read
- Bypass mode creates Email Auth user at `{cleanPhone}@bypass.ledger` with password `bypass123`
- All illustrations from unDraw CDN (full color, no opacity effects)
- `svg.card_network_gradient` removal from `AppColors` (clean solid colors)

## Firestore Rules (Security)

- `isSignedIn()` checks `request.auth != null`
- `isGroupMember(groupId)` checks `exists(/databases/$(database)/documents/groups/$(groupId)/members/$(request.auth.uid))`
- `hasRole(groupId, role)` checks member doc role field
- Chairman: full write access; Treasurer: approved contributions; Member: read only
- Timeline: `allow create: if hasRole(...)` (relaxed — no Cloud Functions)

## Build Commands

```bash
flutter clean
flutter pub get
flutter analyze    # Should be 0 issues
flutter build apk --debug
flutter build apk --release    # For release signing
```

## All Screens Have unDraw SVGs

Every screen features an online unDraw SVG illustration displayed at full color with no opacity overlays, giving the app a clean, modern, and attractive look. The SVGs load from the unDraw CDN and cover all contexts: auth, onboarding, groups, payments, events, reports, and empty states.
