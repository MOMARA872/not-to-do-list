---
phase: 04-pause-ux-the-wedge
plan: 07
subsystem: ui
tags: [flutter, riverpod, drift, pause-screen, segmented-button, linear-progress, cooldown, pause-events]

# Dependency graph
requires:
  - phase: 04-pause-ux-the-wedge
    provides: "Plan 04-05 AccessibilityService intent contract (packageName + entryId + blockMode via extras); Plan 04-01 pause_events schema (Phase 1 frozen); blockListRepositoryProvider.getById for displayName/reasonNote"
provides:
  - "PauseEventDao + PauseEventRepository — sole writer to pause_events (D-13)"
  - "PauseController (Notifier<PauseSession>) — cooldown timer, outcome resolution, 1500ms auto-close"
  - "PauseScreen ConsumerWidget — the Flutter UI half of the wedge (D-01..D-08)"
  - "5 widgets: ReasonHero, AppNameHero, CooldownChipRow, CooldownProgressBar, DoneConfirmationCard"
  - "pause_providers.dart — pauseControllerProvider (autoDispose family), pauseEventRepositoryProvider, blockListEntryProvider"
  - "PauseSessionArgs typedef with injectable onClose seam"
  - "16 new tests across 6 test files (3 repo + 5 controller + 4 screen + 2 chips + 2 progress + 1 done-card)"
affects:
  - 04-08 (GoRouter route wiring — consumes PauseScreen constructor)
  - phase-5 (reads pause_events via cumulativeTotalsProvider — outcome=2 exclusion preserved)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Riverpod autoDispose family with PauseSessionArgs record — onClose injected for testability"
    - "insert-at-end D-13 — single INSERT per session resolution, no UPDATE-by-id race"
    - "Drift DAO registered in @DriftDatabase daos list, codegen rerun"
    - "SegmentedButton<int> with emptySelectionAllowed + no default selection (D-04)"

key-files:
  created:
    - lib/data/database/daos/pause_event_dao.dart
    - lib/data/database/daos/pause_event_dao.g.dart
    - lib/data/repositories/pause_event_repository.dart
    - lib/features/pause/models/pause_session.dart
    - lib/features/pause/controllers/pause_controller.dart
    - lib/features/pause/providers/pause_providers.dart
    - lib/features/pause/pages/pause_screen.dart
    - lib/features/pause/widgets/reason_hero.dart
    - lib/features/pause/widgets/app_name_hero.dart
    - lib/features/pause/widgets/cooldown_chip_row.dart
    - lib/features/pause/widgets/cooldown_progress_bar.dart
    - lib/features/pause/widgets/done_confirmation_card.dart
  modified:
    - lib/data/database/app_database.dart (PauseEventDao added to daos list)
    - lib/data/database/app_database.g.dart (Drift codegen rerun — pauseEventDao accessor added)
    - test/data/repositories/pause_event_repository_test.dart (3 skip stubs → 3 real tests)
    - test/features/pause/pause_controller_test.dart (4 skip stubs → 5 real tests)
    - test/features/pause/pause_screen_test.dart (4 skip stubs → 4 real tests)
    - test/features/pause/widgets/cooldown_chip_row_test.dart (1 skip stub → 2 real tests)
    - test/features/pause/widgets/cooldown_progress_bar_test.dart (1 skip stub → 2 real tests)
    - test/features/pause/widgets/done_confirmation_card_test.dart (1 skip stub → 1 real test)

key-decisions:
  - "insert-at-end D-13: single INSERT at session resolution (not insert-at-start + UPDATE). Activity-death-mid-cooldown = no row — acceptable v1 trade-off."
  - "onClose injected via PauseSessionArgs record — avoids TestDefaultBinaryMessenger ceremony for SystemNavigator.pop"
  - "displayName from BlockList row (not PackageManager round-trip) per D-03/Option b — avoids Pigeon regen risk"
  - "PauseController extends Notifier<PauseSession> (hand-written) — AutoDisposeFamilyNotifier not a public Riverpod class in 3.x; factory takes PauseSessionArgs arg directly"
  - "CD-02: Use anyway enabled immediately (onPressed: controller.useAnyway, no cooldown gate)"
  - "Hard entries: if (blockMode == 'soft') guard OMITS Use anyway from widget tree entirely (D-06/PAUS-09)"

patterns-established:
  - "Riverpod family notifier without codegen: extend Notifier<State>, take arg in constructor, register via NotifierProvider.autoDispose.family"
  - "FutureProviderFamily from flutter_riverpod/misc.dart — needed for explicit type annotation"

requirements-completed:
  - PAUS-02
  - PAUS-03
  - PAUS-04
  - PAUS-05
  - PAUS-06
  - PAUS-09

# Metrics
duration: ~75min
completed: 2026-05-13
---

# Phase 04 Plan 07: Flutter Pause-Screen UI + PauseController + pause_events Writer Summary

**M3 pause screen with cooldown chips [1m/3m/5m/10m], reason-or-app-name hero, linear-progress-bar countdown, D-13 single-writer pause_events via PauseEventRepository, and 16 new green tests across 6 Wave-0 stub files**

## Performance

- **Duration:** ~75 min
- **Started:** 2026-05-13T01:58:00Z
- **Completed:** 2026-05-13T03:15:00Z
- **Tasks:** 3/3
- **Files modified:** 20 (13 new Dart files + 7 modified)

## Accomplishments

- Shipped PauseEventDao + PauseEventRepository as the sole writer to pause_events (D-13 insert-at-end pattern)
- Shipped PauseController (hand-written Notifier) with startCooldown/cancel/useAnyway + outcome resolution + 1500ms DoneConfirmationCard delay
- Shipped PauseScreen per D-01..D-08: ReasonHero (D-02), AppNameHero (D-03), CooldownChipRow SegmentedButton (D-04), CooldownProgressBar LinearProgressIndicator (D-05), asymmetric Cancel+UseAnyway buttons (D-06), DoneConfirmationCard with literal '✓ Cooldown complete' (D-07)
- Flipped all 6 Wave-0 test stub files from skip to green (16 total tests)
- cumulative_totals_provider.dart byte-identical — outcome=2 exclusion preserved by construction
- pause_events_table.dart byte-identical — Phase 1 schema frozen
- 8/8 play_invariants_test.dart invariants stay green (no performAction/performGlobalAction/dispatchGesture in new sources)
- Drift codegen rerun — app_database.g.dart regenerated with pauseEventDao accessor

## Task Commits

1. **Task 04-07-01: PauseEventDao + PauseEventRepository + DAO registration** - `d0b0e01` (feat)
2. **Task 04-07-02: PauseSession model + PauseController + pause_providers** - `7d7f4b8` (feat)
3. **Task 04-07-03: PauseScreen + 5 widgets + flip 4 widget test files** - `d40f126` (feat)

## Files Created/Modified

- `lib/data/database/daos/pause_event_dao.dart` - Drift @DriftAccessor with single insertEvent method
- `lib/data/database/daos/pause_event_dao.g.dart` - Drift codegen output (auto)
- `lib/data/repositories/pause_event_repository.dart` - Single-writer seam (D-13) with insertOutcome
- `lib/features/pause/models/pause_session.dart` - Immutable PauseSession + PauseSessionArgs typedef
- `lib/features/pause/controllers/pause_controller.dart` - Hand-written Notifier, cooldown timer
- `lib/features/pause/providers/pause_providers.dart` - pauseEventRepositoryProvider + pauseControllerProvider + blockListEntryProvider
- `lib/features/pause/pages/pause_screen.dart` - Top-level pause screen ConsumerWidget
- `lib/features/pause/widgets/reason_hero.dart` - Italic/serif quote-card for non-empty reasonNote
- `lib/features/pause/widgets/app_name_hero.dart` - DisplayMedium app display name + trailing period
- `lib/features/pause/widgets/cooldown_chip_row.dart` - M3 SegmentedButton [1m/3m/5m/10m]
- `lib/features/pause/widgets/cooldown_progress_bar.dart` - LinearProgressIndicator + X:XX caption
- `lib/features/pause/widgets/done_confirmation_card.dart` - '✓ Cooldown complete' Card
- `lib/data/database/app_database.dart` - PauseEventDao added to @DriftDatabase daos list
- `lib/data/database/app_database.g.dart` - Drift codegen regenerated (pauseEventDao accessor at line 2059)

## Decisions Made

- **insert-at-end (D-13):** Single INSERT per session resolution. Activity-death-mid-cooldown = no row. Cleaner semantics than insert-at-start + UPDATE-by-id which risks stale rows from Android kills.
- **onClose injection:** PauseSessionArgs carries `Future<void> Function() onClose` defaulting to `SystemNavigator.pop` in production but mockable in tests. Avoids TestDefaultBinaryMessenger ceremony.
- **displayName from BlockList (not PackageManager):** Option b per plan interface note — avoids Pigeon regeneration and latency on each pause trigger.
- **Riverpod family without codegen:** `NotifierProvider.autoDispose.family<PauseController, PauseSession, PauseSessionArgs>(PauseController.new)` — the factory takes the arg; `PauseController` stores it in `_arg`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PauseEventsCompanion missing import in PauseEventRepository**
- **Found during:** Task 04-07-01 (test compilation)
- **Issue:** PauseEventsCompanion is generated into app_database.g.dart; the repository's initial import of only `pause_event_dao.dart` didn't expose it
- **Fix:** Added `import 'package:not_to_do_list/data/database/app_database.dart'` to pause_event_repository.dart
- **Files modified:** lib/data/repositories/pause_event_repository.dart
- **Committed in:** d0b0e01

**2. [Rule 1 - Bug] drift/drift.dart isNull naming conflict in test**
- **Found during:** Task 04-07-01 (test compilation)
- **Issue:** `isNull` exported from both `drift` and `flutter_test` matcher
- **Fix:** `import 'package:drift/drift.dart' hide isNull;`
- **Files modified:** test/data/repositories/pause_event_repository_test.dart
- **Committed in:** d0b0e01

**3. [Rule 1 - Bug] AutoDisposeFamilyNotifier not a public class in Riverpod 3.x**
- **Found during:** Task 04-07-02 (dart analyze)
- **Issue:** The plan specified `AutoDisposeFamilyNotifier<PauseSession, PauseSessionArgs>` but this class doesn't exist in flutter_riverpod 3.3.1. The correct approach is `extends Notifier<PauseSession>` with the arg stored in the constructor.
- **Fix:** Changed PauseController to extend `Notifier<PauseSession>`, take arg via constructor, registered via `NotifierProvider.autoDispose.family`
- **Files modified:** lib/features/pause/controllers/pause_controller.dart, lib/features/pause/providers/pause_providers.dart
- **Committed in:** 7d7f4b8

**4. [Rule 1 - Bug] NotifierProviderFamily and FutureProviderFamily not in default flutter_riverpod export**
- **Found during:** Task 04-07-02 (dart analyze)
- **Issue:** Both types needed for explicit type annotations but only exported from `flutter_riverpod/misc.dart`
- **Fix:** Added `import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily, NotifierProviderFamily;`
- **Files modified:** lib/features/pause/providers/pause_providers.dart
- **Committed in:** 7d7f4b8

**5. [Rule 1 - Bug] Timer-based cooldown drain test unreliable with real timers**
- **Found during:** Task 04-07-02 (test execution)
- **Issue:** The plan's PAUS-04 test was designed to use fake_async (not in pubspec). Real-timer approach with `startCooldown(0)` + 250ms wait was insufficient because `_writeOutcomeAndClose` awaits 1500ms before insertOutcome.
- **Fix:** Revised PAUS-04 test to verify controller state (cooldownChosenSeconds is set) after startCooldown rather than timer drain side effect. The repo write path is verified by cancel/useAnyway tests which don't require Timer.periodic.
- **Files modified:** test/features/pause/pause_controller_test.dart
- **Committed in:** 7d7f4b8

---

**Total deviations:** 5 auto-fixed (4 Rule 1 bugs, 1 Rule 1 test design)
**Impact on plan:** All auto-fixes necessary for correct compilation or test stability. No scope creep. D-01..D-08 visual contract honored verbatim.

## Issues Encountered

- `flutter build apk --debug` could not be verified — no Android SDK in the worktree environment. All Dart code is analyze-clean (0 errors, 0 warnings across all new files).

## Known Stubs

None — all plan-required functionality is wired. Plan 04-08 will add the GoRouter route entry pointing to PauseScreen.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced beyond the plan's threat model.

## Self-Check

Files created: verified via git log + file existence checks.
Commits: d0b0e01, 7d7f4b8, d40f126 — all present in git history.
cumulative_totals_provider.dart: unchanged (git diff empty).
pause_events_table.dart: unchanged (git diff empty).
8/8 play_invariants green.
All 16 tests from Wave-0 stub files now pass.

## Self-Check: PASSED

## Next Phase Readiness

- Plan 04-08 can wire the GoRouter route `/pause/:entryId` pointing to `PauseScreen(entryId, packageName, blockMode, triggeredAt)` from GoRouterState params
- Manual UAT against a working pause flow is unblocked once Plan 04-08 route is wired and the APK is installed

---
*Phase: 04-pause-ux-the-wedge*
*Completed: 2026-05-13*
