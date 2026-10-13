# EliteChat: Real Data and Real-Time Policy

Version 0.1 (draft) · Last updated 2026-10-13

This policy applies to the **user app** and the **admin panel**. It says what "no demo data" means in practice, how every screen gets live data, and how the team enforces both. Backend assumptions come from [firebase-backend-plan.md](firebase-backend-plan.md) and [admin-panel.md](admin-panel.md).

## 1. The rules

1. **No demo data in any shipped build.** No hardcoded users, chats, messages, channels, plans, payments, statistics, avatars, or text that pretends to be real.
2. **Every screen reads real data from Firestore** (or from a Cloud Function that reads it). If there is nothing, the screen shows a proper empty state.
3. **Live screens are real-time.** Anything that changes while the user looks at it (messages, chat list, unread counts, subscription and payment status, notifications, membership, admin queues) updates through listeners, not manual refresh.
4. **Failures never fall back to fake data.** An error shows an error state with retry; a loading state shows skeletons with no invented numbers.
5. **Test and mock data live only in `test/`, `integration_test/`, and the local emulator.** They are never compiled into `lib/` and never written to staging or production.

## 2. What counts as demo data

| Counts as demo data (forbidden) | Does not count (allowed) |
| --- | --- |
| Hardcoded chat lists, fake contacts, "John Doe" users | Real empty states ("No chats yet. Find someone by handle.") |
| Lorem ipsum, placeholder bios, stock avatars shown as if users | Neutral default avatar (initials or generic icon) for users without a photo |
| Fake dashboard numbers, random chart data, "1,234 users" | Real counts, including 0 |
| Mock repositories wired into the app | Fake repositories used by unit tests under `test/` |
| Seed scripts that create users or messages in staging/prod | Real configuration records: plans, token allowlist, `appConfig` |
| Fake "online now" or "typing…" indicators | Real indicators driven by actual events |
| Screenshots or marketing mockups presented as live product | Store screenshots taken from the real app with real (test) accounts |

**Configuration is not demo data.** Plans, supported tokens, feature flags, and app limits are real operational settings. In dev they point to BSC testnet (chain 97); in production, to mainnet (chain 56).

## 3. Environments and data

| Environment | Backend | Data |
| --- | --- | --- |
| Local | Firebase Emulator Suite | Created by using the app with test wallets. Optional emulator seed is limited to config (plans, `appConfig`), not fake people or messages |
| Dev | Dev Firebase project | Real flows with internal test accounts on testnet |
| Staging | Separate project | Pre-release testing with real flows; same rules as production; testnet payments |
| Production | Prod project | Real users only. Starts empty except configuration |

- Internal and review accounts are real accounts marked `isTestAccount: true` so they can be excluded from metrics. They contain no fabricated content.
- If a pilot ever leaves test data in production, remove it with a reviewed, audited cleanup script. Do not leave it in place.
- **App store review:** reviewers usually need a way to sign in. Provide a real reviewer account (and testnet wallet instructions where needed) rather than a "demo mode" in the app. **[VERIFY current store requirements]**

## 4. Real-time by feature

| Feature | Source | Mechanism | Notes |
| --- | --- | --- | --- |
| Chat list (order, last message, unread) | `conversations` + member docs | Firestore snapshot listener on the user's conversations query | Needs the composite index (`memberIds array-contains`, `lastMessageAt desc`) |
| Messages in an open chat | `conversations/{cid}/messages` | Snapshot listener, newest 30, older pages by cursor | Listener lives only while the screen is open |
| Sent / delivered state | Firestore metadata | `hasPendingWrites` → `pending`; server ack → `sent` | Real write state, not simulated |
| Unread counts | Member doc `lastReadAt` vs. conversation `lastMessageAt` | Derived from the same listeners | Per-member watermark, no per-message reads |
| Typing and presence | Ephemeral state | Decision needed (section 6) | Optional for MVP |
| Group and channel membership, roles | `members` subcollections | Snapshot listener | Access loss detected via permission-denied and handled |
| Channel posts | `channels/{id}/posts` | Snapshot listener | |
| Notifications list | `notifications` for the user | Snapshot listener | FCM is only the wake-up signal |
| Subscription state | `subscriptions/{uid}` | Snapshot listener | UI updates the moment the server confirms a payment |
| Payment progress | `payments/{chainId_txHash}` (readable by owner) | Snapshot listener | `pending → confirmed` shown live with confirmation count |
| Profile changes | `users/{uid}` | Snapshot listener | |
| App config (maintenance, min version) | `appConfig/current` | Snapshot listener | Force-update and maintenance banners appear live |

### Admin panel

| Screen | Source | Mechanism |
| --- | --- | --- |
| Dashboard live tiles (new users, pending payments, open reports) | `adminLive/*` summary docs | Snapshot listener |
| Report/case queue (list rows) | `adminLive/cases/*` sanitized summaries | Snapshot listener |
| Case detail, user detail, evidence | Cloud Functions (`admin_getCase`, `admin_getUser`) | On open, plus a listener on the case summary for status changes |
| Payments list | `adminLive/payments/*` summaries, detail via function | Snapshot listener |
| Audit log | `admin_listAudit` | On demand with filters; optional "live tail" for superadmins |
| Admin approvals | `adminLive/approvals/*` | Snapshot listener |

**Why `adminLive`:** [admin-panel.md](admin-panel.md) routes sensitive reads through audited callables. Live lists need listeners, so Cloud Functions maintain **sanitized summary documents** (ID, type, status, age, severity, no personal data or message content) in `adminLive`. Admins listen to those, and open the full record through a callable that logs the access.

```
function isActiveAdmin() {
  return request.auth != null
    && request.auth.token.adminRole != null
    && get(/databases/$(database)/documents/adminUsers/$(request.auth.uid)).data.active == true;
}

match /adminLive/{path=**} {
  allow read: if isActiveAdmin();
  allow write: if false;      // maintained by Cloud Functions only
}
```

The `get()` makes a disabled admin lose live access immediately, even before their token expires, at the cost of one extra billed read per evaluation.

## 5. Implementation pattern (Flutter + GetX)

Repositories return streams; controllers subscribe, map to `Rx` state, and cancel in `onClose`. Views never talk to Firestore.

```dart
// data/repositories/firestore_chat_repository.dart
Stream<List<MessageModel>> watchMessages(String conversationId, {int limit = 30}) {
  return _db
      .collection('conversations').doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots(includeMetadataChanges: true)
      .map((snap) => snap.docs
          .map((d) => MessageModel.fromDoc(d, isPending: d.metadata.hasPendingWrites))
          .toList());
}
```

```dart
// modules/chats/controllers/conversation_controller.dart
class ConversationController extends GetxController {
  ConversationController(this._chat, this.conversationId);
  final ChatRepository _chat;
  final String conversationId;

  final messages = <MessageModel>[].obs;
  final isLoading = true.obs;
  final errorKey = RxnString();
  final isOffline = false.obs;
  StreamSubscription<List<MessageModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _chat.watchMessages(conversationId).listen(
      (list) {
        messages.assignAll(list);
        isLoading.value = false;
        errorKey.value = null;
      },
      onError: (Object e) {
        isLoading.value = false;
        errorKey.value = AppException.from(e).messageKey;  // permission-denied, unavailable, ...
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
```

Notes:

- A message just written from this device has a pending server timestamp until the server acknowledges it. Handle the missing `createdAt` for ordering and display. **[VERIFY the current cloud_firestore API for estimated server timestamps]**
- Show an offline or "data may be out of date" banner when snapshot metadata says `isFromCache`.
- **Offline persistence:** it is on by default on mobile; on Web it must be enabled explicitly and has multi-tab constraints. **[VERIFY]** Queued writes appear as real `pending` messages and deliver when the connection returns.
- A `permission-denied` error on a listener means access was lost (removed from a group, banned). Handle it gracefully by leaving the screen with an explanation.

## 6. Presence and typing (decision)

Typing and online indicators are write-heavy and short-lived.

| Option | Pros | Cons |
| --- | --- | --- |
| Firebase Realtime Database with `onDisconnect` | Built for presence; cleans up on disconnect | Second database to secure and pay for |
| Firestore ephemeral docs with heartbeat and TTL | One database | Heartbeat write cost, less accurate disconnect detection |
| Skip in MVP | Simplest, cheapest | Fewer "alive" cues |

Recommendation: ship the MVP without presence, add typing indicators first, and offer a per-user privacy setting for "show online status". Whatever is chosen must show real signals only. Never display a fake "online".

## 7. Dashboard and metrics honesty

"Real data" and "real-time" can conflict for large counters:

- Low-rate numbers (new users, confirmed payments, open reports, pending payments) are updated by trigger functions into `adminLive` counters and appear live.
- High-rate numbers (messages per day, active users) are **not** incremented live on one document, because Firestore limits sustained writes to a single document. Use sharded counters, a scheduled aggregation job, or the Analytics/BigQuery export, and show **"Updated at HH:MM"** next to the number. **[VERIFY analytics setup and cost]**
- Never display an estimate as an exact figure. Never show a placeholder number while loading; show a skeleton.
- Exclude `isTestAccount` users from business metrics, and say so on the dashboard.

## 8. Cost and performance guardrails

- Attach listeners only while a screen is visible; cancel on dispose and when the app goes to the background if the data is not needed.
- Always `limit()` queries; paginate older data by cursor. Never listen to a whole collection.
- Use one listener per concern (chat list, open chat, subscription). Do not create a listener per list row.
- Prefer maintained summary fields (`lastMessageAt`, `lastMessagePreview`) over reading message collections for lists.
- Set Firebase budget alerts and review read/write usage weekly during beta.
- Measure end-to-end message delivery latency (p50 and p95) in staging with two real devices; treat any target as a goal to measure, not a promise.

## 9. Privacy constraints on live data

- Admin live views carry **no message content and no personal identifiers** beyond what a case needs; full records open through audited callables.
- Presence and "last seen" are opt-in or at least user-controllable.
- Push payloads stay generic; the app fetches the real content through its normal listeners after opening.

## 10. Per-screen contract

Every screen spec (user app and admin) must fill in this table before implementation:

| Field | Example |
| --- | --- |
| Data source | `conversations` where `memberIds` contains `uid` |
| Query | `orderBy lastMessageAt desc`, `limit 30` |
| Live mechanism | Snapshot listener; cancelled in `onClose` |
| Loading state | Skeleton rows |
| Empty state | "No chats yet" with a "Find people" action |
| Error state | Message plus Retry; permission-denied → explain and navigate back |
| Offline state | Banner; queued writes shown as pending |
| Hardcoded content | None (only localized UI strings) |

A pull request that adds a screen without this contract does not pass review.

## 11. Enforcement

**Code structure**

- Fake repositories and fixtures live only under `test/`. `lib/` must not import from `test/`.
- The dependency-injection `InitialBinding` registers only Firestore-backed repositories; there is no "mock mode" flag.

**CI checks (fail the build)**

```bash
# Banned patterns in shipped code (adjust the list as needed)
if grep -rniE "lorem ipsum|dummy|mock[A-Z_ ]|fake[A-Z_ ]|faker|sample_data|demo_data|john doe" lib/ admin_panel/lib/; then
  echo "Demo/mock data patterns found in shipped code"; exit 1
fi
```

- A unit test that scans `lib/` for imports of `package:mocktail`, `package:faker`, or the `test/` fixtures directory.
- Seed scripts must refuse to run unless the target is the emulator or a project whose ID is on a dev allowlist.
- Release builds fail if `APP_ENV` is `prod` and the emulator flag is on.

```dart
// main.dart
if (AppConfig.useEmulator) {
  if (!kDebugMode || AppConfig.isProd) {
    throw StateError('Emulator must never be enabled outside local debug builds.');
  }
  FirebaseFirestore.instance.useFirestoreEmulator(AppConfig.emulatorHost, 8080);
}
```

**Review and release**

- Reviewers check the per-screen contract and look for hardcoded content in widgets.
- Before every release, a QA pass on a staging build confirms: no placeholder text, empty states render with a fresh account, and every live feature updates without refresh.

## 12. Acceptance tests (real-time)

Run on two real devices (or device plus browser) signed in with different test accounts:

1. A message sent on device A appears on device B without any refresh, and the chat list on B reorders and updates its unread count.
2. Turning off the network on A and sending shows a `pending` message; turning it back on delivers it and the state changes to `sent`.
3. B marks the chat read; A sees the read state update (if read receipts are enabled).
4. B is removed from a group by an admin; B's open chat shows the access-lost state live.
5. A BEP-20 testnet payment moves `pending → confirmed` on screen and the premium state unlocks without restart.
6. Setting `maintenanceMode` in the admin panel shows the maintenance banner in the app within seconds.
7. A new report from the app appears in the admin queue without a page refresh; opening it logs an audit entry; a moderator action updates the case status for other admins live.
8. A fresh account in production-like staging shows empty states everywhere and zero invented numbers.
9. Disabling an admin account removes their live access to `adminLive` immediately.

## 13. Definition of done (data)

- [ ] No hardcoded or mock data in `lib/` or `admin_panel/lib/`; CI pattern check passes
- [ ] Every screen has a completed per-screen contract
- [ ] Live features verified by the acceptance tests in section 12
- [ ] Listeners are bounded (`limit`), cancelled on close, and covered by cost review
- [ ] Empty, loading, error, and offline states implemented and reviewed
- [ ] Production project contains no test data except flagged review accounts and real configuration
- [ ] Dashboard figures show source and freshness where they are not live
