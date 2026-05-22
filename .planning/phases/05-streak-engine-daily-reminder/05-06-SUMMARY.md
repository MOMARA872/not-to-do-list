---
phase: 05-streak-engine-daily-reminder
plan: "06"
subsystem: checkin
tags: [checkin, streak, riverpod, drift, router, widget-test]
dependency_graph:
  requires: [05-02, 05-03, 05-05]
  provides: [/checkin-route, checkin-screen, checkin-controller, checkin-providers]
  affects: [app_router, daily_checkins, daily_streak]
tech_stack:
  added: []
  patterns:
    - ConsumerStatefulWidget with initState reset for transient StateProvider
    - Single Drift db.transaction() for multi-row atomic write (D-03)
    - ref.listen single-listener pattern for error+navigation handling
    - _kErrorCopy top-level const for UI-SPEC copy with non-ASCII characters
    - GoRouter + MaterialApp.router scaffold in widget tests
key_files:
  created:
    - lib/features/checkin/providers/checkin_providers.dart
    - lib/features/checkin/controllers/checkin_controller.dart
    - lib/features/checkin/pages/checkin_screen.dart
  modified:
    - lib/core/router/app_router.dart
    - test/features/checkin/checkin_screen_test.dart
decisions:
  - Used single ref.listen handler for both error SnackBar and post-submit navigation (avoids cascade_invocations lint)
  - Extracted _kErrorCopy as top-level const to satisfy prefer_single_quotes when string contains apostrophe + em dash
  - STRK-09 weekday filter uses midpoint-of-window test time to determine in-mask status without time-of-day dependency
  - _ErrorCheckinController extends CheckinController in tests to override submit() for error path
metrics:
  duration: "~45 minutes"
  completed: "2026-05-22"
  tasks_completed: 1
  files_created: 3
  files_modified: 2
---

# Phase 5 Plan 06: /checkin Screen + Idempotent Single-Transaction Submit + GoRouter Wiring Summary

**One-liner:** Full-screen /checkin GoRoute with Yes/No SegmentedButton per entry, single Drift transaction write for N rows, streak rollover re-trigger, and D-01 idempotent locked display for already-answered entries.

## What Was Built

### New Files

**`lib/features/checkin/providers/checkin_providers.dart`**
- `pendingCheckinsTodayProvider` — FutureProvider that reads all block_list entries, applies STRK-09 weekday-mask filter, and splits into `{pending, answered}` buckets for today's streak day.
- `checkinAnswersProvider` — legacy `StateProvider<Map<int, bool>>` tracking unsaved Yes/No answers for the current session. Reset on screen open via `initState` + `addPostFrameCallback`.

**`lib/features/checkin/controllers/checkin_controller.dart`**
- `CheckinController extends Notifier<AsyncValue<void>>` — `submit()` reads `checkinAnswersProvider`, writes ALL answered entries in ONE `db.transaction()` call (D-03), then triggers `streakRolloverServiceProvider.rollover()` post-write. On error sets `AsyncError` state for the screen's `ref.listen` to surface.
- `checkinControllerProvider` — hand-written `NotifierProvider` (no codegen per 01-01-SUMMARY.md pattern).

**`lib/features/checkin/pages/checkin_screen.dart`**
- `CheckinScreen` (ConsumerStatefulWidget) — AppBar "Daily check-in" (centerTitle: false), SingleChildScrollView body with 16px padding.
- Heading "How did today go?" (titleLarge, w400).
- Per-entry `_EntryRow` with leading AppIcon/spa_outlined (32px), bodyMedium displayName, `SegmentedButton<bool>` {Yes/No}.
- Pending entries: interactive SegmentedButton updates `checkinAnswersProvider`.
- Already-answered entries: locked SegmentedButton (onSelectionChanged: null) with stored answer selected (D-01 idempotency).
- FilledButton "Save check-in" / "All done" (minimumSize: Size.fromHeight(48)) — disabled until ≥1 new answer.
- Empty state: check_circle_outline 48px + "You're all caught up" (titleMedium) + "Check back tomorrow." (bodyMedium, onSurfaceVariant).
- Single `ref.listen` handles both error SnackBar and post-submit `context.go('/')`.

### Modified Files

**`lib/core/router/app_router.dart`**
- Appended `GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen())` after `/dashboard` route.
- Import added in alphabetical order.
- T-2-10 onboarding redirect logic preserved byte-for-byte (line `if (completed && goingToOnboarding) return '/';` unchanged).

**`test/features/checkin/checkin_screen_test.dart`**
- Filled all 7 Wave 0 stubs (Plan 05-01). No `skip:` markers remain.
- Tests: AppBar title, heading, Yes/No segments; button disabled until answer; 3-entry D-03 transaction write verified by reading DB rows; D-01 locked SegmentedButton with stored answer; empty state both strings; error SnackBar exact copy.
- Uses `GoRouter + MaterialApp.router` scaffold so `context.go('/')` works after submit.
- `_NoopRolloverService` extends `StreakRolloverService` to skip Pigeon + SharedPrefs in tests.
- `_ErrorCheckinController` extends `CheckinController` to override `submit()` for error path.

## Deviations from Plan

### Auto-fixed Issues

None of the deviations required structural changes. Minor implementation adjustments:

**1. [Rule 1 - Bug] Single ref.listen instead of two**
- **Found during:** Task 1 linting
- **Issue:** Two consecutive `ref.listen` calls on the same `checkinControllerProvider` triggered `cascade_invocations` lint. The plan spec showed two listeners (error + navigate).
- **Fix:** Merged into a single listener that handles both error SnackBar (via `whenOrNull`) and navigation (via `prev?.isLoading` transition check). Semantics identical.
- **Files modified:** `lib/features/checkin/pages/checkin_screen.dart`
- **Commit:** e725b47

**2. [Rule 1 - Bug] Error copy extracted to top-level const**
- **Found during:** Task 1 linting
- **Issue:** Inline string `"Something went wrong — your check-in wasn't saved. Try again."` triggered `prefer_single_quotes` because of the apostrophe; escaping in single-quotes triggered `avoid_escaping_inner_quotes`.
- **Fix:** Extracted to `const String _kErrorCopy` at file scope, defined with double quotes (contains apostrophe so double-quotes avoid escaping). The `_kErrorCopy` const is visible to both the `const SnackBar(content: Text(_kErrorCopy))` call and the test's expected string.
- **Files modified:** `lib/features/checkin/pages/checkin_screen.dart`
- **Commit:** e725b47

**3. [Rule 1 - Bug] GoRouter scaffold in tests**
- **Found during:** Task 1 test run
- **Issue:** `MaterialApp(home: CheckinScreen())` caused `context.go('/')` to throw "No GoRouter found in context" in the D-03 transaction test.
- **Fix:** Replaced with `MaterialApp.router(routerConfig: GoRouter(...))` with `/checkin` as initial location and a stub `/` home. Matches the `reminder_off_banner_test.dart` pattern.
- **Files modified:** `test/features/checkin/checkin_screen_test.dart`
- **Commit:** e725b47

## Verification Results

```
flutter analyze lib/features/checkin/ lib/core/router/
  → No issues found.

flutter test test/features/checkin/checkin_screen_test.dart
  → +7: All tests passed!

flutter test test/policy/play_invariants_test.dart test/policy/phase_5_invariants_test.dart
  → +14 ~2: All tests passed! (2 skipped = manual-only real-device tests)

grep -c "GoRoute(path: '/checkin'" lib/core/router/app_router.dart → 1
grep -c "import 'package:not_to_do_list/features/checkin/pages/checkin_screen.dart'" lib/core/router/app_router.dart → 1
grep -c 'completed && goingToOnboarding' lib/core/router/app_router.dart → 1
grep -c 'transaction' lib/features/checkin/controllers/checkin_controller.dart → 4
grep -c 'streakRolloverServiceProvider' lib/features/checkin/controllers/checkin_controller.dart → 1
```

## Known Stubs

None.

## Threat Flags

No new network endpoints, auth paths, or trust-boundary crossing introduced. `/checkin` is gated behind the existing T-2-10 onboarding redirect in app_router.dart (verified by grep acceptance criterion and by the redirect logic being unchanged).

## Self-Check: PASSED

- `lib/features/checkin/providers/checkin_providers.dart` — FOUND
- `lib/features/checkin/controllers/checkin_controller.dart` — FOUND
- `lib/features/checkin/pages/checkin_screen.dart` — FOUND
- `lib/core/router/app_router.dart` (GoRoute /checkin) — FOUND
- `test/features/checkin/checkin_screen_test.dart` (7 GREEN tests) — FOUND
- Commit e725b47 — FOUND
