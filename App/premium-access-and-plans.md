# EliteChat Premium: Access Rules, Plans, Token Pricing, and Timer

Version 0.3 (draft) · Last updated 2026-10-13

Premium is bought **only with the $E-FORCE token**. There is no Google Play Billing and no card payment. This file defines what Premium and free users get, what nobody gets, the plans and prices, the timer, how token payment works worldwide, and how to distribute the app so token-only payment is workable. It extends [premium-e-force.md](premium-e-force.md). Where the two files differ, **this file wins**.

**What changed in v0.3**

- Google Play Billing, regional USD tiers, and the Play purchase backend are removed. Token is the only payment method.
- One **global token price** (section 3).
- New **distribution and store-policy section** (section 2). Token-only payment has real consequences for Google Play and the App Store, and you should read it before building.
- Backend simplified to token verification plus a grants ledger (section 9).

All numbers are **proposals** stored in the database, so they can change without an app release. **[DECIDE]** = product decision. **[VERIFY]** = confirm against current official documentation. This is not legal or tax advice.

---

## 1. Summary

| Topic | Decision |
| --- | --- |
| Payment | $E-FORCE token only, one-off period purchases |
| Plans | 1 month, 2 months, 3 months, 1 year, 2 years |
| Price | One global price per plan, pegged to a USD list price through an admin-set E-FORCE reference price |
| Account | One Premium status per account. Time stacks |
| Server | Only the server decides who is Premium |
| Features | Identical in every country and on every platform |
| Distribution | Web app and direct Android download carry the full purchase flow. Store builds follow section 2 |

---

## 2. Distribution and store rules (read first)

### The problem

Based on Google's published Payments policy (verify the current text before launch):

- Apps distributed on **Google Play** that sell in-app digital features must use Google Play's billing system, unless a specific exception or program applies. A Premium badge and higher limits are digital features.
- Google's policy states that tokenized digital assets used for in-app purchases of digital content fall under the same rule.
- Apps may not steer users inside the app to another payment method (buttons, links, or messaging) unless an allowance or program covers it.
- Apple's App Store has a similar in-app purchase rule on iOS. **[VERIFY]**

So an app on Google Play that lets people buy Premium with E-FORCE inside the app is likely to be rejected or removed. Token-only payment is possible, but it changes where and how you distribute.

### Distribution options

| Option | Purchase in the app? | Risk | Notes |
| --- | --- | --- | --- |
| **A. Web app (PWA)** | ✅ Full token purchase | Low | Works on every device, including iPhone. No store review |
| **B. Direct Android APK from your own site** | ✅ Full token purchase | Low to medium | Users must allow installs from unknown sources and may see Play Protect warnings. You handle updates and APK signing. Publish the APK's SHA-256 so users can verify it |
| **C. Alternative Android stores** | ✅ Usually | Medium | Each store has its own rules and review. **[VERIFY]** per store |
| **D. Google Play listing, status-only app** | ❌ No buy button | Medium to high | The app shows Premium status and features but never sells or links to the purchase. Google may still treat features consumed in-app as digital goods, so ask Play policy support before relying on this. **[VERIFY]** |
| **E. Apple App Store, status-only app** | ❌ No buy button | Medium to high | Same idea and same uncertainty. **[VERIFY]** |
| **F. Google Play with Play Billing** | Play Billing instead of token | Low | Not your choice for now, but it is the safe fallback if D is rejected |

**Recommended starting point:** launch with **A + B** (Web and direct APK), since they support the full token flow with no store conflict. Treat D and E as later experiments after written confirmation from the stores. Keep F as a ready fallback (it was designed in v0.2 of this file and needs only a `play` build flavor and a verify function).

### Rules if you use option D or E (status-only store builds)

- No buy button, price, token amount, or link to the purchase page anywhere in the store build.
- No text that tells users to pay elsewhere ("cheaper on our website" is a violation risk).
- Premium status, badge, and limits are read from the account. A user who bought on the Web simply sees Premium active.
- Wallet **sign-in** can stay. Wallet **payment** code is excluded from the build using a Flutter flavor (`store` vs `web`/`direct`), so it cannot be reached.
- If your app lets users hold, earn, or trade tokens inside the store build, read Google's blockchain-based content policy and the matching Apple rules. **[VERIFY]**

### Flavors

| Flavor | Contains token payment? |
| --- | --- |
| `web` | Yes |
| `direct` (APK from your site) | Yes |
| `store` (Google Play / App Store, status-only) | **No** |

---

## 3. Plans and token prices

### 3.1 Price list

Each plan has a USD **list price** and a **token price**.

| Plan key | Duration | Days | USD list | **E-FORCE price** | Per month (E-FORCE) | Discount vs 1 month |
| --- | --- | --- | --- | --- | --- | --- |
| `premium_1m` | 1 month | 30 | $4.99 | **500** | 500 | none |
| `premium_2m` | 2 months | 60 | $9.49 | **950** | 475 | 5% |
| `premium_3m` | 3 months | 90 | $13.49 | **1,350** | 450 | 10% |
| `premium_12m` | 1 year | 365 | $47.99 | **4,800** | 400 | 20% |
| `premium_24m` | 2 years | 730 | $83.99 | **8,400** | 350 | 30% |

The token amounts above assume a reference price of **$0.01 per E-FORCE**. This is an example. The real token price may be different. **[DECIDE]** the USD list prices and the reference price.

### 3.2 How the token price is calculated

```
token_price = round_to_tidy( usd_list_price ÷ e_force_reference_price_usd )
```

- `e_force_reference_price_usd` is set by an admin from an approved price source and reviewed on a schedule (for example weekly). An alert fires if the market price moves more than a set percent from the reference.
- The admin panel previews the new token prices before publishing, and every price change needs a reason and is audit-logged.
- The price shown at checkout is **locked for 30 minutes** **[DECIDE]**. After that the user must start checkout again.
- If you prefer to ignore USD and use fixed token amounts, skip the formula and just edit the token price per plan. The cost is that real-world value swings with the token price.

### 3.3 Worldwide pricing

- **One global price.** A buyer's country cannot be reliably proven on-chain (a VPN, a new wallet, or a borrowed wallet defeats location checks), so regional discounts are not safe. A user in Dhaka and a user in New York pay the same number of tokens.
- Features and limits are the same in every country.
- If cheaper access for lower-income markets matters, handle it through **admin-granted promotional periods** (campaigns, partners) rather than regional token prices. **[DECIDE]**
- Show the USD equivalent next to the token amount on the checkout screen, as an estimate, using the same reference price.

### 3.4 Token payment rules

- Price, token contract, chain, and receiver come **only from the `plans` table**, never from the app.
- Amounts are stored in **base units** (integer). With 18 decimals, 500 E-FORCE = `500 × 10^18`. **[VERIFY decimals]**
- One-off purchases only. No recurring token approvals (high risk).
- Payments are final. The checkout screen says so. Manual refunds only through admin tooling with an audit entry. **[DECIDE]**
- Where the tokens go (treasury, burn, split) is a business and legal decision. **[DECIDE]**
- Verification follows [web3-auth-and-payments.md](web3-auth-and-payments.md#8-subscription-payments): the `Transfer` log must come from the **expected E-FORCE contract address** (a fake token with the same name must fail); `to == receiver_address`; `value >= price`; `from` must be one of the caller's linked wallets; `(chain_id, tx_hash)` unique; required confirmations; re-verify at confirmation to handle reorgs.
- **[VERIFY]** chain, contract address, and decimals.

---

## 4. Premium timer

### How time is counted

- Premium is active while `profiles.premium_until > now()` (server time). The phone clock is never trusted.
- Every verified purchase (or admin grant) adds days: `premium_until = max(now, current premium_until) + days`.
- **Stacking:** buying again while Premium is active adds time after the current expiry. Nobody loses paid time.
- Time starts when the payment is **confirmed** (required block confirmations reached), not when the transaction is first submitted.

Example: Premium ends 1 Nov. The user buys 3 months on 20 Oct. New expiry is 1 Feb.

### What the user sees

| Where | Display |
| --- | --- |
| Premium status screen | End date + countdown, for example `47 days 6 hours left` |
| Under 24 hours | `hours and minutes left` |
| Profile / settings row | `Premium until 1 Feb 2027` |
| After extending | `Added 90 days. New end date: 1 Feb 2027` |
| Expired | `Premium ended on 1 Nov. Renew to restore your badge and limits.` |

The countdown is calculated in the app from the server's `premium_until` and refreshes on app resume and after any payment. It is display only. Access is always decided by the server. Dates and numbers use the user's locale. The countdown has a text label, no flashing, and respects reduce-motion.

### Reminders

| When | Reminder |
| --- | --- |
| 7 days before expiry | In-app banner + generic push |
| 1 day before expiry | In-app banner + generic push |
| On expiry | One in-app message on next open |

In `store` builds (section 2), reminders say "Your Premium ends soon" with no purchase link. Push text is generic and never contains message content. Reminders can be turned off.

### Checkout window and pending payments

- The price is locked for **30 minutes** after the user opens checkout.
- If the app is closed after paying, the pending payment is picked up on next launch, and a scheduled job re-checks it until it is confirmed or rejected.
- Chain congestion can delay confirmation. Show `Confirming (n/N)` and never grant access early.

### After expiry

- Optional grace period: **3 days** **[DECIDE]** where perks still work and a renew banner shows.
- After grace: badge hides and free limits apply. **Nothing is deleted** (section 7).

---

## 5. Access matrix: what each user gets

Legend: ✅ yes · ❌ no · number = limit. Same in every country and on every build.

### 5.1 Identity and profile

| Feature | Free | Premium |
| --- | --- | --- |
| Premium badge beside the name | ❌ | ✅ (can hide it in settings) |
| Set display name at sign-up | ✅ | ✅ |
| **Edit display name later** | ❌ locked | ✅ every 7 days |
| `@handle` set at sign-up | ✅ | ✅ |
| Change `@handle` later | ❌ | ✅ once per 30 days **[DECIDE]** |
| Bio length | 70 characters | 200 characters |
| Avatar upload size | 2 MB | 5 MB |

### 5.2 Messaging (core, always free)

| Feature | Free | Premium |
| --- | --- | --- |
| Direct chats | ✅ unlimited | ✅ unlimited |
| Realtime delivery, typing, read state | ✅ | ✅ |
| Push notifications | ✅ | ✅ |
| Block and report | ✅ | ✅ |
| Message text length | 2,000 characters | 4,000 characters |
| Delete account / export data | ✅ | ✅ |

### 5.3 Media and storage

| Feature | Free | Premium |
| --- | --- | --- |
| Image attachment size | 5 MB | 15 MB |
| File attachment size | 10 MB | 100 MB |
| Total attachment storage | 500 MB | 5 GB |

### 5.4 Chat organization

| Feature | Free | Premium |
| --- | --- | --- |
| Pinned chats | 3 | 10 |
| Chat folders / labels (later) | 2 | 10 |
| Scheduled messages (later) | ❌ | 20 pending |

### 5.5 Groups

| Feature | Free | Premium |
| --- | --- | --- |
| Join groups | up to 100 | up to 500 |
| Create (own) groups | up to 3 | up to 20 |
| Members per group you own | 50 | 500 |
| Active invite links per group | 3 | 20 |

### 5.6 Channels

| Feature | Free | Premium |
| --- | --- | --- |
| Join public channels | ✅ | ✅ |
| Join token-gated channels you qualify for | ✅ | ✅ |
| Create (own) channels | 1 | 10 |
| Create **private / token-gated** channels | ❌ | ✅ |
| Subscribers per channel you own | 500 | 5,000 |

### 5.7 Customization

| Feature | Free | Premium |
| --- | --- | --- |
| Dark and light theme | ✅ | ✅ |
| Extra accent colors | ❌ | ✅ |
| Alternate app icons | ❌ | ✅ |

### 5.8 Support and access

| Feature | Free | Premium |
| --- | --- | --- |
| Normal support | ✅ | ✅ |
| Priority support queue | ❌ | ✅ |
| Early access to new features (opt-in) | ❌ | ✅ |

---

## 6. What nobody gets (Premium does not change these)

- ❌ Access to other users' private messages, files, or data.
- ❌ Bypassing moderation, content rules, rate limits, or spam controls.
- ❌ Admin powers in groups or channels you do not own.
- ❌ Hiding from block, report, or ban actions.
- ❌ Reserved or impersonating names (`admin`, `support`, `official`, `EliteChat`, `E-FORCE`, look-alike characters) and the badge symbol inside a name.
- ❌ Free Premium by changing the device clock. Time comes only from the server.
- ❌ Premium without a verified payment (the only exception is an admin-granted complimentary period, audit-logged).
- ❌ Ads. EliteChat shows no ads to anyone.

Never locked behind Premium (safety and basic access): reading and sending messages, blocking, reporting, push notifications, deleting your account, exporting your data, and E2EE when it ships.

---

## 7. When Premium ends: what happens to each feature

| Item | After expiry |
| --- | --- |
| Badge | Hidden |
| Display name / `@handle` | Stay as they are. Editing locks again |
| Groups you own (above 3) | Keep working. No new ones |
| Members above 50 in a group | Existing members stay. No new members until under the cap |
| Channels you own (above 1) | Keep working. No new ones |
| Private / token-gated channels | Keep working for existing members. No new ones |
| Pinned chats (above 3) / folders (above 2) | Extras hidden, not removed. They return on renewal |
| Stored files above 500 MB | Kept and readable. No new uploads until under the quota |
| Scheduled messages | Already scheduled ones still send. No new ones |
| Larger upload limits | Lower limits apply to new uploads only |
| Priority support / early access | Ends |

Renewing restores everything immediately.

**Revoke:** if an admin revokes a grant (fraud or a manual token refund), the days from that grant are removed from `premium_until`. The user falls back to the free tier with the same no-delete rule above.

---

## 8. Checkout screens

### Web and direct APK

```
┌───────────────────────────────┐
│  Premium                      │
│  ⚡ Badge · Edit name · More  │
│  limits · Priority support    │
│                               │
│  ○ 1 month          500       │
│  ○ 2 months         950       │
│  ○ 3 months       1,350       │
│  ● 1 year         4,800  -20% │
│  ○ 2 years        8,400  -30% │
│        (all prices E-FORCE)   │
│                               │
│  ≈ $47.99 · Premium until     │
│  14 Oct 2027                  │
│  Network: <chain>             │
│  Pay to: 0x12…ab34 (copy)     │
│  Price locked for 29:41       │
│  [ Pay with wallet ]          │
│  Payments are final.          │
└───────────────────────────────┘
```

### Store build (status-only, options D and E)

```
┌───────────────────────────────┐
│  Premium                      │
│  Status: Active               │
│  Ends 14 Oct 2027 (47d 6h)    │
│                               │
│  Badge · Edit name · Higher   │
│  limits                       │
└───────────────────────────────┘
```

No buy button and no link in the store build.

- Both full screens show the **end date** the plan would produce (stacking included).
- Token states: `Waiting for wallet` → `Transaction submitted` → `Confirming (n/N)` → `Premium active`.
- Friendly error messages only. No raw wallet or RPC error strings.

---

## 9. Backend design

### 9.1 Plans and price quotes

```sql
-- Plans: USD list price and token price
alter table public.plans
  add column usd_list_price_cents integer check (usd_list_price_cents > 0),
  add column duration_days integer check (duration_days > 0);
-- price_amount (existing) holds the token price in base units.

-- Price lock for checkout (30 minutes)
create table public.payment_quotes (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  plan_id      uuid not null references public.plans (id),
  amount       numeric(78, 0) not null check (amount > 0),  -- base units
  expires_at   timestamptz not null,
  created_at   timestamptz not null default now()
);
create index on public.payment_quotes (user_id, created_at desc);
alter table public.payment_quotes enable row level security;
-- Policy intent: users read only their own quotes; quotes are created by an Edge Function.
create policy payment_quotes_read_own on public.payment_quotes
  for select to authenticated using (user_id = auth.uid());
```

`verify-payment` accepts a transaction only if its block time falls inside a valid quote window for the caller (small buffer allowed) and `value >= quote.amount`. This stops a token price swing from breaking a payment that the user started in good faith, and stops old cheap quotes from being reused later.

### 9.2 Ledger of grants

```sql
-- Every added period
create table public.premium_grants (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  source        text not null check (source in ('token', 'admin')),
  external_ref  text not null,   -- token: chain_id:tx_hash; admin: ticket id
  plan_id       uuid references public.plans (id),
  days          integer not null check (days > 0),
  status        text not null default 'active' check (status in ('active', 'revoked')),
  created_at    timestamptz not null default now(),
  revoked_at    timestamptz,
  unique (source, external_ref)   -- one payment can only be claimed once
);
create index on public.premium_grants (user_id, created_at desc);
alter table public.premium_grants enable row level security;
-- Policy intent: a user may read only their own grants; nobody writes from the client.
create policy premium_grants_read_own on public.premium_grants
  for select to authenticated using (user_id = auth.uid());
```

The existing `grant_premium_period(user, days)` function (service role only) runs in the **same transaction** that inserts the `premium_grants` row. Revoking marks the row `revoked` and sets `premium_until = greatest(now(), premium_until - days)`, also service-role only.

### 9.3 Edge Functions

| Function | Auth | Purpose |
| --- | --- | --- |
| `create-quote` | JWT | Returns the current token price for a plan, stores a 30-minute quote, rate limited |
| `verify-payment` | JWT | Existing flow plus quote check, writes `premium_grants` |
| `check-pending-payments` | Scheduled | Re-checks pending payments, handles reorgs, rejects vanished transactions |
| `admin-set-reference-price` | Admin only | Updates the E-FORCE reference price and recalculates plan token prices (audit-logged) |

### 9.4 Admin tooling

Matches [admin-panel.md](admin-panel.md) **[ALIGN]**. Includes: edit USD list prices and the E-FORCE reference price, preview computed token prices before publishing, see grants per user, grant complimentary days (promotions, partners), revoke a grant, and review payments that need manual handling (wrong wallet, underpayment).

---

## 10. Worldwide launch notes

| Topic | Note |
| --- | --- |
| **Crypto legality** | Some countries restrict or ban buying or using crypto. Get legal review. If needed, hide the payment option by region (best effort only, since location is easy to fake) |
| **Token as a financial product** | Selling Premium for a token can attract regulation, and the token itself may have its own rules. Legal review before mainnet launch |
| **Tax** | You are the seller on token sales. Get tax advice for your company's country and your main markets |
| **Wallet access** | Many users need a wallet and E-FORCE before they can buy. Add a clear "How to get E-FORCE" guide, and keep the free tier genuinely useful |
| **Network fees** | The buyer pays gas on the chain. Show a plain notice and choose a chain with low fees if possible |
| **Languages** | English and Bengali at launch; add more later. Plan for RTL languages |
| **Currency display** | Show the token amount first and an approximate USD value as a hint. Format numbers with the user's locale |
| **Support** | Worldwide users mean worldwide time zones. Plan async support and clear refund rules |
| **Store distribution** | See section 2. Re-check store policies before each launch, since they change |

---

## 11. Test cases

**Timer and plans**

- Each of the five plans adds exactly its `days` to `premium_until`.
- Buying while active stacks after the current expiry; buying while expired starts from now.
- Time does not start while a payment is unconfirmed.
- At `premium_until - 1s` the user is Premium; at `premium_until + 1s` they are not.
- Changing the phone clock changes nothing.
- Reminders fire at 7 days and 1 day, and not again after renewing.
- Countdown text is correct across the days → hours switch, in English and Bengali.

**Token payments (testnet)**

- A correct payment grants the plan's days once. Replaying the same `tx_hash` grants nothing.
- Wrong contract address (fake token with the same name), wrong receiver, underpayment, failed transaction, wrong chain, and a non-linked sender all grant nothing.
- A payment made after the quote expired is rejected; a payment inside the quote window succeeds even if the reference price changed afterwards.
- Two users submitting the same `tx_hash`: only the owner of the sending wallet succeeds, and only once.
- A reorg before confirmation grants nothing.
- Revoking a grant removes exactly its days.

**Store build**

- The `store` flavor contains no payment button, price text, or purchase link, and no payment code is reachable.
- A user who bought on the Web sees Premium active in the `store` build.

**General**

- Downgrade keeps all data and blocks only new creation beyond free limits.
- Client cannot write `premium_until`, `premium_grants`, `payment_quotes`, or `plans`.

---

## 12. Open decisions

1. Distribution plan: Web + direct APK first? Will you try a status-only Google Play or App Store listing, and who confirms with the stores? **[VERIFY]**
2. Final USD list prices and the E-FORCE reference price.
3. $E-FORCE chain, contract address, and decimals. **[VERIFY]**
4. Price source for the reference price and update schedule.
5. Promotions for lower-income markets (admin-granted periods instead of regional prices).
6. Grace period after expiry (0 or 3 days).
7. Can free users change their name once?
8. Premium handle change rules.
9. Final numbers for every limit in section 5 after cost estimates.
10. Treasury, burn, or split of received tokens, and legal review of selling Premium for a token.
11. Refund policy for token payments and who can approve manual refunds.
12. Fallback: should Google Play Billing be added later for a Play-only build if the store blocks status-only?
