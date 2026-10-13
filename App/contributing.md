# Contributing to EliteChat

Version 0.1 (draft) · Last updated 2026-10-13

## 1. Workflow

- `main` is always releasable and protected: PRs only, required CI, at least one approving review.
- Branch names: `feat/<short-name>`, `fix/<short-name>`, `chore/<short-name>`, `docs/<short-name>`.
- Keep PRs small and focused (aim for under ~400 changed lines). Split schema changes, backend functions, and UI into separate PRs when practical.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/): `feat(chat): add retry for failed sends`.
- Squash-merge so history on `main` reads as one commit per change.

## 2. Code style

- Format with `dart format`; lint with `flutter analyze`. Start from `flutter_lints` (or a stricter set such as `very_good_analysis`) and treat warnings as errors in CI.

```yaml
# analysis_options.yaml (starting point)
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    missing_return: error
    dead_code: warning

linter:
  rules:
    - prefer_const_constructors
    - prefer_final_fields
    - avoid_print
    - always_declare_return_types
    - unawaited_futures
    - cancel_subscriptions
    - close_sinks
```

### Naming and files

| Item | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart` | `conversation_controller.dart` |
| Classes | `UpperCamelCase` | `ConversationController` |
| Routes | kebab-case path constants in `AppRoutes` | `/wallet-login` |
| DB objects | `snake_case`, plural tables | `conversation_members` |
| Edge Functions | kebab-case | `verify-payment` |
| Localization keys | `feature.element.purpose` | `chat.composer.hint` |

One public class per file for controllers, views, and repositories. Prefer `final` and immutable models.

## 3. GetX rules (enforced in review)

**Do**

- Inject dependencies through constructors; call `Get.find` only inside bindings.
- Register screen controllers in route bindings with `Get.lazyPut`.
- Cancel subscriptions, timers, and workers in `onClose`.
- Keep `Obx` scopes small.
- Handle every `Result` branch.

**Don't**

- Call Supabase, wallet SDKs, or HTTP from controllers or views.
- Use `Get.context` or store `BuildContext` in controllers.
- Use `Get.put` inside `build` methods.
- Put business rules only in the client when they must also hold on the server.
- Keep secrets, tokens, or personal data in globals or static fields.

## 4. Security rules for every PR

- No secrets, keys, or personal data committed (CI runs secret scanning).
- No `service_role` usage outside Edge Functions.
- New table → RLS enabled in the same migration, with allow/deny tests.
- New RPC or `security definer` function → `set search_path = ''`, schema-qualified names, `revoke` from `anon`/`public`, caller validation, tests.
- New Edge Function → input validation, authentication decision documented (public vs JWT), rate limiting considered, failure paths tested.
- New user-generated content surface → rendered as plain text, length limits at DB level.
- No logging of tokens, signatures, nonces, message content, or full wallet addresses.
- New dependency → justify it, check maintenance and permissions, pin the version. Wallet/crypto/auth packages require a second reviewer.

## 5. Database and migration rules

- Schema changes only through `supabase/migrations/`; never edit an applied migration.
- Migrations must run cleanly from scratch (`supabase db reset`) and be reviewed like code.
- Include indexes for new foreign keys and query patterns.
- Document policy intent in a comment above each policy.

## 6. Pull request checklist

```markdown
## What and why
<!-- Summary, linked issue/roadmap item -->

## Checklist
- [ ] `dart format`, `flutter analyze`, and tests pass locally
- [ ] Controller/repository logic covered by unit tests
- [ ] New or changed policies/functions covered by pgTAP or Deno tests (allow + deny)
- [ ] No secrets or sensitive data in code, logs, or fixtures
- [ ] Loading, empty, and error states handled in the UI
- [ ] Strings localized (en, bn); no hard-coded text
- [ ] Accessibility: labels, contrast, tap targets checked
- [ ] Docs updated (architecture / security / database / design) where behavior changed
- [ ] Screenshots or recording attached for UI changes (mobile + web where relevant)
```

## 7. Review guidelines

Reviewers check, in order: security and authorization → correctness → tests → architecture boundaries (see [architecture.md](architecture.md)) → readability → style. Be specific and kind; explain the why. Authors respond to every comment or resolve it with a reason.

## 8. Definition of done

- Acceptance criteria met and demoed on at least one mobile device and one browser.
- Tests written and passing in CI.
- Security checklist items for the change satisfied.
- Docs and ADRs updated.
- Feature behind a flag if partially complete.
- No new analyzer warnings, no TODOs without an issue reference.

## 9. Releases

1. Cut a release branch or tag from `main` (`vMAJOR.MINOR.PATCH`).
2. Run the full CI suite and the manual smoke test (sign in, send message, receive push, open deep link).
3. Apply migrations to staging first, then production; Edge Functions deploy with the same release.
4. Build mobile with `--obfuscate --split-debug-info`, upload symbols, and publish to store tracks (internal → beta → production).
5. Deploy Web with the security headers configured.
6. Monitor crash-free rate, error logs, and auth failure rates for 24–48 hours; have a rollback plan (previous build, forward-fix migration).

## 10. Documentation

Docs live in `docs/` and change with the code. Architectural decisions go into the ADR table in [architecture.md](architecture.md#16-architecture-decision-records). Security-impacting changes update [security.md](security.md).

## 11. Reporting security issues

Do not open public issues for vulnerabilities. Email the security contact (placeholder: `security@<your-domain>`) with reproduction steps and impact. See [security.md](security.md#16-incident-response-and-disclosure).
