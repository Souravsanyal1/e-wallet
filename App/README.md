# EliteChat

A wallet-authenticated messaging app: direct chats, groups, channels, and token-based premium subscriptions. Built with Flutter (Android, iOS, Web), GetX, and Supabase.

> **Status:** Draft v0.1 (documentation phase). Nothing here is implemented yet. Items marked **[VERIFY]** depend on third-party behavior that must be confirmed against current documentation before building.

## Documentation

| Document | What it covers |
| --- | --- |
| [docs/architecture.md](docs/architecture.md) | Layers, GetX conventions, data flow, realtime, backend, ADR log |
| [docs/security.md](docs/security.md) | Threat model, authorization, E2EE stance, client/backend hardening, checklist |
| [docs/design.md](docs/design.md) | Design principles, tokens, components, screens, accessibility, localization |
| [docs/database.md](docs/database.md) | Schema, ERD, RLS policies, storage rules (draft SQL) |
| [docs/web3-auth-and-payments.md](docs/web3-auth-and-payments.md) | Wallet sign-in flow, session minting, token payment verification |
| [docs/roadmap.md](docs/roadmap.md) | Phases, deliverables, exit criteria, risks |
| [docs/testing.md](docs/testing.md) | Test strategy, RLS tests, CI pipeline |
| [docs/contributing.md](docs/contributing.md) | Conventions, PR checklist, definition of done |

## Tech stack

| Concern | Choice |
| --- | --- |
| UI / app | Flutter + Dart (Android, iOS, Web) |
| State, DI, routing | GetX |
| Backend | Supabase (Postgres + RLS, Auth, Realtime, Storage, Edge Functions) |
| Wallet connection | WalletConnect / Reown-compatible package **[VERIFY: Flutter Web support]** |
| Push | Firebase Cloud Messaging |
| Pattern | Repository pattern; controllers never touch the database or chain directly |

## Getting started

Prerequisites: Flutter (stable channel), Dart 3+, [Supabase CLI](https://supabase.com/docs/guides/cli), Docker (for the local Supabase stack), a Firebase project (for push, optional in early phases).

```bash
# 1. Install dependencies
flutter pub get

# 2. Start local backend (applies supabase/migrations)
supabase start

# 3. Run the app
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon key printed by `supabase start`> \
  --dart-define=WALLET_PROJECT_ID=<walletconnect/reown project id> \
  --dart-define=AUTH_DOMAIN=localhost
```

On a physical Android device or emulator, `127.0.0.1` is not your computer; use your machine's LAN IP (or `10.0.2.2` on the Android emulator).

### Configuration

| Key | Secret? | Notes |
| --- | --- | --- |
| `APP_ENV` | No | `dev`, `staging`, `prod` |
| `SUPABASE_URL` | No | Project URL |
| `SUPABASE_ANON_KEY` | No (public by design) | Safe only because every table has RLS |
| `WALLET_PROJECT_ID` | No | Public identifier for the wallet relay |
| `AUTH_DOMAIN` | No | Domain bound into wallet sign-in messages |

**Never** put the Supabase `service_role` key, JWT secret, RPC provider keys, or FCM server credentials in the Flutter app, in `--dart-define`, or in the repository. Those live only in Supabase Edge Function secrets.

## Repository layout

```
elite_chat/
├── lib/                 # Flutter app (see docs/architecture.md)
├── supabase/
│   ├── migrations/      # SQL migrations (source of truth for schema + RLS)
│   ├── functions/       # Edge Functions (auth-nonce, auth-verify, verify-payment, ...)
│   ├── tests/           # pgTAP RLS tests
│   └── seed.sql
├── test/  integration_test/
├── docs/                # This documentation
└── README.md
```

## Ground rules (short version)

1. UI never queries the database; controllers never run blockchain transactions; both go through repositories/services.
2. Authorization is enforced by Postgres RLS and server-side functions, never by client checks.
3. No private keys, seed phrases, or service-role keys in the client.
4. No home-made cryptography. Use vetted, audited libraries.
5. Do not describe the app as "end-to-end encrypted" until E2EE is implemented and independently reviewed.

## Reporting a vulnerability

Please report security issues privately to `security@<your-domain>` (placeholder) rather than opening a public issue. See [docs/security.md](docs/security.md#16-incident-response-and-disclosure).
