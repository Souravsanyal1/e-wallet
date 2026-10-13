# EliteChat (e-wallet)

A production-grade wallet-authenticated Web3 messaging application built with **Flutter**, **GetX**, and **Supabase**. Supports Direct Messages, Community Groups, Token-Gated Broadcast Channels, and On-Chain USDC Subscriptions.

## ✨ Features

- **Web3 Wallet Sign-In (EIP-4361)**: Nonce-based cryptographic signature authentication with MetaMask, Rainbow, Coinbase Wallet, and Injected browser providers.
- **Direct & Group Chats**: Realtime reactive message streams, delivery status ticks (`pending`, `sent`, `delivered`, `read`), typing indicators, and quoted replies.
- **Token-Gated Broadcast Channels**: Community channels with on-chain entitlement verification.
- **Wallet & Subscription Manager**: View connected address, token balances (ETH, USDC), and subscribe to Pro Trader or Alpha Insider tiers with simulated transaction lifecycles (`Waiting for wallet` → `Submitted` → `Confirming` → `Active`).
- **Postgres Row Level Security (RLS)**: Strict data isolation where database queries are governed by Postgres security policies.
- **Cross-Platform Responsive Design**:
  - Compact (< 600 dp): Bottom navigation.
  - Medium & Expanded (≥ 840 dp): NavigationRail and Master-Detail dual-pane split view.
- **Bilingual & Dual Theme**: English (`en_US`) and Bengali (`bn_BD`), Dark (Ink & Warm Gold) and Light modes.

## 🚀 Tech Stack

- **Framework**: Flutter 3.44+ (Android, iOS, Web, Windows)
- **State & Routing**: GetX
- **Backend & DB**: Supabase (Postgres + RLS, Edge Functions)
- **Typography & Icons**: Google Fonts (Inter), Material Symbols

## 🛠 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Run Application
```bash
flutter run
# or for Web:
flutter run -d chrome
```

## 📂 Repository Structure
```
├── lib/
│   ├── core/              # Theme, bindings, localization, widgets, services, errors
│   ├── data/              # Models and repository interfaces + implementations
│   ├── modules/           # Auth, Chats, Conversation, Groups, Channels, Wallet, Profile
│   └── routes/            # AppPages and AppRoutes
├── supabase/
│   ├── migrations/        # Complete SQL schema & RLS policies (from database.md)
│   └── seed.sql           # Development seed data
├── test/                  # Unit and widget tests
└── App/                   # Design, Architecture, Security, and Web3 specifications
```
