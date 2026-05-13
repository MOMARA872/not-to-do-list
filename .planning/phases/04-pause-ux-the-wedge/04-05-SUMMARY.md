---
plan_id: 04-05
phase: 04-pause-ux-the-wedge
plan: 05
subsystem: accessibility-service-wedge
tags: [kotlin, dart, accessibility-service, local-broadcast, pattern-1, d09, d10, d11, paus-10, rel-01, play-02, cd-01]
dependency_graph:
  requires: [04-02, 04-04]
  provides: [accessibility-service-body, service-receiver, schedule-gate, pause-intent-launch, d10-resume-refresh]
  affects: [04-06-pause-activity, 04-07-pause-events, 04-08-final-uat]
tech_stack:
  added:
    - "LocalBroadcastManager usage in service (androidx.localbroadcastmanager already added by 04-04)"
    - "org.json.JSONArray parsing in BlockListReceiver (Android-bundled, zero new dep)"
  patterns:
    - "Pattern 1: service reads in-memory Map<String, ScheduleSlice> only — ZERO SQLite access from event thread"
    - "800ms per-package debounce via Map<String, Long> lastFiredAtMs on event thread"
    - "Atomic @Volatile blockMap replace from BlockListReceiver binder thread"
    - "Schedule gate: isInScheduleWindow(nowEpochMs, start, end, mask) from Plan 04-02 Kotlin port"
    - "D-10 resume refresh: AppLifecycleState.resumed -> republishCurrent() -> Pigeon -> LocalBroadcast -> service"
key_files:
  created: []
  modified:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt
    - lib/features/health/widgets/_health_lifecycle_observer.dart
decisions:
  - "Used inner class BlockListReceiver (not object) so it can directly access @Volatile blockMap field"
  - "Preserved Phase 1 doc comment verbatim; added imports above comment to keep PLAY-02 within head -26"
  - "Used unawaited(republishCurrent()) in observer — matches existing unawaited(refresh()) pattern for fire-and-forget lifecycle hooks"
  - "No Kotlin-side onResume override in MainActivity — Dart-side observer fires on every resume (including post-settings) with correct timing after engine is booted"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-10"
  tasks: 2
  files: 2
---

# Phase 4 Plan 05: Wave 2 — AccessibilityService body fill + Intent launch (PAUS-01, PAUS-10, REL-01) Summary

TYPE_WINDOW_STATE_CHANGED handler with 800ms debounce, in-memory ScheduleSlice map refreshed via LocalBroadcast receiver, PAUS-10 schedule gate via Plan 04-02's Kotlin port, and PauseActivity Intent launch — the wedge fires for the first time.

## Performance

- **Duration:** ~20 minutes
- **Completed:** 2026-05-10
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

**Task 04-05-01 — Fill NotToDoAccessibilityService.kt body** (commit `0eb2870`)

- Replaced Phase 1 stub body with production implementation (~145 lines including preserved doc comment)
- Phase 1 doc comment (lines 1-26) preserved verbatim; PLAY-02 appears at line 26 within `head -26` check
- `onServiceConnected`: registers `BlockListReceiver` via `LocalBroadcastManager.getInstance(this).registerReceiver(...)` + single `Log.d(TAG, "service connected")` (T-04 discipline)
- `onAccessibilityEvent`: 5-step hot path — null guard, TYPE_WINDOW_STATE_CHANGED filter, pkg null guard, blockMap lookup, 800ms debounce, PAUS-10 schedule gate, lastFiredAtMs update, PauseActivity Intent with 4 lowercase_snake extras + `FLAG_ACTIVITY_NEW_TASK`
- `onDestroy`: unregisters receiver
- `ScheduleSlice` private data class carrying entryId, blockMode, startMinutes?, endMinutes?, weekdayMask?
- `BlockListReceiver` inner class: parses JSON snapshot into fresh Map, wraps in try/catch fail-safe (T-4-05-07), atomically replaces `@Volatile blockMap`
- All acceptance greps green: PLAY-02 (0 forbidden tokens), CD-01 (0 FGS tokens), D-13 (0 DB imports)
- `./gradlew :app:compileDebugKotlin` exits 0 (2 deprecation warnings from LocalBroadcastManager — pre-existing, same as BlocklistBroadcastApiImpl)

**Task 04-05-02 — Augment HealthLifecycleObserver with republishCurrent()** (commit `c57e852`)

- Added `blockListRepoProvider` import to `lib/features/health/widgets/_health_lifecycle_observer.dart`
- Added `unawaited(ref.read(blockListRepoProvider).republishCurrent())` in the `AppLifecycleState.resumed` branch, after existing `permissionHealthProvider.refresh()` call
- No new observer file created — existing Phase 2 observer augmented (Karpathy Simplicity First)
- `flutter analyze lib/features/health/widgets/_health_lifecycle_observer.dart` — 0 issues
- D-10 resume-refresh chain is now closed end-to-end

## Verification Results

- `flutter test test/policy/play_invariants_test.dart` — 8/8 PASS
- `flutter test test/features/health/` — 23/23 PASS (1 skip: Plan 04-08 live a11y test)
- `flutter test --timeout 30s` — 367 PASS, 18 skip, 0 fail (pre-existing perf test `dashboard_render_test.dart` is in skip set)
- `flutter build apk --debug` — exits 0; APK at `build/app/outputs/flutter-apk/app-debug.apk`
- `./gradlew :app:compileDebugKotlin` — BUILD SUCCESSFUL (2 pre-existing deprecation warnings, 0 errors)
- PLAY-02 absence-grep: `grep -cE 'performAction\(|performGlobalAction\(|dispatchGesture\('` on service file = 0
- CD-01 absence-grep: `grep -cE 'startForeground\(|NotificationCompat\.Builder|FOREGROUND_SERVICE'` on service file = 0
- D-13 absence-grep: `grep -cE 'Drift|\bsqlite\b|AppDatabase|getDao\('` on service file = 0
- head-26 PLAY-02 check: count = 1 (≥1 required)

## Deviations from Plan

None — plan executed exactly as written.

The Phase 1 doc comment shift (PLAY-02 moved from line 18 in original to line 26 in filled file due to 9 additional imports) is expected and intentional. The `head -26` acceptance check still passes at line 26.

The LocalBroadcastManager deprecation warnings in Kotlin are pre-existing from Plan 04-04's `BlocklistBroadcastApiImpl.kt` and appear in the service file for the same reason — the D-10 design uses LocalBroadcastManager by plan (T-01 mitigation; in-process only). These are warnings, not errors; the plan acknowledges and accepts them.

## Known Stubs

None — both artifacts are fully implemented.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes. The service uses explicit-component Intent launch `Intent(this, PauseActivity::class.java)` (T-4-05-03 mitigated). The BlockListReceiver uses LocalBroadcastManager (T-4-05-01 mitigated by in-process delivery + Plan 04-04's setPackage).

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 04-05-01 | `0eb2870` | feat(04-05-01): fill NotToDoAccessibilityService body — TYPE_WINDOW_STATE_CHANGED handler |
| 04-05-02 | `c57e852` | feat(04-05-02): augment HealthLifecycleObserver with republishCurrent() on resume |

## Self-Check: PASSED

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt` — FOUND
- `lib/features/health/widgets/_health_lifecycle_observer.dart` — FOUND
- `.planning/phases/04-pause-ux-the-wedge/04-05-SUMMARY.md` — FOUND
- `0eb2870` feat(04-05-01) — FOUND in git log
- `c57e852` feat(04-05-02) — FOUND in git log
