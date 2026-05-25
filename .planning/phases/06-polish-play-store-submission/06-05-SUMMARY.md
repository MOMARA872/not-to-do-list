---
phase: "06-polish-play-store-submission"
plan: "05"
subsystem: "settings-reset"
tags: ["wave-3", "reset", "SETT-02", "D-13", "D-14", "Pitfall-2"]
dependency_graph:
  requires:
    - "06-01 (RED test stubs)"
    - "06-02 (themeModeProvider)"
    - "06-03 (SettingsScreen placeholder _showResetDialog)"
  provides:
    - "ResetController — atomic 5-step reset sequence (alarm cancel + Drift wipe + prefs.clear + 5 provider invalidations + nav)"
    - "SettingsScreen _showResetDialog wired with verbatim D-13 body + cs.error FilledButton"
  affects:
    - "Onboarding flow (user re-enters /onboarding/welcome after reset)"
    - "All 5 prefs-backed providers invalidated on reset"
tech_stack:
  added: []
  patterns:
    - "ProviderScope.containerOf(context) to bridge WidgetRef → ProviderContainer for service-layer invalidation"
    - "Dialog pop-with-bool pattern: show dialog → if confirmed → run controller (SettingsScreen context, not dialog context)"
    - "In-memory Drift seeded DB + MockNotificationApi + MockPermissionStatusApi for unit tests"
    - "UnmountedContext fake for testing non-navigation side effects without GoRouter"
key_files:
  created:
    - "lib/features/settings/services/reset_controller.dart"
  modified:
    - "lib/features/settings/pages/settings_screen.dart (replaced placeholder _showResetDialog)"
    - "test/features/settings/reset_controller_test.dart (RED→GREEN: 7 tests)"
    - "test/features/settings/reset_dialog_test.dart (RED→GREEN: 7 tests)"
decisions:
  - "ResetController accepts ProviderContainer (not Ref/WidgetRef) because ProviderOrFamily is not exported from flutter_riverpod; ProviderScope.containerOf(context) bridges widget layer cleanly"
  - "Tests 1-5 in reset_controller_test use _UnmountedContext to avoid GoRouter requirement in pure unit tests; Test 6 uses full widget pump with GoRouter for nav assertion"
  - "Provider invalidation assertion uses isLoading==true (not isA<AsyncLoading>) because Riverpod 3.x returns AsyncData(isLoading:true) when prior data exists, matching the Pitfall 2 intent"
metrics:
  duration: "~35min"
  completed: "2026-05-25"
  tasks_completed: 2
  files_created: 1
  files_modified: 3
---

# Phase 6 Plan 05: Reset Feature End-to-End Summary

ResetController with atomic 5-step sequence (alarm cancel → Drift wipe → prefs.clear → 5 provider invalidations → navigate) + SettingsScreen wired with verbatim D-13 AlertDialog copy and cs.error FilledButton — SETT-02 complete.

## What Was Built

**Task 1: ResetController** (commit `4243f05`)

- `lib/features/settings/services/reset_controller.dart`: plain service class owning the SETT-02 reset sequence
  - Step 1: `cancelDailyReminder()` BEFORE prefs.clear() — prevents pending alarm from firing on cleared pref state (Runtime State Inventory)
  - Step 2: Drift transaction wiping 5 tables in FK-safe child-first order: `dailyCheckins → pauseEvents → dailyStreak → dailyUsageSummary → blockList`
  - Step 3: `SharedPreferences.clear()` — wipes ALL keys including future-added ones (D-14 true clean slate, NOT per-key remove)
  - Step 4: Cascade invalidation of 5 prefs-backed providers (`onboardingCompleteProvider`, `themeModeProvider`, `reminderTimeProvider`, `streakThresholdProvider`, `postNotificationsGrantedProvider`) BEFORE navigation (Pitfall 2 — prevents pre-reset flash)
  - Step 5: `if (context.mounted) context.go('/onboarding/welcome')` (Pattern 6)
  - Constructor accepts `ProviderContainer` to avoid `ProviderOrFamily` sealed-class type constraint
- `test/features/settings/reset_controller_test.dart`: 7 tests GREEN
  - Test 1: `cancelDailyReminder` is FIRST event recorded
  - Test 2: All 5 FK-linked tables empty after Drift transaction
  - Test 3: All 5 tables row-count == 0 after resetAll
  - Test 4: `SharedPreferences.getKeys()` empty after reset
  - Test 5: All 5 providers in loading state after invalidation (`isLoading==true`)
  - Test 6: `context.go('/onboarding/welcome')` invoked when context is mounted (widget test with GoRouter)
  - Test 7: When context unmounted, no navigation call attempted

**Task 2: SettingsScreen Reset Dialog** (commit `8b130b7`)

- `lib/features/settings/pages/settings_screen.dart`: replaced `TODO(06-05)` placeholder with real `_showResetDialog`
  - AlertDialog title: `'Reset all data'`
  - AlertDialog body: verbatim D-13 copy — `'This deletes every entry, streak day, pause event, and check-in. This cannot be undone.'` (calm tone, zero `!` or `?`)
  - Cancel `TextButton` listed FIRST (default-focused per D-13 + UI-SPEC §Accessibility)
  - Reset `FilledButton` with `FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)`
  - Dialog pops with `bool` result; if `confirmed == true`, creates `ResetController` with `ProviderScope.containerOf(context)` and calls `controller.resetAll(context)` using SettingsScreen context (not dialog context — prevents post-pop context footgun)
- `test/features/settings/reset_dialog_test.dart`: 7 tests GREEN (6 widget tests + 1 source-grep invariant)

## Verification

- `flutter test test/features/settings/reset_controller_test.dart test/features/settings/reset_dialog_test.dart` exits 0 — 14 tests passing
- `flutter test` (full suite) exits 0 — 519 passing + 30 skipped (RED stubs for 06-04/06-06) + 0 failures
- `dart analyze lib/features/settings/services/reset_controller.dart lib/features/settings/pages/settings_screen.dart` — no issues found
- Acceptance criteria greps:
  - `grep "This deletes every entry"` → line 100 in settings_screen.dart
  - `grep "FilledButton.styleFrom"` → line 111
  - `grep "backgroundColor: cs.error"` → line 112
  - `grep "foregroundColor: cs.onError"` → line 113
  - `grep "TODO(06-05)"` → empty (all markers removed)
  - `grep -E '[!?]' ... | grep 'This deletes every entry'` → empty (calm tone confirmed)
  - `grep "ResetController("` → line 124

## Deviations from Plan

### [Rule 2 - Type Architecture] ResetController accepts ProviderContainer instead of Ref

**Found during:** Task 1 implementation

**Issue:** The plan specifies `final Ref _ref` in the constructor. However, `Ref` is a sealed class from `package:riverpod` and is not a common supertype of both `WidgetRef` (used in widget layer) and `ProviderContainer` (used in tests). Additionally, `ProviderOrFamily` is not exported from `package:flutter_riverpod`, preventing a callback-based approach using that type.

**Fix:** Constructor accepts `ProviderContainer` instead of `Ref`. In the widget layer, `ProviderScope.containerOf(context, listen: false)` provides the container. In tests, the `ProviderContainer` is passed directly. This satisfies both use cases without type gymnastics.

**Impact:** The dialog code uses `ProviderScope.containerOf(context)` rather than `ref` directly. Functionally identical — `ProviderContainer.invalidate` has the same semantics as `Ref.invalidate`.

### [Rule 1 - Bug] Provider invalidation test uses isLoading instead of isA<AsyncLoading>

**Found during:** Task 1 test GREEN phase

**Issue:** When `container.invalidate()` is called on a provider that has previously resolved to `AsyncData`, Riverpod 3.x transitions the provider to `AsyncData(isLoading: true)` (a refreshing state), NOT pure `AsyncLoading`. The original test assertion `isA<AsyncLoading<bool>>()` failed.

**Fix:** Changed assertion to `provider.isLoading == true`, which is true for both `AsyncLoading` (first load) and `AsyncData(isLoading: true)` (refresh). This correctly captures the Pitfall 2 intent — providers are reloading before navigation.

### [Rule 1 - Bug] Test 3 button type assertion used cast instead of find.widgetWithText

**Found during:** Task 2 test GREEN phase

**Issue:** `(b.child as Text?)?.data == 'Reset'` threw `_TypeError: type 'Row' is not a subtype of type 'Text?'` — `FilledButton` wraps child in a `Row` internally.

**Fix:** Changed to `find.widgetWithText(FilledButton, 'Reset')` which correctly traverses the widget tree.

## Known Stubs

None. The placeholder `_showResetDialog` from 06-03 is fully replaced. No new stubs introduced.

## Threat Flags

None. ResetController only destroys data (no new network surface, no new auth paths, no new file access). Operates entirely on local SQLite + SharedPreferences.

## Self-Check: PASSED

- [x] `lib/features/settings/services/reset_controller.dart` exists with `class ResetController` and `Future<void> resetAll(BuildContext`
- [x] Source contains `cancelDailyReminder()` call BEFORE `transaction(` (verified by source line order: line 64 vs line 67 in reset_controller.dart)
- [x] Source contains all 5 table delete calls: `_db.delete(_db.dailyCheckins)`, `_db.delete(_db.pauseEvents)`, `_db.delete(_db.dailyStreak)`, `_db.delete(_db.dailyUsageSummary)`, `_db.delete(_db.blockList)`
- [x] Source contains `prefs.clear()` (NOT `prefs.remove`)
- [x] Source contains 5 distinct `_container.invalidate(` calls (via cascade)
- [x] Source contains `if (context.mounted) context.go('/onboarding/welcome')`
- [x] `settings_screen.dart` contains no `TODO(06-05)` markers
- [x] `settings_screen.dart` contains verbatim D-13 body copy
- [x] `settings_screen.dart` contains `FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError)`
- [x] Commits `4243f05` (Task 1) and `8b130b7` (Task 2) exist on `worktree-agent-a0c22ae0dbebe2c1d`
- [x] `flutter test` exits 0 (519 passing + 30 skipped)
- [x] `dart analyze` — no issues found
