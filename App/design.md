# EliteChat Design

Version 0.1 (draft) · Last updated 2026-10-13

Colors, fonts, and the brand name treatment below are **proposals** to unblock development. Replace them when brand work is done; the token structure should stay.

## 1. Design principles

1. **Clarity over cleverness.** Messaging is a utility. Fast to scan, obvious to use.
2. **Trust is visible.** Wallet prompts, payments, and privacy states are explained in plain language.
3. **Calm by default.** Minimal chrome, restrained motion, no dark patterns or notification spam.
4. **Works for everyone.** Accessible contrast, scalable text, screen-reader support, Bengali and English from day one.
5. **One app, three form factors.** Phone, tablet, and desktop web share components but not necessarily layouts.

## 2. Visual direction (proposed)

Dark-first, premium feel: deep ink surfaces with a warm gold accent. A light theme is provided for accessibility and preference. Respect the system theme by default.

### Color tokens

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| `background` | `#0E1116` | `#FFFFFF` | App background |
| `surface` | `#161B22` | `#F5F6F8` | Cards, bars, composer |
| `surfaceHigh` | `#1E252E` | `#E9ECF0` | Incoming bubble, inputs, sheets |
| `primary` | `#E5B84B` | `#8A6A00` | Brand accent, primary buttons, outgoing bubble tint |
| `onPrimary` | `#0E1116` | `#FFFFFF` | Text/icons on primary |
| `textPrimary` | `#F0F3F6` | `#12161C` | Body text |
| `textSecondary` | `#9AA4B2` | `#545E6B` | Metadata, timestamps |
| `outline` | `#2A323D` | `#D3D8DF` | Dividers, borders |
| `success` | `#3FB27F` | `#1E7D55` | Sent/confirmed |
| `warning` | `#E0A030` | `#8F5F00` | Pending, caution |
| `error` | `#F0616D` | `#C0392B` | Failures, destructive actions |

Verify every text/background pair against WCAG AA (4.5:1 for body text, 3:1 for large text and UI components) with a contrast checker before finalizing. Never rely on color alone to convey state; pair with an icon or label.

### Typography

- Latin: Inter (or system default as a fallback).
- Bengali: Noto Sans Bengali, bundled in `assets/fonts` so Web and mobile render consistently. Test conjuncts and line height with real Bengali text.
- Provide a font fallback list so missing glyphs never render as boxes.

| Style | Size / line height | Weight | Use |
| --- | --- | --- | --- |
| `displayLarge` | 32 / 40 | 700 | Onboarding headlines |
| `titleLarge` | 22 / 28 | 600 | Screen titles |
| `titleMedium` | 16 / 24 | 600 | List item titles, names |
| `bodyLarge` | 16 / 24 | 400 | Message text |
| `bodyMedium` | 14 / 20 | 400 | Secondary text |
| `labelSmall` | 12 / 16 | 500 | Timestamps, badges |

Bengali text usually needs slightly more line height than Latin. Use a minimum of 1.5 for Bengali body text. Support the user's OS text scale up to at least 200% without clipping.

### Spacing, shape, elevation

- 4 dp spacing grid: `4, 8, 12, 16, 24, 32, 48`.
- Corner radius: `8` (inputs, cards), `16` (bubbles, sheets), `999` (avatars, pills).
- Prefer tonal surfaces and outlines to heavy shadows, especially in dark theme.
- Minimum touch target 48 × 48 dp.

### Iconography

Use one consistent icon set (Material Symbols rounded) at 24 dp; 20 dp in dense lists. Icons that carry meaning must have a semantic label.

## 3. Theme implementation (Flutter)

```dart
// core/theme/app_colors.dart
abstract final class AppColors {
  static const inkBg = Color(0xFF0E1116);
  static const inkSurface = Color(0xFF161B22);
  static const inkSurfaceHigh = Color(0xFF1E252E);
  static const gold = Color(0xFFE5B84B);
}

// core/theme/app_theme.dart
abstract final class AppTheme {
  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.inkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          onPrimary: AppColors.inkBg,
          surface: AppColors.inkSurface,
          surfaceContainerHighest: AppColors.inkSurfaceHigh,
        ),
      );
}
```

Components read from `Theme.of(context)`; they never hard-code colors. Use `Get.changeThemeMode` (or `GetMaterialApp.themeMode`) with the user's choice persisted in settings.

## 4. Navigation and layout

### Information architecture

```
Auth: Splash → Onboarding → Wallet login → (Signature request)
Main: Chats · Groups · Channels · Wallet · Profile
Secondary: Notifications, Settings, Subscription plans/history, Contacts
```

Bottom navigation has at most five destinations. If "Groups" and "Channels" feel redundant on small screens, merge them into a "Communities" tab with a segmented control; decide in usability testing.

### Responsive breakpoints (Material window size classes)

| Class | Width | Layout |
| --- | --- | --- |
| Compact | < 600 dp | Bottom navigation, single pane |
| Medium | 600–839 dp | Navigation rail, single or two pane |
| Expanded | ≥ 840 dp | Navigation rail + list/detail two-pane (chat list left, conversation right) |

Constrain message column width on large screens (about 720 dp max) for readable line lengths.

## 5. Key screens

### Wallet login

```
┌───────────────────────────┐
│          EliteChat        │
│                           │
│   Sign in with your       │
│   wallet                  │
│                           │
│  Your wallet is your      │
│  account. Signing in      │
│  doesn't move funds or    │
│  cost gas.                │
│                           │
│ [ Connect wallet ]        │
│                           │
│  New to wallets? Learn    │
│  more                     │
└───────────────────────────┘
```

Signature request screen shows: the domain, the human-readable statement, "No transaction. No fees.", and `Sign` / `Cancel`. If the wallet app does not return, show a retry and a "Having trouble?" help link.

### Chat list

```
┌───────────────────────────┐
│ Chats              🔍  ✎  │
├───────────────────────────┤
│ (A) Alice            09:41│
│     Sounds good, see you… │
│ (G) Design team   ③  Fri  │
│     Sam: uploaded v2      │
│ (A) Bob            Thu    │
│     ✓✓ Thanks!            │
├───────────────────────────┤
│ Chats Groups Channels ... │
└───────────────────────────┘
```

Rows: avatar, name, last message preview (single line, truncated), time, unread count, mute icon. Swipe actions: mute, archive (later), delete (with confirm).

### Conversation

```
┌───────────────────────────┐
│ ← Alice            ⋮      │
├───────────────────────────┤
│        Today              │
│  ┌──────────────┐         │
│  │ Hi! Ready?   │ 09:40   │
│  └──────────────┘         │
│         ┌───────────────┐ │
│  09:41  │ Yes, one sec  │ │
│  ✓✓     └───────────────┘ │
│  Alice is typing…         │
├───────────────────────────┤
│ ＋  [ Message…      ] ➤   │
└───────────────────────────┘
```

## 6. Chat component specs

| Component | Spec |
| --- | --- |
| Message bubble | Max width 75% of pane (or 520 dp). Outgoing aligned end with `primary` tint; incoming aligned start with `surfaceHigh`. Consecutive messages from the same sender within 2 minutes group together (tighter spacing, one avatar/timestamp). |
| Timestamp | Shown per group; day separators ("Today", "Yesterday", date). Localized formats. |
| Delivery state | `pending` clock icon, `sent` single check, `delivered` double check, `read` double check in accent, `failed` red icon with tap-to-retry. Always with an accessible label. |
| Reply | Quoted preview above the text; tap scrolls to original. |
| Attachments | Image thumbnails with fixed aspect placeholder to avoid layout jumps; file chips with name, size, icon. |
| Composer | Multiline, grows to 5 lines, then scrolls. Send disabled when empty. Attachment button. Preserve draft per conversation. |
| Typing indicator | Three-dot animation, replaced by static text when reduce-motion is on. |
| Unread badge | Count up to 99, then "99+". |
| Empty chat | Friendly prompt with a primary action ("Say hello"). |

## 7. States (every screen needs all of them)

| State | Pattern |
| --- | --- |
| Loading | Skeleton placeholders for lists; spinner only for short blocking actions |
| Empty | Illustration or icon, one sentence, one action |
| Error | Plain-language message, retry button, no stack traces or codes in the UI (codes available under "Details") |
| Offline | Non-blocking banner; queued actions explained |
| Permission denied / access lost | Explain ("You're no longer a member of this group") and navigate back |

## 8. Wallet and payment UX

- Explain what is being asked before opening the wallet app.
- Show the exact plan, price, token, network, and receiving address (shortened with copy and "view on explorer").
- Use clear states: `Waiting for wallet` → `Transaction submitted` → `Confirming (n/N)` → `Active`, with a way to resume if the app is closed.
- Never display raw error strings from wallets or RPC providers; map to friendly messages.
- Format addresses as `0x1234…abcd` with a copy action; never as the primary identity in chats.
- Always show a "Not financial advice / you control your funds" style notice only if legal review requires it; otherwise keep copy concise.

## 9. Microcopy guidelines

- Short, direct, human. Sentence case. No jargon ("sign a message" is clearer than "authenticate via EIP-4361").
- Errors say what happened and what to do next ("Couldn't send. Check your connection and tap to retry.").
- Destructive actions name the consequence ("Delete this group for everyone?").
- Do not use the words "encrypted" or "private" in UI copy unless literally true for that feature.

## 10. Accessibility

- Contrast: WCAG AA minimum.
- Targets: ≥ 48 dp; adequate spacing between adjacent actions.
- Semantics: label all icon buttons; announce new incoming messages politely (not for every message in busy groups); describe delivery states; group list-item content into one focusable node with a meaningful label ("Alice, 2 unread, Sounds good, 9:41").
- Focus order and keyboard navigation on Web and tablets (Tab, Enter to send, Shift+Enter newline, Esc to close dialogs).
- Honor text scaling, bold text, reduce motion, and high-contrast settings.
- Do not use time-limited toasts for critical information.

## 11. Motion

| Use | Duration | Notes |
| --- | --- | --- |
| Micro-interactions (press, toggle) | 100–150 ms | Ease-out |
| Page/transition | 200–300 ms | Platform-appropriate defaults |
| Message insert | ~150 ms fade/slide | Disabled when reduce-motion is on |

Avoid gratuitous animation in message lists; it hurts performance and readability.

## 12. Localization

- Languages: English (`en_US`) and Bengali (`bn_BD`) at launch; code is RTL-ready for future languages.
- All strings live in `localization/`; no hard-coded text in widgets. Prefer ICU-style plurals/parameters (consider the `intl` message format or Flutter's `gen_l10n`) over GetX's simple map when plural rules matter, since Bengali plural/number formatting differs.
- Dates, times, and numbers via `intl` with the active locale. Offer Bengali digits as a setting, not a forced default.
- Allow ~30% text expansion in layouts; avoid fixed-width buttons.
- Language picker in Settings; default to the device language.

## 13. Asset and component inventory

- App icon, adaptive Android icon, iOS icon set, Web favicon and PWA manifest icons.
- Splash screen (native + Flutter).
- Empty-state illustrations (chats, groups, channels, notifications, wallet not connected).
- Reusable widgets in `core/widgets`: `AppButton`, `AppTextField`, `AppLoader`, `ErrorView`, `EmptyState`, `Avatar`, `AddressChip`, `StatusBadge`.

## 14. Design deliverables checklist

- [ ] Brand name treatment, final palette, and type choice approved
- [ ] Design tokens implemented in `app_colors.dart`, `app_text_styles.dart`, `app_dimensions.dart`
- [ ] Wireframes for all screens in section 5 and the wallet/payment flow
- [ ] Hi-fi mockups: compact and expanded layouts, dark and light
- [ ] Empty/loading/error states designed for each screen
- [ ] Accessibility review with a screen reader (TalkBack and VoiceOver)
- [ ] Bengali content review by a native speaker
- [ ] Usability test with at least five representative users before beta
