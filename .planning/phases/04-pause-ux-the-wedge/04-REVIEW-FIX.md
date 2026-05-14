---
phase: 04-pause-ux-the-wedge
fixed_at: 2026-05-14T21:55:10Z
review_path: .planning/phases/04-pause-ux-the-wedge/04-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 7
fixed: 6
skipped: 1
status: partial
---

# Phase 04: Code Review Fix Report — Pause UX (The Wedge)

**Fixed at:** 2026-05-14T21:55:10Z
**Source review:** `.planning/phases/04-pause-ux-the-wedge/04-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 6
- Skipped: 1

---

## Fixed Issues

### CR-01: GoRouter defaults `blockMode` to `'soft'` — hard entries show "Use anyway"

**Files modified:** `lib/core/router/app_router.dart`
**Commit:** `66717ae`
**Applied fix:** Replaced `state.uri.queryParameters['mode'] ?? 'soft'` with a strict enum validation. Extracted `rawMode` and computed `blockMode` as `(rawMode == 'soft' || rawMode == 'hard') ? rawMode! : 'hard'`. Any missing, null, or unrecognized `mode=` parameter now defaults to `'hard'` (fail-closed — the more restrictive mode, omits "Use anyway" button per PAUS-09/D-06).

---

### CR-02 + WR-03: Double-write race + disposed `ref` in `_writeOutcomeAndClose`

**Files modified:** `lib/features/pause/controllers/pause_controller.dart`
**Commit:** `7430fd8`
**Applied fix (CR-02):** Added `if (state.isComplete) return;` guard at the very top of `_writeOutcomeAndClose`, before the first `await`. Because `state.isComplete` is read synchronously before any `await`, there is no async gap within the guard itself. This prevents the double-write race when the cooldown timer drain and a user tap (Cancel / Use-anyway) call `_writeOutcomeAndClose` concurrently.

**Applied fix (WR-03):** Moved `final repo = ref.read(pauseEventRepositoryProvider);` to immediately after the guard check (before the first `await`). This ensures `ref` is read while the provider container is still alive. If `PauseActivity` is killed mid-cooldown and Riverpod's `autoDispose` fires, the floating `unawaited` future no longer throws `StateError: "Cannot use ref after it was disposed"` when resuming after an `await`.

**Verification:** `fix: requires human verification` — the timing of the async guard across real-world OS scheduling (especially Samsung/Xiaomi aggressive background reclaim) cannot be fully verified by unit tests alone; the fakeAsync test (WR-05) covers the synchronous path.

---

### WR-02: `PauseActivity` binds FlutterEngine before `finish()` in fail-closed branch

**Files modified:** `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt`
**Commit:** `6483151`
**Applied fix:** Removed `super.onCreate(savedInstanceState)` from the fail-closed branch (malformed Intent). The branch now calls `finish(); return;` directly without calling super. This prevents `FlutterActivity.onCreate()` from invoking `provideFlutterEngine()`, which would consume the cached `"pause_engine"` entry (or create a new engine) before the Activity is destroyed. The fix replaces the misleading `// no engine bind` comment (which was inaccurate) with an accurate explanation of why `super.onCreate` is omitted.

Android contract note: calling `finish()` without `super.onCreate` is legal — the Activity framework creates the Activity in CREATED state and transitions it to DESTROYED via `finish()` without requiring the full `onCreate → onStart → onResume` lifecycle.

---

### WR-04: Dart parity test comment falsely claims Kotlin uses `America/Los_Angeles` timezone

**Files modified:** `test/domain/schedule/schedule_window_parity_test.dart`
**Commit:** `a522b7e`
**Applied fix:** Replaced the false claim at two locations (line 33 and the GROUP 5 DST section comment) that stated "The Kotlin counterpart uses `TimeZone.getTimeZone("America/Los_Angeles")` explicitly." The Kotlin `ScheduleWindowTest.kt` actually uses `TimeZone.getDefault()` throughout (confirmed by reading the file — `Calendar.getInstance(TimeZone.getDefault())` in the `ms()` helper and the GROUP 5 comment). Both Dart and Kotlin sides use local-TZ semantics; neither pins to a Pacific timezone. The new comment accurately states: "Both sides are locally-consistent but neither exercises real DST wall-clock gaps/folds. True DST testing would require pinned TZ + epoch math."

The fix is comment-only; no logic was changed. The Kotlin file was NOT modified (it already uses `TimeZone.getDefault()` correctly; only the Dart comment was wrong).

---

### WR-05: Missing fakeAsync drain test for `PauseController` outcome=0

**Files modified:** `test/features/pause/pause_controller_test.dart`
**Commit:** `894bc86`
**Applied fix:** Added two new tests in a new `'WR-05 fakeAsync drain — timer auto-completes outcome=0'` group.

**Test 1 — timer drain path:** Uses `package:fake_async/fake_async.dart` (transitive dependency via `flutter_test`; no new `pubspec.yaml` entry required). Creates a `PauseController` with a 60-second cooldown, advances fake time by 60100ms so all `Timer.periodic` ticks fire, then calls `fake.flushMicrotasks()` to drain the `unawaited(_writeOutcomeAndClose(0))` future chain. Verifies `remainingMs == 0` (synchronously set by the timer) and that `mockRepo.insertOutcome` is called exactly once with `outcome=0, cooldownChosenSeconds=60`. Uses `container.listen` to keep the `autoDispose` provider alive throughout the test (without a listener, Riverpod disposes the provider between async checkpoints, causing `StateError` on the second verify).

**Test 2 — CR-02 isComplete guard:** Calls `cancel()` twice sequentially on the same session. First call completes the session (`isComplete = true`). Second call hits the `if (state.isComplete) return;` guard and returns immediately. Verifies exactly one `insertOutcome` call total despite two `cancel()` invocations.

**Verification:** `flutter test test/features/pause/pause_controller_test.dart` — 7/7 tests pass.

---

## Skipped Issues

### WR-01: Release build signed with debug keystore

**File:** `android/app/build.gradle.kts:32-34`
**Reason:** Skipped — requires manual keystore setup. This finding requires creating a production signing keystore, configuring CI secrets (`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`), and updating `build.gradle.kts` with a `release` signing config. This is operational work that cannot be safely automated without the actual keystore material. The comment in `build.gradle.kts` already acknowledges this as a TODO. Fix before Play Store submission (REL-04 exit gate / Phase 6 `PLAY-08`).

---

## Verification Run

After all fixes: `flutter test --no-pub` passed 389 tests, 3 skipped (pre-existing IN-04 placeholder + 2 live-service tests). Zero new failures introduced.

---

_Fixed: 2026-05-14T21:55:10Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
