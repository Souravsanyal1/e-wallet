# EliteChat Backend Plan: Firebase only

Version 0.1 (draft) · Last updated 2026-10-13

Stack: Flutter + GetX, Firebase (Auth, Firestore, Cloud Functions, Hosting, FCM, App Check), Cloudinary for images, BEP-20 payments on BNB Smart Chain. There is no Vercel or Supabase in this plan.

This file replaces the Supabase-specific parts of [architecture.md](architecture.md), [database.md](database.md), and [web3-auth-and-payments.md](web3-auth-and-payments.md). Wherever those documents say "RLS", read "Firestore Security Rules", and wherever they say "Edge Functions", read "Cloud Functions". The admin panel is described in [admin-panel.md](admin-panel.md).

## 0. Security notice

A Cloudinary API secret was shared in plain text during planning. Treat it as leaked:

1. In the Cloudinary dashboard, go to Settings → API Keys, generate a new key pair, and delete the old one.
2. Never put the secret in the Flutter app, the repository, chat messages, or screenshots.
3. Store it only in Secret Manager (`firebase functions:secrets:set CLOUDINARY_API_SECRET`).

The Firebase project ID and the Cloudinary cloud name are not secrets. Firebase client config values in `firebase_options.dart` are public identifiers; protect them with Security Rules, App Check, and API-key restrictions.

## 1. Stack

| Concern | Choice | Role |
| --- | --- | --- |
| App | Flutter + GetX | Android, iOS, Web |
| Auth | Firebase Auth with custom tokens | Wallet signature verified server-side, then a Firebase token is issued |
| Database + realtime | Cloud Firestore | Chats, groups, channels, payments |
| Authorization | Firestore Security Rules + App Check | Per-request access control |
| Images | Cloudinary (signed uploads) | Avatars and chat images |
| Server logic | Cloud Functions 2nd gen (TypeScript, Admin SDK) | Auth, upload signing, payments, push, scheduled jobs |
| Web hosting | Firebase Hosting | Flutter Web build |
| Push | FCM | Sent by a Firestore trigger |
| Chain | BNB Smart Chain, BEP-20 | Chain ID 56 mainnet, 97 testnet |

Setup:

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=<dev-project-id>
```

Use separate Firebase projects for dev and prod (for example `elitechat-dev` and `elitechat-prod`), with aliases in `.firebaserc`. Confirm that the project `e-wallet-1cb99` is meant for EliteChat before reusing it.

## 2. Server logic on Firebase

| Function | Type | Purpose |
| --- | --- | --- |
| `authNonce` | Callable | Create a single-use nonce and the sign-in message |
| `authVerify` | Callable | Verify the signature and return a custom token |
| `linkWallet` | Callable | Bind another wallet to the signed-in user |
| `uploadSign` | Callable | Sign a Cloudinary upload after checking membership |
| `createConversation` | Callable | Create direct chats/groups atomically, checking blocks |
| `verifyPayment` | Callable | Verify a BEP-20 payment and grant a subscription |
| `deleteAccount` | Callable | Remove or anonymize the user's data |
| `onMessageCreated` | Firestore trigger | Send FCM push, set `lastMessageAt` server-side |
| `recheckPayments`, `expireSubscriptions` | Scheduled | Confirm pending payments, expire subscriptions |

Why callables:

- Firebase verifies the caller's ID token automatically, so `request.auth.uid` is trustworthy.
- `enforceAppCheck: true` blocks calls from outside your real app.
- The Flutter side is `FirebaseFunctions.instance.httpsCallable('uploadSign')`, with no manual HTTP handling.
- `authNonce` and `authVerify` run before sign-in, so they accept unauthenticated calls. Protect them with App Check, rate limiting, and `maxInstances`.

```ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const cloudinarySecret = defineSecret("CLOUDINARY_API_SECRET");

export const uploadSign = onCall(
  {
    region: "<your-region>",
    enforceAppCheck: true,
    secrets: [cloudinarySecret],
    maxInstances: 10,
  },
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    // 1. validate conversationId + file type/size from req.data
    // 2. check req.auth.uid is a member of the conversation (Firestore Admin SDK)
    // 3. return Cloudinary { timestamp, folder, signature, apiKey } with limits
  }
);
```

## 3. Project layout

```
elite_chat/
├── lib/                       # Flutter app
├── functions/                 # Cloud Functions (TypeScript)
│   └── src/
│       ├── auth/              # authNonce, authVerify, linkWallet
│       ├── uploads/           # uploadSign
│       ├── conversations/     # createConversation, member management
│       ├── payments/          # verifyPayment, recheckPayments, expireSubscriptions
│       ├── notifications/     # onMessageCreated
│       ├── admin/             # admin_* callables (see admin-panel.md)
│       └── account/           # deleteAccount
├── admin_panel/               # Separate admin web app
├── firestore.rules
├── firestore.indexes.json
├── firebase.json
└── .firebaserc                # aliases: dev, prod
```

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{ "source": "**", "destination": "/index.html" }],
    "headers": [{
      "source": "**",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "X-Frame-Options", "value": "DENY" }
      ]
    }]
  },
  "firestore": { "rules": "firestore.rules", "indexes": "firestore.indexes.json" },
  "functions": [{ "source": "functions", "codebase": "default" }],
  "emulators": {
    "auth": { "port": 9099 }, "firestore": { "port": 8080 },
    "functions": { "port": 5001 }, "hosting": { "port": 5000 },
    "ui": { "enabled": true }
  }
}
```

Add a Content-Security-Policy header after testing, since Flutter Web loads some assets from Google domains by default. Deploy with `flutter build web` then `firebase deploy --only hosting` (or GitHub Actions with a preview channel for each PR). Run everything locally with `firebase emulators:start`.

## 4. Setup steps

1. **Blaze plan is required.** Cloud Functions deployment, outbound calls to Cloudinary and the BSC RPC, and scheduled jobs all need it. Set budget alerts immediately; Firestore reads and function invocations are billed by usage.
2. **Choose the region now.** The Firestore location cannot be changed later. Pick the one closest to most users and put Functions in the same region.
3. **Separate dev and prod projects**, then `flutterfire configure --project=<project-id>` for each.
4. **Secrets:** `firebase functions:secrets:set CLOUDINARY_API_SECRET` (the rotated secret), and the same for the BSC RPC key.
5. **Custom tokens:** `authVerify` uses `createCustomToken`. On deployed functions this commonly fails with a `signBlob` permission error until the runtime service account has the **Service Account Token Creator** role.
6. **App Check:** register Play Integrity (Android), App Attest (iOS), and reCAPTCHA (Web), then enforce it on Firestore and the callables.
7. **API key restrictions:** restrict Firebase API keys by platform and API in Google Cloud.

## 5. Wallet sign-in

1. The app connects the wallet and calls `authNonce`. The server stores a single-use nonce (5-minute expiry) in Firestore and returns an EIP-4361 (SIWE) message built on the server.
2. The wallet signs the message.
3. The app calls `authVerify`. The server checks the domain, URI, chain ID (56), issued/expiry times, and the signature, and consumes the nonce in a Firestore transaction (fails if already used).
4. The server finds or creates the user (`users/{uid}`, `wallets/{chain_address}`) and calls `createCustomToken(uid)`.
5. The app calls `signInWithCustomToken`.

Logout everywhere uses `revokeRefreshTokens(uid)`. Smart-contract wallets (EIP-1271) need a launch decision: support them or reject them with a clear message. Use a maintained library for SIWE parsing and signature verification. The security requirements in [web3-auth-and-payments.md](web3-auth-and-payments.md) (sections 3, 4, 6, 7, and the sign-in test cases) still apply.

## 6. Firestore data model

```
users/{uid}                          public profile only (handle, displayName, avatarUrl, bio, status)
wallets/{chain_address}              server-only, maps address → uid
authNonces/{nonce}                   server-only, TTL on expiresAt
conversations/{cid}                  type, memberIds[], title, lastMessageAt, createdBy
  members/{uid}                      role, lastReadAt, mutedUntil
  messages/{mid}                     senderId, body, kind, createdAt, deletedAt, imageRef
channels/{chid}                      handle, title, isPublic, requiredPlanId
  members/{uid}
  posts/{pid}
plans/{planId}                       E-FORCE config: chainId, token, tokenDecimals, receiver, price (base units, string), durationDays, isActive
paymentQuotes/{quoteId}              userId, planId, locked amount/config, 30-minute expiry; server-only writes
payments/{chainId_txHash}            doc ID is the uniqueness guard; server-only
premiumGrants/{chainId_txHash}       one token grant per transaction; server-only
subscriptions/{uid}                  current plan/payment status and expiry; server-only writes
users/{uid}.premiumUntil             authoritative Premium expiry; only Cloud Functions may write
deviceTokens/{uid}/tokens/{token}
blocks/{uid}/blocked/{otherUid}
reports/{id}
```

Admin-related collections (`adminUsers`, `adminAuditLogs`, `adminApprovals`, `moderationCases`, `bannedUsers`, `appConfig`, `stats`) are described in [admin-panel.md](admin-panel.md).

Design notes:

- Direct chats use a deterministic ID (sorted `uidA_uidB`) so duplicates cannot exist. Conversations are created through `createConversation`, which checks blocks.
- The chat list query needs a composite index: `memberIds array-contains uid` ordered by `lastMessageAt desc`.
- Read state lives in each member's own doc. Writing a shared map on the conversation doc would hit Firestore's roughly one-write-per-second-per-document limit.
- Large groups and channels should not rely on a `memberIds` array (1 MB document limit); use the members subcollection.
- Token amounts are strings in base units, because Firestore numbers cannot hold a `uint256`.
- Use soft deletes (`deletedAt`) for messages and posts.
- Page messages with cursor queries on `createdAt` (plus document ID as tiebreaker).

## 7. Security Rules essentials

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isMember(cid) {
      return request.auth != null &&
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(cid)).data.memberIds;
    }

    match /conversations/{cid} {
      allow read: if isMember(cid);
      allow write: if false;                 // created/updated via Cloud Functions

      match /messages/{mid} {
        allow read: if isMember(cid);
        allow create: if isMember(cid)
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.createdAt == request.time
          && request.resource.data.body.size() <= 4000;
        allow update, delete: if false;      // soft-delete via Cloud Function
      }
    }

    match /users/{uid} {
      allow read: if request.auth != null;
      allow update: if request.auth.uid == uid
        && request.resource.data.diff(resource.data).affectedKeys()
             .hasOnly(['displayName', 'avatarUrl', 'bio']);
      allow create, delete: if false;
    }

    match /subscriptions/{uid} {
      allow read: if request.auth.uid == uid;
      allow write: if false;
    }

    // Default deny
    match /{document=**} { allow read, write: if false; }
  }
}
```

Notes:

- Rules guard each request but are not filters: queries must match the rules, there are no joins, and each `get()` in a rule is billed as a read.
- Server-only collections need no rules; the Admin SDK bypasses them, and the default-deny rule blocks clients.
- Test rules with the Firebase Emulator and `@firebase/rules-unit-testing`: allowed and denied cases for member, non-member, wrong sender, forged `createdAt`, and attempts to write server-only collections.
- Before launch, check whether banned users should be blocked via a `bannedUsers` lookup on message creation (see admin-panel.md section 10).

## 8. Images with Cloudinary

1. The app calls `uploadSign` with the conversation ID and file type.
2. The function checks the Firebase ID token and membership, then returns a signed upload (timestamp, folder, signature, API key) with size and format limits.
3. The app uploads straight to Cloudinary. The API secret never leaves Cloud Functions.
4. The app writes the message with the returned `public_id`, not a permanent public URL.

- Avatars can be public.
- Chat images should use Cloudinary's `authenticated` delivery type so access goes through signed URLs generated for members only.
- Do not use unsigned upload presets for chat; anyone could upload to your account.
- Enforce a size and format allowlist at upload time, and review how location metadata is handled in Cloudinary settings.
- Optional scheduled job: clean up uploads that never became part of a message.

## 9. E-FORCE Premium payments on BNB Smart Chain

- Chain ID 56 in production, 97 on testnet. Use a paid RPC provider (public endpoints are rate-limited) and keep the key in Secret Manager.
- Plans come from the `plans` collection; the client sends only `planId` and `txHash`.
- Verification (server side, fail closed):
  1. The plan exists and is active; chain, token, receiver, and price come from Firestore, never from the request.
  2. `payments/{chainId_txHash}` does not already exist (create it inside a Firestore transaction; the document ID is the uniqueness guard).
  3. The receipt exists and succeeded.
  4. A `Transfer(address,address,uint256)` log (topic0 `0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef`) was emitted by the **expected token contract**, to the receiver, with value at or above the price (native BNB: check `to` and `value`).
  5. The sender is one of the caller's linked wallets.
  6. Enough confirmations; otherwise store `pending` and let `recheckPayments` finish it. Re-verify the receipt before confirming to handle reorgs.
  7. Write `payments` and `subscriptions/{uid}` in one transaction; extend from `max(now, current expiresAt)`.
- Accept only the configured E-FORCE contract for each active plan. The E-FORCE chain, contract address, and decimals are still launch decisions and must be verified before enabling a plan.
- Read decimals from each plan's `tokenDecimals`; never assume E-FORCE has 18 decimals until verified.
- Premium uses the five plan keys and proposed token amounts in [premium-access-and-plans.md](premium-access-and-plans.md). Prices are stored as integer base-unit strings. The server issues a 30-minute quote and checks the transaction's block time against that quote.
- On confirmation, atomically write the payment, one `premiumGrants` ledger row, the subscription status, and `users/{uid}.premiumUntil = max(now, current premiumUntil) + durationDays`.
- Users need a little BNB for gas; say so in the payment UI.
- BSC finality is quick, but confirm current finality guidance and choose your own confirmation threshold.
- Avoid recurring token approvals for the MVP; sell one-off periods.
- Test on testnet with recorded transactions: wrong token, wrong receiver, underpayment, failed transaction, replayed hash, another user's hash, reorg.

## 10. Security additions and differences

- **Nonce cleanup:** use a Firestore TTL policy on `authNonces.expiresAt`, and still check expiry in code because TTL deletion is not instant.
- **Rate limiting:** Firebase has no built-in per-IP limiter. Combine `maxInstances`, App Check, and transactional Firestore counters (per address and per IP from `request.rawRequest.ip`) on `authNonce` and `authVerify`.
- **Cold starts:** the first sign-in after idle can be slow; optionally set `minInstances: 1` on auth functions.
- **Budgets:** set Firebase/Google Cloud budget alerts; Firestore bills per read, write, and listener update.
- **Push payloads** stay generic ("New message"); never include message text.
- **Single-vendor trade-off:** simpler operations and one IAM model, but more dependence on Google Cloud. Keep business logic in plain TypeScript modules so it can move later.
- All other requirements in [security.md](security.md) carry over (threat model, abuse controls, incident response, pre-launch checklist).

## 11. Phases

- **Phase 0 (spikes):** wallet connect and `personal_sign` on Android, iOS, and Web; `authVerify` issuing a custom token end to end (including the Token Creator role); a signed Cloudinary upload through `uploadSign`; a BSC testnet payment verified from a recorded transaction.
- **Phase 1 (foundation):** dev and prod projects, App Check, emulator suite, rules tests in CI, Hosting deploy pipeline, GetX skeleton.
- **Phase 2 (auth):** `authNonce`, `authVerify`, profile creation, session handling, admin foundation (roles, MFA, audit log).
- **Phase 3 (direct chat):** `createConversation`, messages with cursor pagination, realtime listeners, Cloudinary images, push, block and report, moderation basics.
- **Phase 4 (groups and channels).**
- **Phase 5 (privacy hardening):** E2EE with an audited library, penetration test. Firestore can store ciphertext.
- **Phase 6 (payments):** BEP-20 verification on testnet, then a small mainnet dry run; admin payment tools.

## 12. Decisions left

1. Confirm the Blaze plan and the region.
2. Which BEP-20 tokens to accept, and whether native BNB counts.
3. Smart-contract wallet support at launch.
4. Whether `e-wallet-1cb99` is the right project, or whether to create dedicated dev and prod projects.
5. Whether to enable Identity Platform for admin MFA (see admin-panel.md).
