# EliteChat Security

Version 0.1 (draft) · Last updated 2026-10-13

This document defines the security model, requirements, and launch checklist. It is a design document, not an audit. Have it reviewed by a qualified security engineer, and commission an independent penetration test before public launch.

## 1. Principles

1. **The server is the security boundary.** Anything enforced only in Flutter code can be bypassed. Authorization lives in Postgres RLS and server-side functions.
2. **Default deny.** Every table has RLS enabled; access exists only where a policy grants it.
3. **Least privilege.** Clients get the anon key and a user JWT, nothing more. Elevated keys exist only in Edge Function secrets.
4. **No custom cryptography.** Use vetted, audited libraries and protocols.
5. **Minimize data.** Collect, log, and retain only what the product needs.
6. **Be honest in the UI and marketing.** Do not claim end-to-end encryption, anonymity, or "unhackable" anything that is not true.

## 2. Assets

| Asset | Why it matters |
| --- | --- |
| Account/session (JWT, refresh token) | Account takeover |
| Messages and attachments | Confidentiality, integrity |
| Social graph (who talks to whom, group membership) | Metadata is sensitive even without content |
| Wallet addresses linked to accounts | Public and linkable on-chain; deanonymization risk |
| Subscription entitlements and payment records | Financial integrity, fraud |
| Push tokens | Spam, tracking |
| Backend secrets (service role, RPC keys, FCM credentials) | Full-system compromise |

## 3. Threat actors

- Unauthenticated internet attacker (scraping, enumeration, brute force, spam).
- Authenticated malicious user (reading others' data, privilege escalation, abuse, free premium access).
- Phishing attacker targeting wallet users (fake sign-in or payment prompts).
- Malicious or compromised group/channel admin.
- Compromised device or malware on a user's device.
- Insider/operator with dashboard or database access.
- Supply-chain attacker (malicious or compromised packages).

## 4. Trust boundaries

```
[User device / wallet]  ──TLS──►  [Supabase API gateway: JWT check]
                                     │
                                     ├─► Postgres (RLS enforces per-row access)
                                     ├─► Storage (policies enforce per-object access)
                                     └─► Edge Functions (service role, verification logic)
                                              │
                                              └─► RPC provider / FCM (third parties)
```

Everything left of the gateway is untrusted. Third parties (RPC provider, FCM, wallet relay) see metadata and must not receive secrets or message content.

## 5. Threat model summary

| # | Threat | Mitigation | Phase |
| --- | --- | --- | --- |
| T1 | Replay of a captured wallet signature | Single-use nonce, short expiry, domain and chain binding, atomic nonce consumption | 2 |
| T2 | Phishing: user signs a malicious message | Human-readable SIWE-style message built server-side, clear UI copy, domain binding | 2 |
| T3 | Reading another user's messages via the API | RLS membership checks on `messages`, `conversation_members`, Storage | 1–3 |
| T4 | Privilege escalation in groups/channels (self-promote, add self) | Role changes only through checked RPC functions; column-level grants | 4 |
| T5 | Free premium via fake or replayed payment | Server-side chain verification, unique `(chain_id, tx_hash)`, sender must be the linked wallet, confirmations | 6 |
| T6 | Service-role key in the client or repo | CI secret scanning; keys only in Edge Function secrets; key rotation runbook | 1 |
| T7 | Stored XSS / content injection (Web) | Render message text as plain text; no HTML; sanitize links; CSP | 3 |
| T8 | Malicious file upload | Size/type limits, server-side MIME check, private bucket, signed URLs, EXIF stripping | 4 |
| T9 | User/handle/wallet enumeration | Rate limits; no wallet-address lookup API; uniform responses | 2–4 |
| T10 | Spam and harassment | Rate limits, blocks, reports, group join limits, channel posting rights | 4 |
| T11 | Token theft from a device | Secure storage on mobile, short-lived access tokens, refresh rotation, remote session revoke | 2 |
| T12 | Push notification content leakage | Generic payloads, no message text | 3 |
| T13 | Compromised dependency | Pin versions, review wallet/crypto packages, automated alerts, lockfile in CI | all |
| T14 | Metadata exposure to operators | Least-privilege dashboard access, MFA, audit logs, retention limits | 5 |

## 6. Authentication

Wallet sign-in details are in [web3-auth-and-payments.md](web3-auth-and-payments.md). Security requirements:

- The server generates the sign-in message and nonce; the client cannot choose the domain.
- Nonce: at least 128 bits of randomness, single use, expires in about 5 minutes, bound to the address.
- Verify domain (allowlist), chain ID, address, issued-at/expiry, and signature server-side. Support smart-contract wallets (EIP-1271) or document that they are unsupported.
- Sign-in never requests a transaction, token approval, or `eth_sendTransaction`.
- **Sessions:** short-lived access token, rotating refresh token, logout revokes the refresh token, and users can see and revoke active sessions.
- **Re-authentication** (fresh wallet signature) before sensitive actions: unlinking a wallet, deleting the account, changing payout or receiver settings.
- **Wallet loss = account loss** in the MVP. Document this in onboarding. Recovery (for example a second linked wallet) is a later feature and must be designed carefully, since recovery paths are a common attack route.

## 7. Authorization

- RLS is enabled on every table in exposed schemas. A migration check in CI fails if a table lacks RLS.
- Policies are written against the JWT (`auth.uid()`); never trust a user ID sent in a request body.
- Membership checks use `security definer` helper functions with `set search_path = ''` to avoid recursive policies and search-path hijacking. Revoke `execute` on helpers from `anon`.
- State-changing operations that involve more than one row (create DM, create group, add/remove member, change role, join gated channel) go through RPC functions that validate the caller's role.
- Use column-level grants to prevent clients from updating privileged columns (for example `role`, `joined_at`).
- Views over RLS-protected tables use `security_invoker = true`.

**Role matrix (target)**

| Action | Member | Admin | Owner |
| --- | :---: | :---: | :---: |
| Read/send messages (groups) | ✔ | ✔ | ✔ |
| Delete own messages | ✔ | ✔ | ✔ |
| Delete others' messages | ✘ | ✔ | ✔ |
| Add/remove members | ✘ | ✔ | ✔ |
| Promote/demote admins | ✘ | ✘ | ✔ |
| Edit group info | ✘ | ✔ | ✔ |
| Delete group / transfer ownership | ✘ | ✘ | ✔ |
| Publish to a channel | ✘ | ✔ | ✔ |

## 8. Data protection

**In transit:** TLS everywhere. No cleartext HTTP in release builds (Android network security config, iOS ATS).

**At rest:** rely on the hosting provider's disk encryption **[VERIFY current provider guarantees]**; this protects against stolen disks, not against someone with database access.

**Metadata minimization:** do not store IP addresses in application tables; keep message `read` state as a watermark; keep logs free of content.

**Retention:** define and implement retention for messages (user-deletable), nonces (purge after expiry), logs (short), and deleted accounts (see section 14).

## 9. End-to-end encryption (planned, not in MVP)

Until E2EE ships, messages are readable by the backend operator. **The app and website must not claim E2EE** until it is implemented, reviewed, and tested.

When designing E2EE (Phase 5):

- Use an audited protocol and implementation (for example a Signal-protocol-based library for direct chats and an MLS-based approach for groups). **[VERIFY: library maturity and Flutter/Web availability before committing]**
- Requirements to resolve up front: device key generation and storage, multi-device support, key backup/recovery, group membership changes (re-keying), forward secrecy expectations, attachment encryption, and how identity keys relate to wallet identity.
- Account for product trade-offs: server-side search, moderation, link previews, and push content are limited or impossible with E2EE.
- Wallet keys must **not** be reused as messaging keys, and the app never stores wallet private keys or seed phrases.
- Write an ADR and obtain an external cryptography review before launch.

## 10. Web3-specific risks

| Risk | Control |
| --- | --- |
| Blind-signing / phishing | Readable message, domain shown prominently, "this will not cost gas or move funds" copy |
| Address linkability | Do not display or expose wallet addresses by default; use handle/display name; warn that addresses are public on-chain |
| Fake token / wrong chain payments | Verify chain ID, token contract address, receiver, and amount server-side |
| Reorgs and unconfirmed transactions | Require a confirmation threshold before granting entitlement |
| Tx hash reuse across accounts | Unique `(chain_id, tx_hash)` and sender must equal the user's linked wallet |
| RPC provider lying or failing | Use a reputable provider, consider a second provider for high-value checks, fail closed |
| Wallet package vulnerabilities | Pin versions, review changelogs, keep updated |

## 11. Client app security

- **Secrets:** none in the client except public identifiers (Supabase URL, anon key, wallet project ID).
- **Local storage:** mobile uses Keychain/Keystore via `flutter_secure_storage` for tokens. **Web has no equivalent**; use short session lifetimes, and consider keeping the session in memory only on Web for higher assurance.
- **Logging:** never log tokens, signatures, nonces, or message content; strip logs in release.
- **Input validation:** validate lengths, formats, and UUIDs on the client for UX, and again in the database with `check` constraints.
- **Rendering user content:** show messages as plain text. If link detection or markdown is added later, use a sanitizing renderer and open links with a scheme allowlist (`https`), showing the real destination for suspicious links.
- **Deep links:** validate route and parameters; deep links open screens but never perform actions without user confirmation and server-side authorization.
- **Obfuscation:** build release with `--obfuscate --split-debug-info` and upload symbols to the crash reporter. Obfuscation slows reverse engineering; it is not a security control.
- **Optional hardening:** app lock with biometrics, screenshot blocking on sensitive screens, and clipboard timeouts. Certificate pinning adds operational risk (rotation outages); decide deliberately.
- **Web:** strict Content-Security-Policy, no inline scripts beyond what Flutter requires, `X-Content-Type-Options`, `Referrer-Policy`, `frame-ancestors 'none'`, and CORS restricted to your origins.

## 12. File and media security

- Private `chat-attachments` bucket; reads via short-lived signed URLs only after an RLS/membership check.
- Enforce maximum file size and an allowlist of MIME types at the bucket and in an Edge Function; verify magic bytes, not just the extension or declared type.
- Store under random names (`{conversation_id}/{uuid}`); never trust the client filename.
- Strip EXIF/location metadata from images before storing, or at upload time on the client and verified server-side.
- Limit image dimensions and pixel counts to prevent decompression abuse.
- Consider malware scanning for non-image files before enabling general file sharing.
- Never serve uploads from the app's own origin in a way that lets the browser execute them.

## 13. Abuse prevention

- **Rate limits:** nonce requests (per IP and per address), verification attempts, message sends, group creation, invites, and uploads. Enforce in Edge Functions and database constraints; Supabase gateway limits alone are not sufficient.
- **User tools:** block users, report messages/users/channels, leave and mute conversations.
- **Group controls:** member caps, admin-only invites option, join approval for public groups.
- **Enumeration:** no search by wallet address; handle search is rate limited and returns minimal fields.
- **Moderation:** reports go to a `reports` table reviewed through a restricted admin process. Establish a policy and legal process for unlawful content, including child-safety reporting obligations in your jurisdictions. **Consult legal counsel before launch.**

## 14. Privacy and compliance

- Maintain a data inventory: what is stored, why, where, for how long.
- Provide in-app account deletion that removes profile, wallet links, device tokens, memberships, and attachments, and defines what happens to messages in shared conversations (for example anonymize sender).
- Publish a privacy policy and terms before launch. Review applicable regulations (for example GDPR-style access/erasure rights, and rules around minors) with counsel.
- Wallet addresses and on-chain payments are public by nature; explain this plainly during onboarding and payments.

## 15. Backend and operations security

- Supabase dashboard: SSO/MFA for all operators, least-privilege roles, review access quarterly.
- Edge Function secrets stored only in Supabase secrets; separate secrets per environment.
- `service_role` usage restricted to Edge Functions that need it; each function re-validates the caller and input and does not blindly trust request data.
- Edge Functions verify the caller's JWT unless intentionally public (`auth-nonce`, `auth-verify`), which receive extra rate limiting and input validation.
- Migrations reviewed like application code; no manual schema changes in production.
- Backups enabled, restore tested at least once before launch.
- Alerts on spikes in auth failures, RLS denials, Edge Function errors, and unusual storage usage.
- Secret scanning (for example gitleaks) and dependency review in CI.

**Supply chain**

- Commit `pubspec.lock`; update intentionally.
- Review any wallet, crypto, or auth package (maintainer activity, issues, permissions) before adoption.
- Enable automated dependency alerts (Dependabot/Renovate) and run `flutter pub outdated` in CI reports.

## 16. Incident response and disclosure

**Severity levels:** SEV1 data exposure or key compromise; SEV2 auth bypass or privilege escalation without confirmed exploitation; SEV3 limited-impact vulnerabilities.

**Runbook outline**

1. Triage and assign an incident lead.
2. Contain: disable the affected Edge Function or policy, revoke sessions if needed, rotate secrets (service role, JWT secret if exposed, FCM, RPC keys).
3. Investigate using logs; preserve evidence.
4. Fix, add a regression test, and deploy.
5. Notify affected users and authorities where legally required.
6. Post-incident review with action items.

**Disclosure:** publish `security.txt` (Web) and a contact address; acknowledge reports promptly and agree on a disclosure timeline.

## 17. Security testing plan

| Test | When |
| --- | --- |
| pgTAP RLS tests: every table, every role (anon, member, non-member, admin, owner) | Every PR touching migrations |
| Edge Function unit tests: nonce replay, expiry, wrong domain/chain/address, tampered message, concurrent nonce use | Every PR touching functions |
| Static analysis (`flutter analyze`), secret scanning, dependency audit | Every PR |
| Manual abuse-case review for each new feature | Design phase |
| Independent penetration test (mobile, web, backend) | Before public launch |
| Cryptography review | Before claiming E2EE |

See [testing.md](testing.md) for examples.

## 18. Pre-launch checklist

- [ ] RLS enabled on every table; CI check in place; pgTAP tests passing
- [ ] No `service_role` or other secrets in client, repo history, or build artifacts
- [ ] Nonce replay, expiry, domain/chain binding tests passing
- [ ] Payment verification tested on testnet including reorg, wrong token, wrong amount, replayed tx
- [ ] Storage buckets private (except avatars), signed URL TTLs set, size/type limits enforced
- [ ] Rate limits active on auth, messaging, upload endpoints
- [ ] Release builds obfuscated; debug logging disabled
- [ ] Web CSP and security headers configured and tested
- [ ] Push payloads contain no message content
- [ ] Block/report flow working; moderation process and legal contacts defined
- [ ] Account deletion works end to end
- [ ] Backups enabled and restore tested; alerting configured
- [ ] Privacy policy, terms, `security.txt` published
- [ ] Penetration test completed and findings resolved
- [ ] Marketing and UI copy contain no unverified security claims (especially E2EE)

## 19. Known limitations (MVP)

- Messages are not end-to-end encrypted.
- Wallet loss means account loss.
- Web sessions have weaker local protection than mobile.
- Wallet addresses are publicly linkable on-chain.
- Third parties (FCM, RPC provider, wallet relay) see some metadata.
