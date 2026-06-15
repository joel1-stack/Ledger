# Ledger — Community OS

**The record your community keeps forever.**

A Flutter mobile app for funeral welfare groups, chamas, churches, SACCOs, and community project coordination. Built with Firebase + Riverpod.

## Paradigm: Group-First Identity

No global user database. No phone verification at the front door. Identity lives **inside each group**.

- Open app → pick a group model → create or join → SIM auto-match → OTP only when needed
- Firebase Anonymous Auth (invisible, instant)
- SIM sense via `sms_autofill` — match phone to group member list locally
- OTP fallback for new devices or role elevation

## Tech Stack

| Layer | Choice |
|-------|--------|
| Framework | Flutter 3.10.8+ |
| State | Riverpod 2.x + GoRouter |
| Backend | Firebase (Spark) — Auth, Firestore, Storage |
| Auth | Anonymous Auth + SIM sense + Phone Auth (fallback) |
| Images | Unsplash real photos (not SVGs) |

## Flow

```
DOWNLOAD APP
    │
    ▼
ANONYMOUS LOGIN (invisible, 0s)
    │
    ▼
"What are you building?"  ← 6 group models with real photos
(Funeral, Chama, Wedding, Project, SACCO, Church, Join Existing)
    │
    ├──► CREATE GROUP
    │       ├── Group name, rules, contribution types
    │       ├── Enter name & phone
    │       ├── SIM auto-match → Chairman instantly
    │       └── OTP fallback if SIM doesn't match
    │
    └──► JOIN GROUP
            ├── Enter invite code
            ├── SIM auto-match → "Welcome back, Mary!" (0s, no SMS)
            └── OTP fallback to claim profile
```

## Key Features

- **Group Models**: 6 pre-built templates with contribution types
- **SIM Sense**: Read phone number locally, match against member list
- **Role-Based Access**: Chairman, Treasurer, Secretary, Member
- **Contributions**: Record payments, track outstanding
- **Events**: Create events with required contributions
- **Reports**: Generate PDF reports with share
- **Timeline**: Chronological activity feed
- **Approvals**: Request/approve expenses
- **Announcements**: In-app broadcast
- **Documents**: Upload & share files

## Setup

```bash
flutter clean
flutter pub get
flutter analyze    # Should be 0 issues
flutter build apk --debug
```

Firebase project: `ledger-45f58` (Spark plan, package: `com.ledgerapp.ke`)
