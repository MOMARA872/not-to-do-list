# Plan 01-04 — Pigeon HostApi Stubs + BlockedAppDetector (Hand-Written Provider)

**Phase:** 01-foundation-play-declaration
**Plan:** 01-04
**Wave:** 1 (parallel-safe with 01-02 manifest/service and 01-03 Drift schema)
**Completed:** 2026-05-04
**Commits:** `549c580` (initial) + `24086d6` (FlutterError redeclaration fix)

## What landed

Three Pigeon `@HostApi` channel contracts (UsageApi, AccessibilityApi, NotificationApi) at the project root, with codegen producing both Dart shims (`lib/platform/*.g.dart`) and Kotlin abstract interfaces (`android/.../platform/*.g.kt`). `MainActivity.kt` was rewritten to register all three with stub bodies that throw `NotImplementedError` (or return safe defaults) so the APK compiles end-to-end. The REL-05 abstraction shipped: a `BlockedAppDetector` interface with five members (`initialize`, `updateBlockList`, `detections`, `isHealthy`, `dispose`) and zero autonomous-action methods; two concrete stubs (`AccessibilityBlockedAppDetector`, `UsageStatsPollingBlockedAppDetector`) that throw `UnimplementedError`; and a hand-written Riverpod selector that swaps between them based on `useAccessibilityServiceProvider`. A unit test exercises both branches of the swap and asserts PLAY-02 absence at runtime by reading the source file.

## Pinned Pigeon version

`pigeon: 26.3.4` (from `pubspec.lock`). Matches the Plan 01-01 pin (`^26.3.4`).

## Codegen output

`tool/pigeon.sh` ran cleanly:
```
Generating pigeons/accessibility_api.dart...
Generating pigeons/notification_api.dart...
Generating pigeons/usage_api.dart...
Done. Run 'dart format lib/platform/' to format generated Dart.
```

Six output files:

| Source                            | Output                                                                                |
| --------------------------------- | ------------------------------------------------------------------------------------- |
| `pigeons/usage_api.dart`          | `lib/platform/usage_api.g.dart` + `android/.../platform/UsageApi.g.kt`                 |
| `pigeons/accessibility_api.dart`  | `lib/platform/accessibility_api.g.dart` + `android/.../platform/AccessibilityApi.g.kt` |
| `pigeons/notification_api.dart`   | `lib/platform/notification_api.g.dart` + `android/.../platform/NotificationApi.g.kt`   |

## RESEARCH Assumption A1 — generated Kotlin signature

The plan flagged that the exact `UsageApi.queryRange` Kotlin signature could not be predicted before codegen. The actual emitted signature (line 266 of `UsageApi.g.kt`) is:

```kotlin
fun queryRange(startEpochMs: Long, endEpochMs: Long, callback: (Result<List<UsagePackageStat>>) -> Unit)
```

Both epoch-ms parameters resolved to `Long` (matching A1's primary case) and the async return uses callback-style, not suspend. `MainActivity.kt`'s stub registration mirrors this signature exactly:

```kotlin
override fun queryRange(
    startEpochMs: Long,
    endEpochMs: Long,
    callback: (Result<List<UsagePackageStat>>) -> Unit
) {
    callback(Result.failure(NotImplementedError("UsageApi: implemented in Phase 3")))
}
```

`AccessibilityApi.isServiceEnabled(callback: (Result<Boolean>) -> Unit)` and `NotificationApi.scheduleDailyReminder(hour: Long, minute: Long, callback: (Result<Unit>) -> Unit)` followed the same callback pattern; `openAccessibilitySettings()` was emitted as a synchronous `void` (no callback), as expected for non-`@async` Pigeon methods.

Pigeon emits `interface` (not `abstract class`) for its Kotlin output — `MainActivity.kt`'s `object : UsageApi { ... }` syntax works for both. No registration changes were needed beyond the documented template.

## Deviation from plan: hand-written Riverpod providers (no `@riverpod` codegen)

The plan as written assumed `riverpod_annotation` + `riverpod_generator` would be available. Per Plan 01-01's SUMMARY, those packages were dropped because their analyzer-major pins are incompatible with `pigeon 26.3.4` + Flutter 3.41 (`meta 1.17`). The interface contract is unchanged; the provider was rewritten by hand:

```dart
final Provider<bool> useAccessibilityServiceProvider = Provider<bool>(
  (ref) => true,
);

final Provider<BlockedAppDetector> blockedAppDetectorProvider =
    Provider<BlockedAppDetector>((ref) {
      final useA11y = ref.watch(useAccessibilityServiceProvider);
      if (useA11y) {
        return AccessibilityBlockedAppDetector();
      } else {
        return UsageStatsPollingBlockedAppDetector();
      }
    });
```

A plain `Provider<bool>` is sufficient — the test overrides via `provider.overrideWith((ref) => false)`, which is the same swap mechanism a `StateProvider` would use. `StateProvider` was avoided because in Riverpod 3.x it lives only in `package:flutter_riverpod/legacy.dart` (deprecated path); a plain `Provider` keeps the file free of legacy imports.

The plan's `files_modified` listed `lib/domain/providers/blocked_app_detector_provider.g.dart` as an output. **That file was NOT generated** because there is no codegen — the deviation makes it unnecessary. The plan's success criteria are still met: the swap contract works, the test passes, the analyzer is clean.

## Deviation: pigeon `errorClassName` per input (Rule 1 fix)

Each Pigeon-generated `*.g.kt` file declares a top-level `class FlutterError` for use in error wrapping. With all three outputs sharing the single Kotlin package `com.nottodo.not_to_do_list.platform`, kotlinc fails with three "Redeclaration: FlutterError" errors during `flutter build apk --debug`. Fixed by setting a unique `errorClassName` per input — `UsageApiError` / `AccessibilityApiError` / `NotificationApiError` — without splitting the package. Tracked in commit `24086d6`.

## REL-05 unit test

`flutter test test/domain/providers/blocked_app_detector_provider_test.dart -r expanded`:

```
00:00 +0: blockedAppDetectorProvider (REL-05) default flag (true) returns AccessibilityBlockedAppDetector
00:00 +1: blockedAppDetectorProvider (REL-05) flag overridden to false returns UsageStatsPollingBlockedAppDetector
00:00 +2: PLAY-02 enforcement-by-absence in BlockedAppDetector blocked_app_detector.dart declares no autonomous-action methods
00:00 +3: All tests passed!
```

Three tests: the two REL-05 swap-contract tests cover both branches (`overrideWith((ref) => false)` flips the concrete type), and the PLAY-02 test reads `lib/domain/blocked_app_detector.dart` at runtime and asserts no method declarations match `\bperformAction\s*\(`, `\bperformGlobalAction\s*\(`, or `\bdispatchGesture\s*\(`. Future Phase 4 changes that try to add autonomous-action methods to the interface will fail this test.

Full-suite `flutter test` exits 0 with 6 tests total (3 from this plan + 3 from Plan 01-03's Drift round-trip).

## PLAY-02 absence-enforcement evidence

All four target files passed strict substring checks (the user task spec asked for the strictest interpretation):

| File                                                      | Substring grep result                |
| --------------------------------------------------------- | ------------------------------------ |
| `lib/domain/blocked_app_detector.dart`                    | clean (no substring at all)         |
| `pigeons/usage_api.dart`                                  | clean                                |
| `pigeons/accessibility_api.dart`                          | clean                                |
| `pigeons/notification_api.dart`                           | clean                                |
| `android/.../MainActivity.kt`                             | clean                                |

The interface KDoc was rephrased to say "any autonomous-action APIs (the AccessibilityService capabilities that click, type, navigate, or fire gestures on the user's behalf)" instead of naming the methods directly — this satisfies the strictest grep while preserving the "what these are" context for downstream readers.

## APK build evidence

`flutter build apk --debug` exits 0:

```
Running Gradle task 'assembleDebug'...                              4.1s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

Artifact: `build/app/outputs/flutter-apk/app-debug.apk` (153 MB debug build). This satisfies V3 from RESEARCH §10.

## REQ-IDs satisfied

- **PLAY-02 (no autonomous-action APIs)**: enforced by absence in the BlockedAppDetector interface, the Pigeon contracts, and MainActivity.kt; verified by both static greps and the runtime test.
- **REL-05 (swappable detector source)**: the `Provider<BlockedAppDetector>` selector reads `useAccessibilityServiceProvider` and returns one of two concrete types; the unit test exercises both branches via `overrideWith`.

## Files of record

| File                                                                                        | State                                                          |
| ------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `pigeons/usage_api.dart`                                                                    | New (Pigeon @HostApi input, with `errorClassName: UsageApiError`) |
| `pigeons/accessibility_api.dart`                                                            | New (with `errorClassName: AccessibilityApiError`)              |
| `pigeons/notification_api.dart`                                                             | New (with `errorClassName: NotificationApiError`)               |
| `tool/pigeon.sh`                                                                            | New (executable)                                               |
| `lib/platform/usage_api.g.dart`                                                             | Generated, committed                                           |
| `lib/platform/accessibility_api.g.dart`                                                     | Generated, committed                                           |
| `lib/platform/notification_api.g.dart`                                                      | Generated, committed                                           |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt`             | Generated, committed                                           |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt`     | Generated, committed                                           |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApi.g.kt`      | Generated, committed                                           |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt`                    | Replaced with Pigeon stub registrations                        |
| `lib/domain/blocked_app_detector.dart`                                                      | New (REL-05 interface, PLAY-02 by absence)                     |
| `lib/data/detectors/accessibility_blocked_app_detector.dart`                                | New (Phase-4 stub)                                             |
| `lib/data/detectors/usage_stats_polling_blocked_app_detector.dart`                          | New (kill-switch fallback stub)                                |
| `lib/domain/providers/blocked_app_detector_provider.dart`                                   | New (hand-written Riverpod selector — deviation)               |
| `test/domain/providers/blocked_app_detector_provider_test.dart`                             | New (3 tests: 2 swap + 1 PLAY-02 absence)                      |

`lib/domain/providers/blocked_app_detector_provider.g.dart` from the plan's `files_modified` list was intentionally NOT created — see deviation section above.

## Notes for downstream plans

- **Phase 3 (UsageApi)**: replace the `MainActivity.kt` stub for `UsageApi.queryRange` with a real implementation calling `UsageStatsManager.queryUsageStats(...)`. The Kotlin signature `fun queryRange(startEpochMs: Long, endEpochMs: Long, callback: (Result<List<UsagePackageStat>>) -> Unit)` is locked.
- **Phase 4 (AccessibilityService)**: replace `AccessibilityBlockedAppDetector.initialize/updateBlockList/detections/isHealthy/dispose` bodies. Honor the PLAY-02 promise — the broadcast wiring must NOT add `performAction`-style methods to the interface, only to the native service file.
- **Phase 5 (Notifications)**: replace the `MainActivity.kt` stub for `NotificationApi.scheduleDailyReminder` with `AlarmManager.setExactAndAllowWhileIdle(...)`. The Kotlin signature is locked.
- **Future ecosystem unblock**: when analyzer 12+ converges, reintroduce `riverpod_annotation`/`riverpod_generator` (Plan 01-01's "Notes for downstream plans") and migrate `blocked_app_detector_provider.dart` to `@riverpod` codegen. The interface contract stays identical.
- **Pigeon `errorClassName`**: any future `@HostApi` input MUST set a unique `errorClassName` (or live in its own Kotlin sub-package). Re-running `tool/pigeon.sh` is idempotent; no manual cleanup needed.

---

*Plan 01-04 complete. Wave-2 gate (Plan 01-05) is unblocked once 01-02 (manifest + service) finishes its parallel work.*
