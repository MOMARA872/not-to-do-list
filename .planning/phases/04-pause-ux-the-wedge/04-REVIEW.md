---
phase: 04-pause-ux-the-wedge
reviewed: 2026-05-10T00:00:00Z
depth: standard
files_reviewed: 47
files_reviewed_list:
  - android/app/build.gradle.kts
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApiImpl.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/BlocklistBroadcastApi.g.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/BlocklistBroadcastApiImpl.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt
  - android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindow.kt
  - android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt
  - lib/core/router/app_router.dart
  - lib/data/database/app_database.dart
  - lib/data/database/app_database.g.dart
  - lib/data/database/daos/pause_event_dao.dart
  - lib/data/database/daos/pause_event_dao.g.dart
  - lib/data/detectors/accessibility_blocked_app_detector.dart
  - lib/data/repositories/block_list_repository.dart
  - lib/data/repositories/pause_event_repository.dart
  - lib/domain/providers/accessibility_api_provider.dart
  - lib/domain/providers/block_list_repo_provider.dart
  - lib/domain/providers/blocked_app_detector_provider.dart
  - lib/domain/providers/blocklist_broadcast_provider.dart
  - lib/features/health/widgets/_health_lifecycle_observer.dart
  - lib/features/pause/controllers/pause_controller.dart
  - lib/features/pause/models/pause_session.dart
  - lib/features/pause/pages/pause_screen.dart
  - lib/features/pause/providers/pause_providers.dart
  - lib/features/pause/widgets/app_name_hero.dart
  - lib/features/pause/widgets/cooldown_chip_row.dart
  - lib/features/pause/widgets/cooldown_progress_bar.dart
  - lib/features/pause/widgets/done_confirmation_card.dart
  - lib/features/pause/widgets/reason_hero.dart
  - lib/platform/blocklist_broadcast_api.g.dart
  - pigeons/blocklist_broadcast_api.dart
  - test/_fixtures/pause_intent_fixture.dart
  - test/data/detectors/accessibility_blocked_app_detector_test.dart
  - test/data/repositories/blocklist_broadcast_test.dart
  - test/data/repositories/pause_event_repository_test.dart
  - test/domain/schedule/schedule_window_parity_test.dart
  - test/features/health/permission_health_provider_a11y_live_test.dart
  - test/features/pause/pause_controller_test.dart
  - test/features/pause/pause_screen_test.dart
  - test/features/pause/widgets/cooldown_chip_row_test.dart
  - test/features/pause/widgets/cooldown_progress_bar_test.dart
  - test/features/pause/widgets/done_confirmation_card_test.dart
  - test/platform/accessibility_api_test.dart
  - test/policy/play_invariants_test.dart
  - lib/domain/schedule/schedule_window.dart
findings:
  critical: 2
  warning: 5
  info: 4
  total: 11
status: issues_found
---

# Phase 04: Code Review Report — Pause UX (The Wedge)

**Reviewed:** 2026-05-10
**Depth:** standard
**Files Reviewed:** 47
**Status:** issues_found

## Summary

Phase 4 ships the core wedge: `NotToDoAccessibilityService` fires an Intent to `PauseActivity` (FlutterActivity) which hosts the reflection screen, cooldown chips, Cancel/Use-anyway buttons, and writes a `pause_events` row. The architecture is sound overall: single-writer seam (D-13) is correctly enforced, PLAY-02 autonomous-action tokens are absent from all code paths, the broadcast channel correctly omits the user's `reasonNote` from the snapshot DTO (T-04), and the debounce + schedule-gate logic in the service is correct.

Two critical defects were found: (1) a double-write race on the `pause_events` table when the cooldown auto-completes and the user taps Cancel or Use-anyway before the async write commits, and (2) the GoRouter `/pause/:entryId` route silently defaults `blockMode` to `'soft'` when the `mode=` query parameter is absent, which can cause a hard-block entry to display the "Use anyway" button. Five warnings cover the release signing config, a missing `isComplete` guard in the controller, an unregistered `savedInstanceState` hazard in `PauseActivity`, the DST parity-test comment mismatch, and the absence of a `fakeAsync`-based drain test for outcome=0. Four info items cover the unguarded `int.parse!` on route params, an orphaned-timer documentation gap, the placeholder `accessibility_api_test.dart`, and the `blockListEntryProvider` using `ref.read` inside a `FutureProvider`.

---

## Critical Issues

### CR-01: GoRouter defaults `blockMode` to `'soft'` — hard entries show "Use anyway"

**File:** `lib/core/router/app_router.dart:50`

**Issue:** The `/pause/:entryId` route reads `blockMode` from `state.uri.queryParameters['mode'] ?? 'soft'`. If the `mode=` query parameter is missing (malformed Intent, direct deep link, or URL truncation), the value silently falls back to `'soft'`. The `PauseScreen` then renders the "Use anyway" `TextButton` (`pause_screen.dart:131`) for what was intended as a hard-block entry. This is a functional violation of PAUS-09 / D-06: "Use anyway is OMITTED ENTIRELY from the widget tree for hard entries." A user whose entry is configured as `'hard'` would be able to tap "Use anyway" and exit the pause screen.

`PauseActivity.getInitialRoute()` always supplies `&mode=$blockMode`, so the normal code path is safe — but the default provides no protection against URL truncation, Activity recreation with a stale route, or a future code path that calls the Flutter router directly.

**Fix:**
```dart
// app_router.dart line 50
// Replace the ?? 'soft' default with a strict parse that fails closed:
final rawMode = state.uri.queryParameters['mode'];
final blockMode = (rawMode == 'soft' || rawMode == 'hard') ? rawMode : 'hard';
```
Defaulting to `'hard'` on missing/unrecognised values ensures that the UI fails closed (no "Use anyway") when the parameter is absent. Alternatively, pop the route immediately with a call to `SystemNavigator.pop()` if `rawMode` is null.

---

### CR-02: Double-write race in `PauseController` — two `pause_events` rows for one session

**File:** `lib/features/pause/controllers/pause_controller.dart:43-46` and `56-58` / `70-71`

**Issue:** When the cooldown timer drains to zero, the controller calls `unawaited(_writeOutcomeAndClose(outcome: 0))` (line 46). `_writeOutcomeAndClose` is an `async` function that (a) awaits the DB insert, (b) sets `state.isComplete = true`, then (c) awaits a 1500 ms delay before calling `onClose()`. There is no guard on `state.isComplete` at the entry of `_writeOutcomeAndClose`.

Between the timer firing (step a above) and `state.isComplete` becoming `true` (step b), the Riverpod state is still showing the active pause screen — the `DoneConfirmationCard` has not yet appeared. During this async gap (even microseconds is enough if the Flutter frame budget is exceeded), the user can tap "Cancel" or "Use anyway". Both `cancel()` (line 57) and `useAnyway()` (line 71) call `_writeOutcomeAndClose` again without checking `state.isComplete`. This results in two `pause_events` rows being inserted for the same session, corrupting the aggregate counts read by `cumulativeTotalsProvider`.

```
Timeline:
  t=0ms   timer tick: remaining <= 0 → _cancelTimer(); state.remainingMs = 0;
           unawaited(_writeOutcomeAndClose(0)) -- floating future
  t=0ms   _writeOutcomeAndClose(0): await repo.insertOutcome(outcome=0) ← row #1
  t=+1ms  User taps Cancel (screen still shows pause UI — isComplete is still false)
           cancel() → _writeOutcomeAndClose(1): await repo.insertOutcome(outcome=1) ← row #2
  t=+2ms  _writeOutcomeAndClose(0) resumes: state.isComplete = true (too late)
```

**Fix:** Add an `isComplete` guard at the top of `_writeOutcomeAndClose`:

```dart
Future<void> _writeOutcomeAndClose({required int outcome}) async {
  // Guard: if a prior call already resolved this session, drop this call.
  if (state.isComplete) return;

  final repo = ref.read(pauseEventRepositoryProvider);
  await repo.insertOutcome(
    entryId: _arg.entryId,
    packageName: _arg.packageName,
    triggeredAt: _arg.triggeredAt,
    outcome: outcome,
    cooldownChosenSeconds: state.cooldownChosenSeconds,
  );
  state = state.copyWith(isComplete: true);
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  await _arg.onClose();
}
```

Note: `state.isComplete` is read synchronously before the first `await`, so there is no second async gap within this guard.

---

## Warnings

### WR-01: Release build signed with debug keystore — not production-ready

**File:** `android/app/build.gradle.kts:32-34`

**Issue:** The release build type is configured with `signingConfig = signingConfigs.getByName("debug")`. An APK signed with the debug keystore cannot be distributed via Google Play and does not produce a stable `applicationId` fingerprint for the accessibility service record. The comment acknowledges this as a TODO, but it is a blocker for any Play Store submission or OEM survival testing on a locked-down device image.

**Fix:** Create a production signing config before the REL-04 OEM overnight test and the Play Store submission cycle. At minimum:

```kotlin
// build.gradle.kts — signingConfigs block
signingConfigs {
    create("release") {
        storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release.keystore")
        storePassword = System.getenv("KEYSTORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS")
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

### WR-02: `PauseActivity` calls `super.onCreate` in the fail-closed branch — FlutterEngine binds before `finish()`

**File:** `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt:49-51`

**Issue:** When Intent extras are invalid, the fail-closed branch calls `super.onCreate(savedInstanceState)` (line 49) and then `finish()` (line 50). Calling `super.onCreate` on a `FlutterActivity` triggers `provideFlutterEngine()` (line 57-63), which retrieves (or creates) a `FlutterEngine` and begins Dart execution. The engine is bound before `finish()` is called. This means:

1. The cached `"pause_engine"` is consumed / held for the duration of the early-destroy lifecycle.
2. Dart code (including the router redirect logic) begins executing against a screen that is already finishing. While `getInitialRoute()` never returns a valid route in the fail-closed path (because it uses `entryId = -1L`), this still runs more engine lifecycle than necessary.
3. If `FlutterEngineCache` does not hold the engine (cache miss), a fresh engine is allocated and discarded.

The comment `// no engine bind` at line 37 is inaccurate.

**Fix:** Call `finish()` before `super.onCreate` in the fail-closed path, or avoid calling `super.onCreate` entirely:

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    setShowWhenLocked(true)
    setTurnScreenOn(true)

    entryId = intent.getLongExtra("extra_entry_id", -1L)
    blockedPackage = intent.getStringExtra("extra_blocked_package") ?: ""
    blockMode = intent.getStringExtra("extra_block_mode") ?: ""
    triggeredAtMs = intent.getLongExtra("extra_triggered_at_ms", 0L)

    if (entryId == -1L ||
        blockedPackage.isEmpty() ||
        (blockMode != "soft" && blockMode != "hard") ||
        triggeredAtMs <= 0L
    ) {
        // Do NOT call super.onCreate — avoids binding the FlutterEngine.
        finish()
        return
    }

    super.onCreate(savedInstanceState)
}
```

`finish()` without `super.onCreate` is legal on Android: the Activity is created in CREATED state by the system, and calling `finish()` immediately skips all engine setup.

---

### WR-03: `_writeOutcomeAndClose` calls `ref.read()` on an auto-disposed controller — `StateError` on Activity kill

**File:** `lib/features/pause/controllers/pause_controller.dart:80` and `46`

**Issue:** When the cooldown timer fires and calls `unawaited(_writeOutcomeAndClose(outcome: 0))`, the returned `Future` is not retained. If `PauseActivity` is killed (back-press, OEM memory reclaim, or the user explicitly navigates away) while this future is in-flight, Riverpod's `autoDispose` fires `ref.onDispose(_cancelTimer)` and tears down the provider container. When the floating future resumes at `ref.read(pauseEventRepositoryProvider)` (line 80), Riverpod 3.x throws a `StateError: "Cannot use ref after it was disposed"`. This is an unhandled exception on the isolate's event loop that will be reported as a crash in Play Console vitals.

This path is most likely to be triggered on the REL-04 overnight test on Samsung devices with aggressive background process management.

**Fix:** Either (a) `await` the call so disposal waits for it, or (b) read the repository before entering the async gap:

```dart
// Option B — read repo eagerly, before it can be disposed:
Future<void> _writeOutcomeAndClose({required int outcome}) async {
  if (state.isComplete) return;
  // Read the repo synchronously while ref is guaranteed alive.
  final repo = ref.read(pauseEventRepositoryProvider);
  await repo.insertOutcome(
    entryId: _arg.entryId,
    packageName: _arg.packageName,
    triggeredAt: _arg.triggeredAt,
    outcome: outcome,
    cooldownChosenSeconds: state.cooldownChosenSeconds,
  );
  state = state.copyWith(isComplete: true);
  await Future<void>.delayed(const Duration(milliseconds: 1500));
  await _arg.onClose();
}
```

`ref.read()` occurs before the first `await`, so the provider container is still alive. If the container is disposed before `_cancelTimer` has a chance to run (extremely rare), the timer callback itself would also call `state = state.copyWith(...)` which would also throw — this requires the same guard in `startCooldown`'s timer callback.

---

### WR-04: Kotlin DST parity test comment falsely claims `America/Los_Angeles` timezone — misleads future maintainers

**File:** `test/domain/schedule/schedule_window_parity_test.dart:33` and `430`

**Issue:** The Dart parity test comment at lines 33 and 430 states: "The Kotlin counterpart uses `TimeZone.getTimeZone("America/Los_Angeles")` to test true DST behavior." However, `ScheduleWindowTest.kt` uses `TimeZone.getDefault()` throughout — including in GROUP 5 (DST tuples). This means the Kotlin DST tests do NOT use a pinned timezone. They will produce correct results on any machine (because epoch construction and evaluation use the same default TZ), but they do not exercise actual DST edge cases: the spring-forward 02:00-03:00 gap is invisible because the `ms()` helper accepts local calendar values, not UTC offsets.

This false comment creates a maintenance hazard: a future engineer may believe the Kotlin DST tests are pinned and expect CI failures only on Pacific-TZ machines, whereas in reality the tests pass everywhere with no actual DST coverage.

**Fix:** Update the comments in both files to accurately describe what the tests do:

In `test/domain/schedule/schedule_window_parity_test.dart` lines 33 and 430, replace:
```
// The Kotlin counterpart uses TimeZone.getTimeZone("America/Los_Angeles") explicitly.
```
with:
```
// The Kotlin counterpart also uses TimeZone.getDefault() (local TZ), not a pinned
// Pacific timezone. Both sides are locally-consistent but neither exercises real
// DST wall-clock gaps/folds. True DST testing would require pinned TZ + epoch math.
```

---

### WR-05: `PauseController` has no unit test for auto-complete drain path (outcome=0) — the only `insertOutcome` call path that uses `unawaited`

**File:** `test/features/pause/pause_controller_test.dart:54-90`

**Issue:** The PAUS-04 test group (`'cooldown drain auto-completes outcome=0'`) explicitly acknowledges: "The real drain test relies on real `Timer.periodic` (100ms ticks) which is integration-level; we verify the plumbing here." The test only checks that `startCooldown` sets `cooldownChosenSeconds` and disposes cleanly — it does NOT verify that `insertOutcome(outcome: 0)` is called when the timer reaches zero. This is the only outcome path that uses `unawaited()`, making it the most likely to silently regress (especially with the CR-02 double-write defect above).

Flutter test provides `fakeAsync` + `FakeAsync.elapse` for testing `Timer.periodic` without real time. The test can verify the full drain in a single synchronous `fakeAsync` block.

**Fix:**
```dart
test('timer drain to zero writes exactly one outcome=0 row', () {
  fakeAsync((fake) {
    final args = (..., onClose: () async {});
    final container = buildContainer(mockRepo: mockRepo, args: args);
    addTearDown(container.dispose);
    final controller = container.read(pauseControllerProvider(args).notifier);

    controller.startCooldown(60); // 60 seconds = 600 ticks of 100ms

    // Advance time by slightly over 60 seconds so every timer tick fires.
    fake.elapse(const Duration(milliseconds: 60100));

    // DB write must have been called exactly once with outcome=0.
    verify(() => mockRepo.insertOutcome(
      entryId: any(named: 'entryId'),
      packageName: any(named: 'packageName'),
      triggeredAt: any(named: 'triggeredAt'),
      cooldownChosenSeconds: 60,
      outcome: 0,
    )).called(1);

    container.dispose();
  });
});
```

---

## Info

### IN-01: `int.parse!` on route path parameter — unguarded `FormatException` if URL is manually crafted

**File:** `lib/core/router/app_router.dart:48`

**Issue:** `int.parse(state.pathParameters['entryId']!)` will throw a `FormatException` if `entryId` is not a valid integer. In production this path is only reached via `PauseActivity.getInitialRoute()` which always provides a valid `Long` value. However, if the app is ever deep-linked directly (e.g., from adb or a future notification) with a non-numeric segment, the exception propagates uncaught through GoRouter's builder and surfaces as an unhandled error.

**Fix:** Use `int.tryParse` with a safe fallback, consistent with the `triggeredAt` parameter handling on line 52:
```dart
entryId: int.tryParse(state.pathParameters['entryId'] ?? '') ?? 0,
```
Also apply the same fix to `/list/edit/:id` (line 43).

---

### IN-02: Activity kill during active cooldown leaves no `pause_events` row — undocumented data-loss edge case

**File:** `lib/features/pause/controllers/pause_controller.dart:21` (onDispose) and `lib/features/pause/controllers/pause_controller.dart:41-50` (timer)

**Issue:** If `PauseActivity` is killed (OEM memory pressure, back button, recent-apps swipe) while a cooldown is running, `ref.onDispose(_cancelTimer)` fires, the timer is cancelled, and no `pause_events` row is ever written. The "insert at end" strategy (D-13) is documented but the consequence — a silently dropped session — is not noted anywhere as an accepted trade-off. This is most relevant to the REL-04 overnight test: if the Samsung device kills the Activity during a cooldown, the session disappears from `cumulativeTotalsProvider`.

**Fix (documentation only):** Add a comment to `_cancelTimer` / `onDispose` noting that in-flight cooldowns produce no DB row on Activity destruction — confirm this is intentional per D-13 spec.

---

### IN-03: `blockListEntryProvider` uses `ref.read` inside a `FutureProvider` — stale-data risk on list changes

**File:** `lib/features/pause/providers/pause_providers.dart:34-37`

**Issue:** `blockListEntryProvider` is a `FutureProvider.autoDispose.family` that calls `ref.read(blockListRepoProvider)` (not `ref.watch`). Using `ref.read` inside a provider body means the provider will not rebuild if `blockListRepoProvider` is replaced (e.g., during testing via `overrideWith`) and will not pick up changes to the block-list entry after the initial load. In practice the `PauseScreen` is short-lived and the entry is unlikely to change during a pause session, but using `ref.watch` is the correct Riverpod pattern for dependencies inside a provider.

**Fix:**
```dart
final FutureProviderFamily<BlockListData?, int> blockListEntryProvider =
    FutureProvider.autoDispose.family<BlockListData?, int>((ref, id) {
  final repo = ref.watch(blockListRepoProvider); // watch, not read
  return repo.getById(id);
});
```

---

### IN-04: `test/platform/accessibility_api_test.dart` is a placeholder with a skipped test

**File:** `test/platform/accessibility_api_test.dart:14-21`

**Issue:** The file contains a single `test('placeholder', () {}, skip: '...')`. This contributes to the test count without providing any coverage. The class `MockAccessibilityApi` is defined and exported for reuse, which is valuable, but the test group itself will always be reported as "1 skipped" and could be mistaken for actual coverage.

**Fix:** Either remove the `main()` body (leaving only the mock class export) or implement a real test (e.g., verifying `isServiceEnabled()` is callable and returns a `Future<bool>`). If the intent is purely to export the mock class, rename the file to `_mocks.dart` or move it to a shared mocks directory.

---

_Reviewed: 2026-05-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
