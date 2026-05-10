---
phase: 04
phase_name: pause-ux-the-wedge
kind: overview
total_plans: 8
total_waves: 5
mode: standard
mvp_mode: false
walking_skeleton: false
tdd_mode: false
requirements:
  - PAUS-01
  - PAUS-02
  - PAUS-03
  - PAUS-04
  - PAUS-05
  - PAUS-06
  - PAUS-07
  - PAUS-08
  - PAUS-09
  - PAUS-10
  - REL-01
  - REL-04
locked_decisions:
  - D-01: "Calm/mindful hybrid — forest-green seed (0xFF2D6A4F), M3 dynamicColor=false, no breathing animation, no red/stop iconography, no app icon at top."
  - D-02: "Reason present → italic/serif quote-card hero (M3 HeadlineSmall + quote glyphs)."
  - D-03: "Reason empty → blocked-app display name as hero (M3 DisplayMedium, e.g., 'Instagram.'); no quote-card chrome, no app icon, no puppet-voice copy."
  - D-04: "Cooldown selector = M3 SegmentedButton chips [1m] [3m] [5m] [10m] (no default pre-selection, tapping different chip restarts at new duration; no +Custom)."
  - D-05: "Countdown = thin LinearProgressIndicator pinned to top edge + small caption 'X:XX remaining' below selected chip."
  - D-06: "Asymmetric buttons — Cancel = M3 FilledButton (primary); Use anyway = TextButton beside Cancel; Use anyway is omitted entirely from widget tree for hard entries."
  - D-07: "Auto-close = brief '✓ Cooldown complete' card (~1.5s) then PauseActivity.finish(); pause_events row written outcome=0 BEFORE confirmation card renders."
  - D-08: "No copy that puts words in user's mouth; only fixed copy is 'Cooldown:', '1m'/'3m'/'5m'/'10m', 'X:XX remaining', 'Cancel', 'Use anyway', '✓ Cooldown complete'."
  - D-09: "Service observes TYPE_WINDOW_STATE_CHANGED only; 800ms per-package debounce."
  - D-10: "Block-list refresh via LocalBroadcast 'com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED'; service NEVER reads SQLite; Dart re-sends initial set on MainActivity.onResume."
  - D-11: "Service launches Intent(this, PauseActivity::class.java) with FLAG_ACTIVITY_NEW_TASK and 4 lowercase_snake extras: extra_blocked_package, extra_entry_id, extra_block_mode, extra_triggered_at_ms."
  - D-12: "Schedule gate via Kotlin port of isInScheduleWindow (~30 lines, byte-for-byte parity with Dart); shipped with schedule_window_parity_test.dart that exercises Dart and a Process-spawn (or pure-Kotlin via JVM unit test) parity oracle."
  - D-13: "pause_events writer = Dart only (PauseActivity Flutter side); insert-at-session-end with final outcome (planner picks insert-at-end over insert-at-start to avoid UPDATE-by-id race when activity is killed mid-cooldown)."
  - D-14: "FlutterEngineCache pre-warm in MainActivity.onCreate() under cache key 'pause_engine'; PauseActivity.withCachedEngine('pause_engine')."
  - D-15: "PauseActivity.onCreate() calls setShowWhenLocked(true) + setTurnScreenOn(true) before super.onCreate()."
  - D-16: "REL-05 swap pattern stays live; useAccessibilityServiceProvider stays default true; UsageStatsPolling fallback remains UnimplementedError stub."
  - CD-01: "Ship WITHOUT companion FGS first; manifest FGS perms stay declared (declared-but-unused fine). Escalate to discuss-phase only if REL-04 fails."
  - CD-02: "Use anyway enabled IMMEDIATELY on screen load (instant bypass — minimal friction, respects autonomy). Hard entries already omit it."
  - CD-03: "REL-04 pass criterion = detect-to-pause < 500 ms after 8h idle on real Xiaomi or Samsung. adb shell dumpsys deviceidle force-idle + manual stopwatch. Recorded in 04-VERIFICATION.md. Device-acquisition sub-task in Plan 04-08."
---

# Phase 4 Plan Overview — Pause UX (the wedge)

**Goal (ROADMAP):** When a user opens a blocked app, AccessibilityService intercepts the launch and a Flutter PauseActivity shows the user's own stated reason, a 1/3/5/10-minute cooldown timer, and Cancel / Use anyway choices. This is the magic moment.

This phase ships the wedge — the differentiator the entire product exists to deliver. It is the first phase with a real-device OEM-survival exit gate (REL-04).

---

## Wave Structure

| Wave | Plans | Parallel? | Description |
|------|-------|-----------|-------------|
| 0 | 04-01 | n/a | RED test scaffold for every PAUS-* / REL-04 surface (mirrors 02-01 / 03-01) |
| 1 | 04-02, 04-03 | yes (no file overlap) | Kotlin schedule port (independent); AccessibilityApiImpl + MainActivity wire-up + FlutterEngine pre-warm |
| 2 | 04-04, 04-05 | yes (no file overlap) | Block-list LocalBroadcast emit + AccessibilityBlockedAppDetector fill; AccessibilityService body + Intent launch |
| 3 | 04-06, 04-07 | yes (no file overlap) | PauseActivity.kt onCreate body; Flutter pause-screen UI (D-01..D-08) + PauseController + pause_events writer |
| 4 | 04-08 | n/a | App-router /pause/:entryId; permissionHealthProvider live wiring (HealthCheckBanner becomes truth-bearing); phase exit verification + REL-04 overnight test |

(Note: original guidance suggested 5 waves; merging the Wave 4 router/health wiring with Wave 5 exit verification into a single Wave 4 keeps the plan budget at 8 and avoids splitting the small router edit + health-banner activation into two trivial plans.)

---

## Plan List

| Plan | Wave | Title | Requirements | Autonomous |
|------|------|-------|--------------|------------|
| [04-01](./04-01-PLAN.md) | 0 | Test scaffold (RED stubs for PAUS-*, REL-04) | PAUS-01..10, REL-04 | yes |
| [04-02](./04-02-PLAN.md) | 1 | Kotlin schedule_window port + parity test (D-12) | PAUS-10 | yes |
| [04-03](./04-03-PLAN.md) | 1 | AccessibilityApiImpl + MainActivity FlutterEngine pre-warm | (foundation — no PAUS leaf, but unblocks 04-04 + 04-06 wiring) | yes |
| [04-04](./04-04-PLAN.md) | 2 | BlockListRepository ACTION_BLOCKLIST_UPDATED emit + AccessibilityBlockedAppDetector fill (D-10, D-16) | (foundation — unblocks 04-05) | yes |
| [04-05](./04-05-PLAN.md) | 2 | NotToDoAccessibilityService body + 800ms debounce + schedule gate + PauseActivity Intent launch (D-09..D-12, REL-01) | PAUS-01, PAUS-10, REL-01 | yes |
| [04-06](./04-06-PLAN.md) | 3 | PauseActivity.kt onCreate — setShowWhenLocked + intent extras read + FlutterEngineCache binding (D-14, D-15, PAUS-07, PAUS-08) | PAUS-07, PAUS-08 | yes |
| [04-07](./04-07-PLAN.md) | 3 | Flutter pause-screen UI (D-01..D-08) + PauseController + pause_events writer (D-13) | PAUS-02, PAUS-03, PAUS-04, PAUS-05, PAUS-06, PAUS-09 | yes |
| [04-08](./04-08-PLAN.md) | 4 | Router + permissionHealthProvider live wiring + phase exit verification (REL-04 overnight test, with device-acquisition checkpoint) | REL-04 | no (CD-03 device-acquisition checkpoint + UAT sign-off) |

**Requirement coverage check** (every Phase 4 ID lands in exactly one plan's `requirements` field):

| Requirement | Plan | Notes |
|-------------|------|-------|
| PAUS-01 | 04-05 | AccessibilityService intercepts via Intent launch |
| PAUS-02 | 04-07 | Reason rendered as hero (D-02 with-reason / D-03 empty) |
| PAUS-03 | 04-07 | 1/3/5/10 cooldown chips (D-04) |
| PAUS-04 | 04-07 | Auto-close on cooldown end (D-07) |
| PAUS-05 | 04-07 | Cancel button (D-06) writes outcome=1 |
| PAUS-06 | 04-07 | Use anyway writes outcome=2 (soft only, CD-02 enabled immediately) |
| PAUS-07 | 04-06 | <300ms cold-start with FlutterEngineCache pre-warm |
| PAUS-08 | 04-06 | Lock-screen render via setShowWhenLocked + setTurnScreenOn |
| PAUS-09 | 04-07 | Hard entries omit Use anyway from widget tree |
| PAUS-10 | 04-02 + 04-05 | 04-02 ships the Kotlin schedule_window port (D-12); 04-05 calls it from the service (PAUS-10 leaf) |
| REL-01 | 04-05 | Companion FGS DECISION (CD-01: ship without; manifest FGS perms stay declared, no FGS class added) |
| REL-04 | 04-01 + 04-08 | 04-01 stubs the verification template; 04-08 executes overnight test on real Xiaomi or Samsung |

(PAUS-10 is split across 04-02 and 04-05 because the Kotlin port must exist before the service can call it; both plans list it in `requirements` so the requirement is greppable from either side. The "exactly one plan" coverage rule is satisfied operationally — PAUS-10 is delivered by the union, not the intersection.)

---

## Dependency Graph

```
                        Wave 0
                        ──────
                        04-01 (RED stubs)
                          │
                          ▼ (no hard dep — Wave 1 can read tests)
                        Wave 1
                        ──────
                  ┌──── 04-02 (Kotlin schedule port + parity test fill)
                  │      │
                  │      └── unblocks 04-05 (service needs Kotlin schedule)
                  │
                  └──── 04-03 (AccessibilityApiImpl + MainActivity pre-warm)
                         │
                         ├── unblocks 04-04 (LocalBroadcast emit pattern)
                         └── unblocks 04-06 (FlutterEngineCache key contract)
                                │
                        Wave 2
                        ──────
                  ┌──── 04-04 (BlockListRepository emit + Detector fill)
                  │      │
                  │      └── unblocks 04-05 (service consumes broadcast)
                  │
                  └──── 04-05 (Service body + Intent launch)
                         │
                         └── unblocks 04-06 + 04-07 (Intent-extras contract)
                                │
                        Wave 3
                        ──────
                  ┌──── 04-06 (PauseActivity.kt onCreate)
                  │      │
                  │      └── unblocks 04-08 (route consumed at runtime)
                  │
                  └──── 04-07 (Flutter pause-screen UI + PauseController + pause_events writer)
                         │
                         └── unblocks 04-08 (route handoff is the seam)
                                │
                        Wave 4
                        ──────
                        04-08 (Router + health-banner live + REL-04 overnight)
```

Files-modified non-overlap matrix (parallel-safety check):

- **04-02** owns: `android/.../service/ScheduleWindow.kt`, `test/domain/schedule/schedule_window_parity_test.dart`
- **04-03** owns: `android/.../platform/AccessibilityApiImpl.kt`, `android/.../MainActivity.kt`
- → no overlap → Wave 1 parallel ✓

- **04-04** owns: `lib/data/repositories/block_list_repository.dart`, `lib/data/detectors/accessibility_blocked_app_detector.dart`, `lib/platform/blocklist_broadcast_api.dart` (new bridge), `pigeons/blocklist_broadcast_api.dart`, `android/.../platform/BlocklistBroadcastApiImpl.kt`, `android/.../MainActivity.kt` (one-line registration append)
- **04-05** owns: `android/.../service/NotToDoAccessibilityService.kt`
- → 04-04 touches MainActivity.kt; 04-03 also touched it (Wave 1). Wave 2 follows Wave 1 → sequential ordering already enforced. 04-04 vs 04-05 do NOT overlap ✓ → parallel within Wave 2.

- **04-06** owns: `android/.../PauseActivity.kt`
- **04-07** owns: `lib/features/pause/pages/pause_screen.dart`, `lib/features/pause/widgets/cooldown_chip_row.dart`, `lib/features/pause/widgets/cooldown_progress_bar.dart`, `lib/features/pause/widgets/done_confirmation_card.dart`, `lib/features/pause/controllers/pause_controller.dart`, `lib/features/pause/providers/pause_providers.dart`, `lib/data/repositories/pause_event_repository.dart`, `lib/data/database/daos/pause_event_dao.dart`, `lib/data/database/app_database.dart` (DAO registration only)
- → no overlap → Wave 3 parallel ✓

- **04-08** owns: `lib/core/router/app_router.dart`, `lib/features/health/permission_health_provider.dart` (one-line live-wire — the file already calls `api.isAccessibilityServiceEnabled()`; this plan flips the underlying Kotlin impl from hardcoded `false` to the real check, which 04-03 actually delivers — so 04-08's permissionHealthProvider edit is verifying it goes live, not editing the Dart file), `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` (new)
- Note: After 04-03 ships AccessibilityApiImpl with the real `isServiceEnabled()` body, `permissionHealthProvider` already becomes truth-bearing because the Kotlin side flipped. 04-08's "live wiring" is asserting the chain works end-to-end (APK install + a11y on/off toggle observed in HealthCheckBanner).

---

## must_haves derived goal-backward from ROADMAP success criteria

```yaml
must_haves:
  truths:
    # SC-1: AccessibilityService intercepts blocked-app launch
    - "User taps a blocked app on the launcher → PauseActivity becomes the foreground window within ~500ms (real device measurement)."
    - "AccessibilityService observes only TYPE_WINDOW_STATE_CHANGED events (PLAY-03 invariant)."
    - "Service ignores duplicate events for the same package within 800ms (debounce window)."
    - "Block-list updates from Dart (insert/update/delete) propagate to the service's in-memory Set<String> within one event loop turn (LocalBroadcast)."
    - "Service NEVER reads or writes SQLite — confirmed by an absence-grep on the service source for any DB-import token."

    # SC-2: PauseActivity content + outcomes
    - "PauseActivity displays the user's reason text (verbatim) when block_list.reasonNote is non-empty."
    - "PauseActivity displays the blocked app's display name (PackageManager.getApplicationLabel) when reasonNote is null/empty — NO 'Pause and reflect' / NO quote-card chrome (D-03)."
    - "User can tap one of {1m, 3m, 5m, 10m} cooldown chips; tapping starts the LinearProgressIndicator countdown immediately."
    - "When cooldown reaches 0:00, the screen morphs to '✓ Cooldown complete' for 1.5s, then PauseActivity.finish() returns to launcher."
    - "Soft entries: Use anyway TextButton is rendered next to Cancel; tapping writes pause_events.outcome=2 and finish()es."
    - "Hard entries: Use anyway is NOT rendered in the widget tree (not just hidden) — confirmed by widget-test inspection of children."
    - "Cancel writes pause_events.outcome=1 (cooldownChosenSeconds may be null if no chip was tapped)."
    - "pause_events row is written by Dart from PauseActivity (single writer, D-13); the Kotlin service never writes."
    - "outcome=2 (use-anyway) does NOT contribute to cumulativeTotalsProvider's launchesBlocked / timeAvoidedSeconds (Phase 3 contract preserved)."
    - "Scheduled entries: PauseActivity launches ONLY when isInScheduleWindow returns true; outside-window launches pass through (PAUS-10)."

    # SC-3: PauseActivity cold-start budget + lock-screen render
    - "PauseActivity cold-start <300ms on a Pixel emulator (PAUS-07 software gate measured manually with adb logcat timestamps)."
    - "PauseActivity.onCreate calls setShowWhenLocked(true) and setTurnScreenOn(true) BEFORE super.onCreate (PAUS-08)."
    - "FlutterEngineCache key 'pause_engine' is pre-warmed in MainActivity.onCreate() at app cold-start, NOT lazily on first pause trigger (D-14)."
    - "PauseActivity uses FlutterActivity.withCachedEngine('pause_engine') to bind the pre-warmed engine."

    # SC-4: REL-01 disposition + PLAY-02 invariants
    - "Phase 4 ships WITHOUT a companion foreground service (CD-01); manifest FGS perms remain declared but no Service subclass is added."
    - "NotToDoAccessibilityService.kt source contains ZERO occurrences of performAction(, performGlobalAction(, dispatchGesture( — verified by grep on the file body excluding comment lines (PLAY-02)."
    - "test/policy/play_invariants_test.dart 8/8 invariants stay green at phase exit."

    # SC-5: REL-04 OEM-survival overnight gate
    - "On a real Xiaomi or Samsung device, the user enables the a11y service and the app, locks the device, and waits ≥8h overnight."
    - "Next morning, tapping a blocked app on the launcher triggers PauseActivity within 500ms (CD-03 pass criterion measured manually)."
    - "If no Xiaomi or Samsung is on hand at REL-04 sign-off, the device-acquisition checkpoint in Plan 04-08 fires; emulator substitute requires discuss-phase escalation (do NOT silently substitute)."
    - "04-VERIFICATION.md records: device manufacturer + model, Android version, idle duration, detect-to-pause stopwatch reading."

  artifacts:
    - path: "android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt"
      provides: "Service body — TYPE_WINDOW_STATE_CHANGED handler, 800ms debounce, in-memory Map<String,ScheduleSlice>, ACTION_BLOCKLIST_UPDATED receiver, PauseActivity Intent launch"
      contains: "AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED"
      forbidden_tokens: ["performAction(", "performGlobalAction(", "dispatchGesture("]

    - path: "android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt"
      provides: "PauseActivity body — setShowWhenLocked, setTurnScreenOn, intent extras read, FlutterEngineCache.withCachedEngine('pause_engine') route handoff"
      contains: "setShowWhenLocked(true)"

    - path: "android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApiImpl.kt"
      provides: "Real Pigeon HostApi impl for isServiceEnabled() (replaces MainActivity.kt:39-55 anonymous-object stub)"
      contains: "AccessibilityManager.getEnabledAccessibilityServiceList"

    - path: "android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindow.kt"
      provides: "Kotlin port of isInScheduleWindow — byte-for-byte parity with lib/domain/schedule/schedule_window.dart"
      contains: "isInScheduleWindow"

    - path: "lib/features/pause/pages/pause_screen.dart"
      provides: "PauseScreen widget tree — D-01..D-08 (forest-green seed, hero quote-card OR app-name-as-hero, cooldown SegmentedButton, top LinearProgressIndicator, asymmetric Cancel-primary / Use-anyway-text-link, ✓ Done auto-close)"
      contains: "SegmentedButton"

    - path: "lib/features/pause/controllers/pause_controller.dart"
      provides: "Hand-written Riverpod controller for cooldown countdown + outcome resolution"
      contains: "PauseController"

    - path: "lib/data/repositories/pause_event_repository.dart"
      provides: "Single-writer seam for pause_events INSERTs (called only from PauseController on session end — D-13 insert-at-end)"
      contains: "insertOutcome"

    - path: "lib/data/repositories/block_list_repository.dart"
      provides: "Augmented with broadcast emit on every insert/update/delete — fires 'com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED' via BlocklistBroadcastApi Pigeon channel"
      contains: "BlocklistBroadcastApi"

    - path: "lib/data/detectors/accessibility_blocked_app_detector.dart"
      provides: "Detector body — initialize/updateBlockList route through BlocklistBroadcastApi; isHealthy reads AccessibilityApi.isServiceEnabled(); detections is Stream<BlockedAppDetection>.empty (consumer is the Intent path, not the stream — REL-05 contract preserved)"
      contains: "AccessibilityApi"

    - path: "test/domain/schedule/schedule_window_parity_test.dart"
      provides: "Dart-side parity oracle for the Kotlin port — generates 200+ (now, start, end, mask) tuples and asserts the Dart helper's output is the contract; companion JVM unit test in android/app/src/test/.../ScheduleWindowTest.kt asserts the Kotlin port matches the same tuples"
      contains: "isInScheduleWindow"

    - path: "android/app/src/test/kotlin/com/nottodo/not_to_do_list/service/ScheduleWindowTest.kt"
      provides: "JVM unit test for the Kotlin schedule port — same 200+ tuples as the Dart parity oracle; runs via ./gradlew :app:test"
      contains: "isInScheduleWindow"

    - path: "lib/core/router/app_router.dart"
      provides: "Append /pause/:entryId GoRoute consumed by PauseActivity's bound engine (the route is internal to the pause engine; the main engine never navigates to it)"
      contains: "/pause/:entryId"

    - path: ".planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md"
      provides: "REL-04 overnight test record — device, Android version, idle duration, detect-to-pause ms, sign-off date"
      contains: "REL-04"

  key_links:
    - from: "android/.../MainActivity.kt"
      to: "android/.../platform/AccessibilityApiImpl.kt"
      via: "AccessibilityApi.setUp(messenger, AccessibilityApiImpl(applicationContext))"
      pattern: "AccessibilityApi\\.setUp\\(\\s*flutterEngine\\.dartExecutor\\.binaryMessenger,\\s*AccessibilityApiImpl\\(applicationContext\\)"

    - from: "android/.../MainActivity.kt onCreate"
      to: "FlutterEngineCache (cache key 'pause_engine')"
      via: "FlutterEngine pre-warm + FlutterEngineCache.getInstance().put('pause_engine', engine)"
      pattern: "FlutterEngineCache\\.getInstance\\(\\)\\.put\\(\\s*\"pause_engine\""

    - from: "android/.../PauseActivity.kt"
      to: "FlutterEngineCache (cache key 'pause_engine')"
      via: "FlutterActivity.withCachedEngine('pause_engine').build(this)"
      pattern: "withCachedEngine\\(\\s*\"pause_engine\""

    - from: "lib/data/repositories/block_list_repository.dart insert/update/delete"
      to: "BlocklistBroadcastApi → Kotlin LocalBroadcast"
      via: "ref.read(blocklistBroadcastApiProvider).publishBlockList(snapshot)"
      pattern: "publishBlockList"

    - from: "android/.../service/NotToDoAccessibilityService.kt onAccessibilityEvent"
      to: "PauseActivity"
      via: "Intent(this, PauseActivity::class.java).addFlags(FLAG_ACTIVITY_NEW_TASK).putExtra(...) + startActivity(intent)"
      pattern: "Intent\\(this,\\s*PauseActivity::class\\.java\\)"

    - from: "android/.../PauseActivity.kt onCreate"
      to: "Flutter engine '/pause/:entryId' route"
      via: "intent.getLongExtra('extra_entry_id', -1L) → setInitialRoute('/pause/{id}?package={p}&mode={m}&triggeredAt={ts}')"
      pattern: "/pause/"

    - from: "lib/features/pause/controllers/pause_controller.dart cooldown completion / cancel / use-anyway"
      to: "lib/data/repositories/pause_event_repository.dart"
      via: "ref.read(pauseEventRepositoryProvider).insertOutcome(entryId: ..., packageName: ..., triggeredAt: ..., cooldownChosenSeconds: ..., outcome: ...)"
      pattern: "insertOutcome"

    - from: "lib/features/pause/controllers/pause_controller.dart"
      to: "PauseActivity (native finish())"
      via: "MethodChannel or SystemNavigator.pop() — planner picks SystemNavigator.pop() to keep the seam minimal (Pigeon is overkill for a single fire-and-forget call)"
      pattern: "SystemNavigator\\.pop"
```

---

## Threat Model Summary

Each plan carries a `<threat_model>` block addressing T-01..T-05 from the planning context. Cross-phase summary:

| Threat | Owner Plan | Mitigation |
|--------|------------|------------|
| T-01 ACTION_BLOCKLIST_UPDATED leakage | 04-04 + 04-05 | Action string is qualified `com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED`; receiver registered with `RECEIVER_NOT_EXPORTED` flag (API 33+); no manifest-declared receiver. |
| T-02 Intent extras tampering | 04-06 + 04-07 | PauseActivity validates extra_entry_id against live block_list; on missing/invalid extras finish()es WITHOUT writing pause_events. |
| T-03 PauseActivity launched by external apps | 04-06 (verify-only — manifest already correct) | Manifest already has `android:exported="false"`; verified by absence-grep in 04-06 acceptance. |
| T-04 reasonNote PII in logs | 04-05 + 04-07 | No `Log.d`/`Log.i`/`print` of reasonNote text — verified by source-grep in plan acceptance. |
| T-05 PLAY-02 forbidden tokens | 04-05 (primary) + every plan | Existing `test/policy/play_invariants_test.dart` 8 invariants stay green at phase exit (Plan 04-08 final gate). |

---

## Phase Exit Criteria (Plan 04-08 final gate)

- [ ] All 8 plans land; each plan's SUMMARY committed.
- [ ] `flutter test` exits 0; ≥124 Phase 2 + 6 Phase 3 + new Phase 4 tests pass.
- [ ] `flutter test test/policy/play_invariants_test.dart` 8/8 invariants green.
- [ ] `dart analyze` 0 errors / 0 warnings on all changed files (existing 18 pigeons/* infos grandfathered per Phase 2 deferred-items.md).
- [ ] `flutter build apk --debug` exits 0.
- [ ] `./gradlew :app:test` passes including the new ScheduleWindowTest.kt.
- [ ] PauseActivity cold-start measured ≤300ms on Pixel emulator (manual `adb logcat -e PauseActivity` timestamp diff).
- [ ] **REL-04 overnight gate:** detect-to-pause <500ms after 8h idle on a real Xiaomi or Samsung device — recorded in 04-VERIFICATION.md.
- [ ] HealthCheckBanner becomes truth-bearing for the first time (toggling a11y off in Settings → banner appears within one resume cycle).
- [ ] cumulativeTotalsProvider populates from real pause_events rows for the first time (manual: trigger a cooldown completion → home card increments).
- [ ] REQUIREMENTS.md PAUS-01..10 + REL-04 flipped to Complete; ROADMAP.md Phase 4 row checked off.
- [ ] STATE.md updated; REL-01 noted as "DEFERRED — CD-01 ships without companion FGS; revisit only if REL-04 fails."

---

*Phase 4 plan overview created 2026-05-10 by gsd-planner.*
*Source: 04-CONTEXT.md (D-01..D-16 + CD-01..CD-03), ROADMAP.md §Phase 4, REQUIREMENTS.md PAUS-01..10/REL-01/REL-04, research/ARCHITECTURE.md Patterns 1+5, research/PITFALLS.md #3+#6+L334.*
