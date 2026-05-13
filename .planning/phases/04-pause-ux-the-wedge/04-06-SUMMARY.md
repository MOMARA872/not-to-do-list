---
phase: 04-pause-ux-the-wedge
plan: 06
subsystem: pause-activity-android
tags: [kotlin, android, flutter-activity, flutter-engine-cache, lock-screen, intent-extras, fail-closed, paus-07, paus-08, d-14, d-15, t-02, t-03]

requires:
  - phase: 04-03
    provides: FlutterEngine pre-warmed under cache key "pause_engine" in MainActivity.onCreate
  - phase: 04-05
    provides: PauseActivity Intent contract — 4 lowercase_snake extras (extra_blocked_package, extra_entry_id, extra_block_mode, extra_triggered_at_ms)
provides:
  - PauseActivity.kt onCreate body — lock-screen flags, fail-closed extras validation, cached engine binding
  - provideFlutterEngine override — FlutterEngineCache.getInstance().get("pause_engine")
  - getInitialRoute override — /pause/{entryId}?package=...&mode=...&triggeredAt=...
affects: [04-07-pause-screen-ui, 04-08-final-uat-verification]

tech-stack:
  added: []
  patterns:
    - "setShowWhenLocked(true) + setTurnScreenOn(true) BEFORE super.onCreate — window flags must be set before window attachment at super.onCreate (D-15)"
    - "T-02 fail-closed: validate all 4 intent extras, call super.onCreate + finish() + return on any failure — no engine bind, no route, no DB write"
    - "provideFlutterEngine returns cached engine via FlutterEngineCache.getInstance().get(key) with super fallback for cache miss"
    - "getInitialRoute returns /pause/$entryId + query string from validated extras — GoRouter reads route on first engine attach"

key-files:
  created: []
  modified:
    - android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt

key-decisions:
  - "Fail-closed branch calls super.onCreate before finish() — Activity API requires super.onCreate before finish() to avoid runtime exception"
  - "Intent extra keys remain string literals matching Plan 04-05's putExtra calls — no shared constants file per Karpathy Simplicity First"
  - "provideFlutterEngine falls back to super (fresh engine) on cache miss — functionally correct, slower cold-start, acceptable v1 trade-off"
  - "Uri.encode(blockedPackage) in route string — defense-in-depth against package names with special characters in GoRouter path"

requirements-completed: [PAUS-07, PAUS-08]

duration: ~10 minutes
completed: 2026-05-10
---

# Phase 4 Plan 06: Wave 3 — PauseActivity.kt onCreate body (PAUS-07, PAUS-08) Summary

PauseActivity filled with lock-screen flags before super.onCreate, T-02 fail-closed extras validation, FlutterEngineCache binding to the pre-warmed "pause_engine" key, and /pause/:entryId initial route handoff.

## Performance

- **Duration:** ~10 minutes
- **Completed:** 2026-05-10
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

**Task 04-06-01 — Fill PauseActivity.kt onCreate body + provideFlutterEngine + getInitialRoute** (commit `ed53fc9`)

- Phase 1 doc comment (lines 1-17) preserved verbatim per plan specification
- `onCreate`: `setShowWhenLocked(true)` + `setTurnScreenOn(true)` called BEFORE `super.onCreate(savedInstanceState)` — D-15 / PAUS-08 order constraint
- T-02 fail-closed validation: reads all 4 intent extras and calls `super.onCreate + finish() + return` on any invalid/missing extra — no engine bind, no route, no pause_events write
- `provideFlutterEngine`: returns `FlutterEngineCache.getInstance().get("pause_engine")` (D-14 / PAUS-07) with `super.provideFlutterEngine(context)` fallback on cache miss
- `getInitialRoute`: builds `/pause/$entryId?package=${Uri.encode(pkg)}&mode=$blockMode&triggeredAt=$triggeredAtMs` for Plan 04-07's GoRouter handler
- All acceptance greps green: PLAY-02 (0 forbidden tokens in non-comment lines), D-13 (0 DB imports), T-03 (manifest exported=false verified + unchanged)
- `./gradlew :app:compileDebugKotlin` BUILD SUCCESSFUL
- `flutter build apk --debug` exits 0
- `flutter test test/policy/play_invariants_test.dart` — 8/8 PASS

## Task Commits

| Task | Commit | Message |
|------|--------|---------|
| 04-06-01 | `ed53fc9` | feat(04-06): fill PauseActivity onCreate — lock-screen flags, fail-closed extras validation, cached engine binding, initial route |

## Files Created/Modified

- `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt` — 18 lines (Phase 1 stub) → 76 lines; Phase 1 doc comment preserved verbatim; added onCreate, provideFlutterEngine, getInitialRoute overrides

## Decisions Made

- Fail-closed branch calls `super.onCreate` before `finish()` — Activity API contract requires super.onCreate to be called first; the engine never attaches because finish() causes immediate activity teardown before the Dart engine executes any code.
- No shared constants file for Intent extra keys — the wire contract is the string literal; Karpathy Simplicity First.
- `Uri.encode(blockedPackage)` applied in route construction — defense-in-depth against edge cases in GoRouter path parsing.

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `setShowWhenLocked(true)` appears before `super.onCreate` in file: `awk` returns "OK"
- `grep -F 'finish()'` + context shows fail-closed branch with entryId == -1L condition
- `grep -F 'android:exported="false"'` on manifest: 2 matches (PauseActivity + AccessibilityService)
- `awk '/android:name=".PauseActivity"/,/\/>/' ... | grep 'exported="false"'`: match found
- `git diff android/app/src/main/AndroidManifest.xml`: empty (manifest unchanged)
- `./gradlew :app:compileDebugKotlin`: BUILD SUCCESSFUL
- `flutter build apk --debug`: exits 0
- `flutter test test/policy/play_invariants_test.dart`: 8/8 PASS
- PLAY-02 absence-grep on PauseActivity.kt: 0 matches
- DB token absence-grep on PauseActivity.kt: 0 matches

## Known Stubs

None — PauseActivity is fully implemented for its Phase 4 responsibilities. Plan 04-07 will wire the Flutter GoRouter `/pause/:entryId` route handler (Dart side); Plan 04-08 will measure cold-start and record in 04-VERIFICATION.md.

## Threat Flags

No new network endpoints or auth paths introduced. PauseActivity is reached only via in-process AccessibilityService Intent (android:exported="false", T-03). The T-02 fail-closed validation prevents malformed Intents from triggering engine binding or pause_events writes.

## Next Phase Readiness

- PauseActivity is a fully functional lock-screen-aware FlutterActivity bound to the pre-warmed engine
- Plan 04-07 (Flutter pause-screen UI / GoRouter route) can now render against this activity
- Plan 04-08 can install the APK, trigger a block, and measure cold-start for the PAUS-07 <300ms budget

---
*Phase: 04-pause-ux-the-wedge*
*Completed: 2026-05-10*
