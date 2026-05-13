---
plan_id: 04-04
phase: 4
plan: 04
subsystem: platform-broadcast
tags: [pigeon, local-broadcast, kotlin, dart, riverpod, repository-pattern, d10]
dependency_graph:
  requires: [04-03]
  provides: [blocklist-broadcast-channel, repository-emit-hook, accessibility-detector-body]
  affects: [04-05-service-receiver, 04-06-pause-activity]
tech_stack:
  added:
    - "BlocklistBroadcastApi Pigeon HostApi (3rd channel in project after PermissionStatusApi, UsageApi)"
    - "androidx.localbroadcastmanager:localbroadcastmanager:1.1.0 (build.gradle.kts)"
    - "org.json.JSONObject (Android-bundled, zero new dep — JSON serialization for snapshot)"
  patterns:
    - "D-10 LocalBroadcast emit: Repository write → Pigeon channel → Kotlin LocalBroadcastManager.sendBroadcast()"
    - "T-01 mitigation: Intent.setPackage(context.packageName) + LocalBroadcastManager in-process"
    - "T-04 mitigation: no reason PII in snapshot DTO (entryId+packageName+blockMode+schedule only)"
    - "REL-05 preserved: detections = Stream.empty(); consumer is Intent path not stream"
    - "Lazy snapshotProvider closure in blockedAppDetectorProvider prevents eager DB init in tests"
key_files:
  created:
    - pigeons/blocklist_broadcast_api.dart
    - lib/platform/blocklist_broadcast_api.g.dart
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/BlocklistBroadcastApi.g.kt
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/BlocklistBroadcastApiImpl.kt
    - lib/domain/providers/accessibility_api_provider.dart
    - lib/domain/providers/blocklist_broadcast_provider.dart
  modified:
    - lib/data/repositories/block_list_repository.dart
    - lib/data/detectors/accessibility_blocked_app_detector.dart
    - lib/domain/providers/blocked_app_detector_provider.dart
    - lib/domain/providers/block_list_repo_provider.dart
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt
    - android/app/build.gradle.kts
    - test/data/repositories/blocklist_broadcast_test.dart
    - test/data/detectors/accessibility_blocked_app_detector_test.dart
decisions:
  - "Used org.json.JSONObject (Android-bundled) for snapshot serialization — zero new Kotlin dep, handles null fields cleanly via putOpt()"
  - "BlocklistBroadcastApi? broadcaster nullable in BlockListRepository constructor for Phase 2 test backward compat — production provider always passes non-null (T-4-04-04 accept)"
  - "snapshotProvider is a lazy Dart closure in blockedAppDetectorProvider — prevents eager DB init in tests that only check detector type (REL-05 test maintained)"
  - "PLAY-02 forbidden tokens removed from Dart comments in accessibility_blocked_app_detector.dart after play_invariants_test.dart scanned the literal text and failed"
metrics:
  duration: "~45 minutes"
  completed: "2026-05-10"
  tasks: 3
  files: 14
---

# Phase 4 Plan 04-04: BlocklistBroadcast Pigeon channel + Repository emit + Detector fill Summary

Ships the publisher half of the D-10 LocalBroadcast contract end-to-end: Dart BlockListRepository writes → BlocklistBroadcastApi Pigeon channel → Kotlin BlocklistBroadcastApiImpl sends `com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED` via LocalBroadcastManager, with T-01 defense-in-depth via `Intent.setPackage()`.

## What Was Built

**Task 04-04-01 — Pigeon schema + codegen** (commit `5ddbacb`)

- Created `pigeons/blocklist_broadcast_api.dart` with `BlockListEntrySnapshot` DTO (6 fields: entryId, packageName, blockMode, scheduleStartMinutes?, scheduleEndMinutes?, scheduleWeekdayMask?) and `@HostApi() BlocklistBroadcastApi.publishBlockList(List<BlockListEntrySnapshot>)`
- Ran `dart run pigeon --input pigeons/blocklist_broadcast_api.dart` to generate both bindings
- Generated files land at `lib/platform/blocklist_broadcast_api.g.dart` and `android/.../platform/BlocklistBroadcastApi.g.kt`
- No other pigeon files touched (Pitfall #9 from Phase 3 preserved)
- 8/8 PLAY-* invariants green post-codegen

**Task 04-04-02 — BlocklistBroadcastApiImpl.kt + MainActivity registration** (commit `3bb12af`)

- Created `BlocklistBroadcastApiImpl.kt` implementing the Pigeon HostApi
- `companion object const val ACTION_BLOCKLIST_UPDATED = "com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED"` — qualified action string (T-01)
- `companion object const val EXTRA_BLOCKLIST_SNAPSHOT_JSON = "extra_blocklist_snapshot_json"`
- Serializes snapshot via `org.json.JSONArray` + `putOpt()` for nullable schedule fields
- `Intent(ACTION_BLOCKLIST_UPDATED).setPackage(context.packageName)` — defense-in-depth scope narrowing
- `LocalBroadcastManager.getInstance(context).sendBroadcast(intent)` — Pattern 1 in-process broadcast
- Added `implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")` inside existing `dependencies {}` block in `build.gradle.kts`
- Registered `BlocklistBroadcastApi.setUp(messenger, BlocklistBroadcastApiImpl(applicationContext))` in `MainActivity.configureFlutterEngine` after AccessibilityApi.setUp

**Task 04-04-03 — Dart providers + Repository emit + Detector fill + tests** (commit `1419ffe`)

- Created `lib/domain/providers/accessibility_api_provider.dart` — `Provider<AccessibilityApi>` (hand-written, mirrors permission_status_api_provider.dart shape)
- Created `lib/domain/providers/blocklist_broadcast_provider.dart` — `Provider<BlocklistBroadcastApi>` (hand-written)
- Augmented `BlockListRepository`:
  - Added optional `BlocklistBroadcastApi? broadcaster` constructor param (nullable for Phase 2 backward compat)
  - Added private `_publishCurrent()` helper that reads app-only entries (kind==0 && packageName!=null), maps to `BlockListEntrySnapshot`, calls `_broadcaster?.publishBlockList()`
  - Added `_publishCurrent()` call at the end of `add`, `updateEntry`, `delete`, `insertMany`
  - Added public `republishCurrent()` → `_publishCurrent()` for D-10 onResume refresh
- Updated `block_list_repo_provider.dart` to pass `ref.read(blocklistBroadcastApiProvider)` as second arg
- Filled `AccessibilityBlockedAppDetector`:
  - Constructor takes `BlocklistBroadcastApi broadcaster`, `AccessibilityApi accessibilityApi`, `Future<List<BlockListEntrySnapshot>> Function() snapshotProvider`
  - `initialize()` + `updateBlockList()` both call `_broadcaster.publishBlockList(await _snapshotProvider())`
  - `detections` → `const Stream<BlockedAppDetection>.empty()` (REL-05 preserved)
  - `isHealthy` → `_accessibilityApi.isServiceEnabled()` (real signal from Plan 04-03)
- Updated `blocked_app_detector_provider.dart` to inject all 3 deps; `snapshotProvider` is a lazy closure (prevents eager DB init during type-only tests)
- Flipped `test/data/repositories/blocklist_broadcast_test.dart` from skip to 3 real tests
- Flipped `test/data/detectors/accessibility_blocked_app_detector_test.dart` from skip to 3 real tests

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PLAY-02 test failure from forbidden tokens in Dart comment**
- **Found during:** Task 04-04-03 verification
- **Issue:** `accessibility_blocked_app_detector.dart` comment verbatim listed `performAction / performGlobalAction / dispatchGesture` — the PLAY-02 test uses `RegExp(r'\bdispatchGesture\s*\(')` which matched `dispatchGesture (the BlockedAppDetector...` (space before `(` matched `\s*`)
- **Fix:** Replaced the comment with `"contains no autonomous-action AccessibilityService APIs"` — no forbidden tokens
- **Files modified:** `lib/data/detectors/accessibility_blocked_app_detector.dart`
- **Commit:** `1419ffe`

**2. [Rule 1 - Bug] Unnecessary null-assertion `_broadcaster!` after null guard**
- **Found during:** dart analyze on `block_list_repository.dart`
- **Issue:** `_broadcaster!.publishBlockList(snapshots)` after `if (_broadcaster == null) return;` — Dart flow analysis already knows it's non-null at that point
- **Fix:** Removed `!` operator
- **Files modified:** `lib/data/repositories/block_list_repository.dart`
- **Commit:** `1419ffe`

**3. [Rule 1 - Bug] HTML angle brackets in doc comment**
- **Found during:** dart analyze on `accessibility_blocked_app_detector.dart`
- **Issue:** `Map<String, ScheduleSlice>` in doc comment triggered `unintended_html_in_doc_comment` info
- **Fix:** Replaced with `Map&lt;String, ScheduleSlice&gt;`
- **Files modified:** `lib/data/detectors/accessibility_blocked_app_detector.dart`
- **Commit:** `1419ffe`

**4. [Rule 2 - Missing critical] Lazy snapshotProvider closure in blockedAppDetectorProvider**
- **Found during:** Task 04-04-03 test run — `blocked_app_detector_provider_test.dart` failed when `blockedAppDetectorProvider` tried to eagerly read `blockListRepoProvider` → `databaseProvider` → path_provider without Flutter binding
- **Issue:** The plan's Step 5 code showed `val repo = ref.read(blockListRepoProvider)` inside the `blockedAppDetectorProvider` build closure, but it was positioned BEFORE the `snapshotProvider` lambda, causing eager evaluation
- **Fix:** Moved `ref.read(blockListRepoProvider)` INSIDE the `snapshotProvider` closure so it's only called when `initialize()` or `updateBlockList()` is actually invoked at runtime (not at provider construction time)
- **Files modified:** `lib/domain/providers/blocked_app_detector_provider.dart`
- **Commit:** `1419ffe`

## Known Issues (Pre-existing, Out of Scope)

`test/perf/dashboard_render_test.dart` (DASH-07) times out after 10 minutes when run via `flutter test` — this is a pre-existing issue from Plan 03-06 (`b770359`), unrelated to this plan. See `03-06-SUMMARY.md` "Deferred Issues: DASH-07 host budget".

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-01 mitigated | BlocklistBroadcastApiImpl.kt | ACTION_BLOCKLIST_UPDATED uses qualified package prefix + setPackage() + LocalBroadcastManager — external apps cannot inject spoofed broadcasts |
| T-04 verified | BlocklistBroadcastApiImpl.kt | `grep reason` returns 0 matches — reason PII never crosses Pigeon boundary |

## Test Results

- `flutter test test/data/repositories/blocklist_broadcast_test.dart` — 3/3 PASS
- `flutter test test/data/detectors/accessibility_blocked_app_detector_test.dart` — 3/3 PASS
- `flutter test test/data/repositories/block_list_repo_test.dart` — 9/9 PASS (Phase 2 backward compat)
- `flutter test test/domain/providers/blocked_app_detector_provider_test.dart` — 3/3 PASS (REL-05 preserved)
- `flutter test test/policy/play_invariants_test.dart` — 8/8 PASS

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 04-04-01 | `5ddbacb` | feat(04-04-01): add BlocklistBroadcastApi Pigeon schema + codegen |
| 04-04-02 | `3bb12af` | feat(04-04-02): add BlocklistBroadcastApiImpl.kt + register in MainActivity |
| 04-04-03 | `1419ffe` | feat(04-04-03): Dart providers + Repository emit + Detector fill + tests |

## Self-Check: PASSED
