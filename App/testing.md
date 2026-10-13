# EliteChat Testing

Version 0.1 (draft) · Last updated 2026-10-13

## 1. Strategy

Most risk sits in authorization (RLS) and wallet/payment verification, so those get the strictest testing. UI tests matter, but a pretty screen over a leaky policy is a failure.

| Layer | Tooling | Scope | Priority |
| --- | --- | --- | --- |
| Database / RLS | pgTAP via `supabase test db` | Every policy, allowed and denied, for each role | Critical |
| Edge Functions | `deno test` | Nonce, signature, payment verification, rate limits | Critical |
| Controllers (unit) | `flutter_test` + `mocktail` | Logic with fake repositories | High |
| Repositories | Integration tests against local Supabase | Query shape, error mapping | High |
| Widgets | `flutter_test` with `GetMaterialApp` | Rendering of states, interactions | Medium |
| End to end | `integration_test` | Sign-in (mock wallet), send a message | Medium |
| Security | Manual + pen test | Abuse cases, auth bypass | Before launch |

Target: meaningful coverage of controllers and repositories (aim for 80%+ on `controllers/` and `repositories/`), 100% of policies and RPC functions covered by at least one allow and one deny test. Coverage numbers are a guide, not a goal in themselves.

## 2. Controller unit tests

Controllers take dependencies through the constructor, so tests need no GetX bindings.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository repo;

  setUp(() {
    Get.testMode = true;
    repo = MockChatRepository();
    when(() => repo.watchMessages('c1')).thenAnswer((_) => const Stream.empty());
  });

  tearDown(Get.reset);

  test('loads initial messages', () async {
    when(() => repo.fetchMessages(conversationId: 'c1')).thenAnswer(
      (_) async => Ok<List<MessageModel>>([fakeMessage(id: 'm1')]),
    );

    final controller = ConversationController(repo, 'c1');
    await controller.loadInitial();

    expect(controller.messages.length, 1);
    expect(controller.isLoading.value, isFalse);
    expect(controller.errorKey.value, isNull);
  });

  test('exposes an error key when loading fails', () async {
    when(() => repo.fetchMessages(conversationId: 'c1')).thenAnswer(
      (_) async => Err<List<MessageModel>>(AppException.network()),
    );

    final controller = ConversationController(repo, 'c1');
    await controller.loadInitial();

    expect(controller.messages, isEmpty);
    expect(controller.errorKey.value, isNotNull);
  });
}
```

What to test in controllers: loading/empty/error transitions, dedupe of incoming messages, optimistic send then confirm, optimistic send then failure and retry, subscription cancelled in `onClose`, validation rules.

## 3. Widget tests

```dart
testWidgets('shows empty state when there are no chats', (tester) async {
  Get.put<ChatListController>(FakeChatListController(chats: []));
  await tester.pumpWidget(const GetMaterialApp(home: ChatListView()));
  await tester.pump();
  expect(find.byType(EmptyState), findsOneWidget);
});
```

Cover each screen's loading, empty, error, and populated states, plus text scale 200%, dark and light themes, and an English and a Bengali locale. Use golden tests sparingly (for the message bubble and chat list row) to avoid brittleness.

## 4. Database and RLS tests (pgTAP)

Place tests in `supabase/tests/`. Pattern: seed as a privileged role, then switch to `authenticated` with a JWT subject and assert.

```sql
begin;
select plan(4);

-- Seed (as postgres). Inserting into auth.users may need extra NOT NULL columns
-- depending on the Supabase version; adjust or use a shared test helper.
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000000a'),
  ('00000000-0000-0000-0000-00000000000b'),
  ('00000000-0000-0000-0000-00000000000c');
insert into public.profiles (id, handle) values
  ('00000000-0000-0000-0000-00000000000a', 'alice'),
  ('00000000-0000-0000-0000-00000000000b', 'bob'),
  ('00000000-0000-0000-0000-00000000000c', 'carol');

insert into public.conversations (id, type, direct_key)
values ('11111111-1111-1111-1111-111111111111', 'direct', 'a:b');
insert into public.conversation_members (conversation_id, user_id) values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000000a'),
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000000b');
insert into public.messages (conversation_id, sender_id, body) values
  ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-00000000000a', 'hello');

-- Member can read
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
select isnt_empty($$select 1 from public.messages$$, 'member can read messages');

-- Non-member cannot read
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000c","role":"authenticated"}', true);
select is_empty($$select 1 from public.messages$$, 'non-member sees no messages');

-- Non-member cannot insert
select throws_ok(
  $$insert into public.messages (conversation_id, sender_id, body)
    values ('11111111-1111-1111-1111-111111111111',
            '00000000-0000-0000-0000-00000000000c', 'intrude')$$,
  '42501', null, 'non-member cannot send');

-- Cannot spoof sender
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-00000000000b","role":"authenticated"}', true);
select throws_ok(
  $$insert into public.messages (conversation_id, sender_id, body)
    values ('11111111-1111-1111-1111-111111111111',
            '00000000-0000-0000-0000-00000000000a', 'spoof')$$,
  '42501', null, 'member cannot send as another user');

select * from finish();
rollback;
```

Run with `supabase test db`. Required test matrix for each table: `anon`, authenticated non-member, member, admin, owner. Also test:

- Members cannot update `role` or `joined_at` (column grants).
- `wallets`, `payments`, `subscriptions` cannot be written by clients.
- `auth_nonces` is inaccessible to clients.
- `create_direct_conversation` is idempotent, rejects self and blocked users.
- Storage policies: members can read/upload attachments; non-members cannot.
- A CI query that lists every `public` table without RLS enabled must return zero rows:

```sql
select c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;
```

## 5. Edge Function tests

Use `deno test` with a local Supabase and a mock RPC server. Priority cases are listed in [web3-auth-and-payments.md](web3-auth-and-payments.md#10-test-cases). Add:

- Property-style tests feeding malformed messages and signatures to the parser.
- Concurrency test: parallel `auth-verify` calls with one nonce produce exactly one success.
- Rate limit tests.
- Payment verification against recorded receipts (fixtures) including wrong token, wrong receiver, failed status, and underpayment.

## 6. Integration and end-to-end tests

- **Repository integration tests:** run against `supabase start` with seed data; assert query results and error mapping.
- **End to end:** use a mock `WalletService` that signs with a test key so tests run without a real wallet. Flow: sign in → create DM → send message → second client receives it.
- **Realtime:** test reconnect backfill by dropping the connection and sending messages during the gap.
- Keep a small manual device matrix: low-end Android, recent iPhone, Chrome, Safari, Firefox.

## 7. Non-functional tests

| Area | What to check |
| --- | --- |
| Performance | Chat list and conversation scrolling at 10k messages; frame times in profile mode |
| Load | Concurrent realtime connections and message throughput on staging |
| Accessibility | TalkBack/VoiceOver walkthrough of auth, chat list, conversation; text scale 200% |
| Localization | Bengali rendering, plural/number formats, text expansion |
| Network | Offline, flaky, and slow-network behavior; retry after reconnect |
| Web | CSP violations, bundle size, deep link refresh behavior |

## 8. CI pipeline

```yaml
# .github/workflows/ci.yml (outline)
name: CI
on: [pull_request]
jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
      - run: flutter test --coverage
  backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: supabase db reset
      - run: supabase test db
      - run: deno test --allow-env --allow-net supabase/functions
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
```

Pin action versions and verify current action names/versions when you set this up. Add a nightly job for dependency outdated/vulnerability reports and a release job that builds Android, iOS, and Web with `--obfuscate --split-debug-info` for mobile builds.

## 9. Test data

- `supabase/seed.sql` creates a few users, conversations, messages, and plans for local development only; it never runs in production.
- Use deterministic UUIDs in tests for readable assertions.
- Use testnets and throwaway wallets for payment tests; never test with real funds in automated suites.

## 10. Definition of tested

A feature is tested when: its controller logic has unit tests, new or changed policies have allow/deny pgTAP tests, new Edge Function logic has tests for failure paths, and the happy path was exercised manually on at least one mobile device and one browser.
