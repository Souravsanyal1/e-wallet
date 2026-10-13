# EliteChat Roadmap

Version 0.1 (draft) · Last updated 2026-10-13

Sizing uses T-shirt sizes (S/M/L/XL) instead of dates, because team size and velocity are not yet known. Convert to calendar estimates after Phase 0.

## MVP definition

A user can sign in with a wallet, find another user by handle, and exchange realtime text and image messages on Android, iOS, and Web, with RLS-enforced privacy and push notifications. Groups, channels, and subscriptions follow the MVP.

**Out of scope for MVP:** E2EE, voice/video calls, stories, bots, multi-wallet recovery, offline outbox, message search.

## Phase 0: Decisions and spikes (S)

Goal: remove the biggest unknowns before building.

- [ ] Spike: wallet package works on Android, iOS, and Web (connect + `personal_sign`)
- [ ] Spike: Supabase session creation from a wallet signature (options A/B in the web3 doc)
- [ ] Choose crash reporting provider and CI platform
- [ ] Confirm launch chains/tokens and target markets
- [ ] Brand direction approved (palette, name treatment)
- [ ] Legal review kickoff: privacy policy, terms, moderation obligations

**Exit criteria:** ADR-003 finalized; a throwaway prototype signs in on all three platforms.

## Phase 1: Foundation (M)

- [ ] Flutter project, flavors/environments, `--dart-define` config
- [ ] GetX routes, bindings, guards; `core/` theme, widgets, errors, `Result`
- [ ] Supabase init, local dev stack, first migrations with RLS enabled
- [ ] CI: analyze, test, secret scan, migration reset check
- [ ] Localization scaffold (en, bn)
- [ ] Logging service and error reporting

**Exit criteria:** app boots on all platforms, theme switching works, CI green, an RLS test runs in CI.

## Phase 2: Authentication (L)

- [ ] `auth-nonce` and `auth-verify` Edge Functions with replay/expiry tests
- [ ] Wallet connect UI and signature request screen
- [ ] Profile creation (handle, display name, avatar)
- [ ] Session persistence, refresh, logout, active-session list
- [ ] Route guards and splash session check

**Exit criteria:** all sign-in test cases in the web3 doc pass; security review of the auth flow completed.

## Phase 3: Direct messaging (XL)

- [ ] Handle search and `create_direct_conversation`
- [ ] Chat list with unread counts and last message
- [ ] Conversation screen: send, pagination, optimistic send, retry, dedupe
- [ ] Realtime subscriptions with reconnect backfill
- [ ] Typing indicator, read watermark
- [ ] Push notifications (generic payloads) and deep links
- [ ] Block and report
- [ ] Image attachments with private storage and signed URLs

**Exit criteria:** pgTAP tests prove non-members cannot read messages or attachments; messaging works on all platforms; basic load test passes.

**MVP release candidate after Phase 3**, subject to security checklist items marked for phases 1–3.

## Phase 4: Community (XL)

- [ ] Groups: create, members, roles, invite/leave, admin moderation
- [ ] Channels: public/private, admin posting, subscribe/join
- [ ] File attachments with validation and size limits
- [ ] Rate limits and abuse controls (group caps, invites)
- [ ] Notifications screen and per-conversation mute

**Exit criteria:** role matrix in security.md verified by tests for every action.

## Phase 5: Privacy hardening (L)

- [ ] E2EE design ADR, library selection, external crypto review
- [ ] Implement E2EE for direct chats, then groups
- [ ] Push payload and caching review under E2EE
- [ ] Independent penetration test; fix findings
- [ ] Account deletion and data export flows

**Exit criteria:** pen test clean of high/critical issues; E2EE claims approved by reviewer.

## Phase 6: Web3 utility (L)

- [ ] Plans admin tooling (service-side, not in the client)
- [ ] Payment UI and `verify-payment` Edge Function
- [ ] Confirmation job, expiry job, entitlement checks
- [ ] Token-gated channels via `join_channel`
- [ ] Testnet end-to-end tests, then mainnet dry run with small amounts

**Exit criteria:** all payment test cases pass on testnet, including replay and reorg handling.

## Launch readiness

- [ ] Security checklist in [security.md](security.md#18-pre-launch-checklist) complete
- [ ] Store listings, privacy labels, and Web hosting with security headers
- [ ] Monitoring, alerting, backup restore drill
- [ ] Support and moderation process staffed
- [ ] Beta with a limited group; collect crash and usability feedback

## Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Wallet package lacks reliable Web or maintained support | Medium | High | Phase 0 spike; wrap behind `WalletService` so the package is swappable |
| Wallet-to-Supabase session creation proves awkward | Medium | High | Spike options A/B early; fallback is a thin custom session service |
| RLS mistakes expose data | Medium | Critical | Policy-per-test rule, CI checks, pen test |
| Realtime scaling or cost surprises | Medium | Medium | Load test in Phase 3; limit subscriptions to open screens |
| E2EE harder than planned across devices/Web | High | High | Defer to Phase 5; do not market E2EE before delivery |
| Payment fraud / verification bugs | Medium | High | Server-side checks, testnet tests, small initial limits |
| Regulatory or moderation obligations | Medium | High | Legal review in Phase 0; report/block tools from Phase 3 |
| GetX misuse causing leaks/tangled state | Medium | Medium | Conventions in architecture.md, code review checklist |
| Scope creep | High | Medium | MVP definition above; changes require roadmap update |

## Success metrics (to refine)

- Sign-in success rate and median time to first message
- Message delivery latency (p50/p95) and failed-send rate
- Crash-free sessions
- Day-7 retention
- Zero confirmed cross-user data exposure incidents
