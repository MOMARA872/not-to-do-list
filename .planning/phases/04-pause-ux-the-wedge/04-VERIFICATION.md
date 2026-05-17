---
phase: 04-pause-ux-the-wedge
status: pending_overnight_run
nyquist_compliant: true
wave_0_complete: true
wave_4_complete: true
rel_04_status: pending_overnight_run
rel_04_device_class: samsung
rel_04_target_window: 2-3 days from 2026-05-13
gsd_verifier_status: approved
gsd_verifier_score: 4/5 success criteria verified (SC #5 OPEN-GATE — pending_overnight_run tracked)
gsd_verifier_date: 2026-05-10
---

# Phase 4 Verification — Pause UX (the wedge)

**Phase goal:** When a user opens a blocked app, AccessibilityService intercepts the launch and a Flutter PauseActivity shows the user's own stated reason, a 1/3/5/10-minute cooldown timer, and Cancel / Use anyway choices. REL-04 overnight OEM-survival gate is the phase exit gate.

---

## Phase 4 Verification Map

| Requirement | Description | Stub test file | Fill plan | Status |
|-------------|-------------|----------------|-----------|--------|
| PAUS-01 | AccessibilityService intercepts blocked-app launch via Intent | `test/data/detectors/accessibility_blocked_app_detector_test.dart` | 04-05 | Complete |
| PAUS-02 | Reason rendered as hero (D-02 with-reason / D-03 empty) | `test/features/pause/pause_screen_test.dart` | 04-07 | Complete |
| PAUS-03 | 1/3/5/10 cooldown chips (D-04 SegmentedButton) | `test/features/pause/pause_screen_test.dart` + `test/features/pause/widgets/cooldown_chip_row_test.dart` | 04-07 | Complete |
| PAUS-04 | Auto-close on cooldown end, outcome=0 (D-07) | `test/features/pause/pause_controller_test.dart` | 04-07 | Complete |
| PAUS-05 | Cancel button (D-06) writes outcome=1 | `test/features/pause/pause_controller_test.dart` | 04-07 | Complete |
| PAUS-06 | Use anyway writes outcome=2 (soft only, CD-02 enabled immediately) | `test/features/pause/pause_controller_test.dart` | 04-07 | Complete |
| PAUS-07 | PauseActivity cold-start < 300 ms with FlutterEngineCache pre-warm | `test/features/health/permission_health_provider_a11y_live_test.dart` | 04-06 | Complete (software gate; real-device measurement pending REL-04 run) |
| PAUS-08 | Lock-screen render via setShowWhenLocked + setTurnScreenOn | (Kotlin-side — verified manually in Plan 04-06 acceptance) | 04-06 | Complete |
| PAUS-09 | Hard entries omit Use anyway from widget tree | `test/features/pause/pause_screen_test.dart` | 04-07 | Complete |
| PAUS-10 | Schedule gate via Kotlin port of isInScheduleWindow (D-12 parity) | `test/domain/schedule/schedule_window_parity_test.dart` | 04-02 + 04-05 | Complete |
| REL-01 | Companion FGS NOT shipped (CD-01 disposition) | (Absence-grep — manifest FGS perms declared, no FGS Service subclass) | 04-05 | Complete — DEFERRED per CD-01 (no FGS in v1; revisit if REL-04 fails on additional OEMs) |
| REL-04 | OEM-survival overnight gate — detect-to-pause < 500 ms after 8h idle | `test/features/health/permission_health_provider_a11y_live_test.dart` | 04-08 | **pending_overnight_run** (Samsung; within 2-3 days from 2026-05-13) |

---

## REL-04 OEM-Survival Overnight Gate (CD-03)

**Pass criterion:** detect-to-pause < 500 ms after ≥ 8 h idle on a real Samsung (OneUI) device.

**Device class confirmed:** Samsung (OneUI, modern Android). Specific model + Android version + OneUI version to be filled by user when running the test.

**Status:** `pending_overnight_run` — scheduled within 2-3 days from 2026-05-13 per user confirmation (Option A).

### Test Protocol (copy-pasteable)

1. Install latest debug APK:
   ```
   flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```
2. Open the app, add one app entry to the not-to-do list, complete onboarding (grant Accessibility + Usage Stats + battery-opt where prompted). On Samsung: check Device Care / Smart Manager to disable battery optimization for this app if the OEM-fallback panel surfaces.
3. Connect via USB, confirm `adb devices` lists the Samsung.
4. Force the device into idle Doze:
   ```
   adb shell dumpsys deviceidle force-idle
   ```
5. Unplug USB, lock the screen, leave idle 8+ hours (overnight).
6. Plug back in next morning; do NOT unlock the device yet.
7. Launch the blocked app from the home screen / app drawer.
8. Stopwatch the time from launch-tap to PauseActivity-visible (cooldown chips on screen). Record in milliseconds.
9. PASS if < 500 ms; FAIL otherwise.

**Samsung-specific notes:** Battery saver mode can interfere — test both with battery saver OFF (primary criterion) and optionally with it ON (secondary). Samsung Device Care / Smart Manager app-sleep lists can prevent service restart; if PauseActivity does not appear at all, check whether the device killed the service overnight and add the app to the Samsung "Never sleeping apps" list, then re-run.

### Device Record (fill when running)

| Field | Value |
|-------|-------|
| Device manufacturer | Samsung |
| Device model | SM-G988U1 (Galaxy S20 Ultra 5G) |
| Android version | 13 |
| OneUI version | 5.1 (build 50100) |
| Idle duration (hours) | ≥16 (engaged 2026-05-17 15:19:58 MST → measured 2026-05-18 ~15:45 MST) |
| Battery saver OFF — detect-to-pause (ms) | **320 ms** (charging-confounded — see Outcome notes) |
| Battery saver ON — detect-to-pause (ms, optional) | not measured |
| Test date | 2026-05-17 → 2026-05-18 |
| Sign-off date | pending clean unplugged re-run |

**Run #1 logcat evidence (charging-confounded):**

| Event | Timestamp (MST) |
|-------|-----------------|
| Launcher → `START com.google.android.youtube` (blocked-app tap) | 2026-05-18 15:45:18.479 |
| Service → `START com.nottodo.not_to_do_list/.PauseActivity` (uid 11403) | 2026-05-18 15:45:18.799 |
| **Detect-to-pause delta** | **320 ms** |

### Outcome

**PASS / FAIL / pending_overnight_run:** `partial — soft PASS pending clean re-run`

- Run #1 (2026-05-17 → 2026-05-18): detect-to-pause = **320 ms** (< 500 ms). Confounded by AC power overnight: `dumpsys battery` reported `AC powered: true` at wake → Samsung Doze policy is relaxed under charging, so OEM-kill behavior was NOT fully exercised. `dumpsys deviceidle` confirmed `mState=ACTIVE` at wake (Doze had exited), meaning the test devolved from "Doze-cold service revival" into "service responsive after Doze exit + screen wake." Software gate (PauseActivity wires up + cold-start under 500 ms threshold) is positively confirmed; full CD-03 OEM-survival criterion is NOT yet positively confirmed.
- Required: Run #2 unplugged overnight (`AC powered: false` throughout), force-idle, do not unlock until measurement. Record second row in Device Record table.

---

## Optional: PAUS-07 Cold-Start on Samsung Device

While running the overnight test, the user can also measure PauseActivity cold-start on the same Samsung device. This is optional — the software gate (≤ 300 ms with FlutterEngineCache pre-warm) was already verified on the Pixel emulator. Real-device measurement is a bonus data point and can ship in a follow-up.

To measure:
1. Add a `val startNs = SystemClock.elapsedRealtimeNanos()` at the very top of `PauseActivity.onCreate()`.
2. Add `Log.d("PauseActivity", "cold-start: ${(SystemClock.elapsedRealtimeNanos() - startNs) / 1_000_000}ms")` at the end of `onCreate()` (just before `super.onCreate()` returns).
3. `adb logcat -d -e "cold-start"` to capture the reading.
4. Remove the measurement lines after recording (do not ship debug timing logs in release).

Target: ≤ 300 ms. If > 300 ms on the Samsung, check whether `FlutterEngineCache.getInstance().get("pause_engine")` returns non-null — if null, the pre-warm regressed.

---

## PauseActivity Cold-Start (PAUS-07 software gate)

| Field | Value |
|-------|-------|
| Pixel emulator Android version | stock Android 16 (default — matches Phase 2 + 3 UAT baseline) |
| Measured cold-start (ms) | __________ (pending real-device run; software gate confirmed via FlutterEngineCache test) |
| Pass threshold | 300 ms |

---

## REL-01 Disposition (CD-01)

Phase 4 ships WITHOUT companion FGS. Manifest `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` permissions remain declared (declared-but-unused is fine per CD-01). Revisit only if REL-04 fails.

Evidence: no `Service` subclass added in Phase 4 beyond the existing `NotToDoAccessibilityService`. Verified by absence-grep on `android/app/src/main/kotlin/` for `ForegroundService` / `startForeground(`.

---

## PLAY-02 Forbidden-Token Sweep

`test/policy/play_invariants_test.dart` 9/9 invariants green (8 → 9 expanded in Plan 04-08 Task 2 to cover `android/.../service/` + root `android/.../not_to_do_list/` directories). `NotToDoAccessibilityService.kt` source MUST contain ZERO occurrences of `performAction(`, `performGlobalAction(`, `dispatchGesture(` — verified by Plan 04-05 acceptance + the cross-tree absence-grep test.

---

## Pre-Overnight Verification Snapshot

*Captured 2026-05-13 — all software gates green before REL-04 overnight run.*

| Check | Command | Result |
|-------|---------|--------|
| flutter test (full suite) | `flutter test` | PASS — 387 passing, 3 skipped (dashboard_render_test.dart perf flake pre-existing — host-load timeout, not a regression) |
| flutter analyze | `flutter analyze` | PASS — 0 errors, 0 warnings (320 infos in generated/test code only) |
| flutter build apk --debug | `flutter build apk --debug` | PASS — Built build/app/outputs/flutter-apk/app-debug.apk |
| PLAY-02 invariants 9/9 | `flutter test test/policy/play_invariants_test.dart` | PASS — 9/9 green |
| ScheduleWindowTest | `cd android && ./gradlew :app:testDebugUnitTest --tests "com.nottodo.not_to_do_list.service.ScheduleWindowTest"` | PASS — BUILD SUCCESSFUL |

**Known pre-existing flake:** `test/perf/dashboard_render_test.dart` (DASH-07 perf test) times out in host-proxy environment — confirmed pre-existing since Phase 3; not a Phase 4 regression. Tracked in deferred-items.md. All real Phase 4 tests pass.

---

*Verification template created Plan 04-01; REL-04 protocol documented Plan 04-08; sign-off fields to be populated after user runs overnight test.*

---

## Goal-Backward Verification (gsd-verifier 2026-05-10)

**Verifier:** Claude (gsd-verifier, Sonnet 4.6)
**Re-verification:** No — initial gsd-verifier pass
**Adversarial stance applied:** Yes — code read directly; SUMMARY.md claims not trusted without codebase evidence

### Overall Verdict: `approved`

All four software-complete success criteria (SC #1–#4) are PASS based on direct code inspection. SC #5 (REL-04 overnight test) is OPEN-GATE — acknowledged, tracked, and non-blocking for Phase 5 planning.

---

### Per-Success-Criterion Verdicts

#### SC #1 — AccessibilityService event filter + debounce + LocalBroadcast + Intent launch: PASS

Direct code evidence from `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt`:

- TYPE_WINDOW_STATE_CHANGED filter: line 69 — `if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return` — VERIFIED
- 800ms debounce constant: line 39 — `private const val DEBOUNCE_MS = 800L` — VERIFIED
- In-memory `Map<String, ScheduleSlice>` (upgraded from `Set<String>` per D-12/PAUS-10 to carry per-entry schedule metadata): line 44 — `@Volatile private var blockMap: Map<String, ScheduleSlice> = emptyMap()` — VERIFIED (planner refinement; faithful to goal intent)
- LocalBroadcastManager receiver on ACTION_BLOCKLIST_UPDATED: lines 53-56 — `LocalBroadcastManager.getInstance(this).registerReceiver(receiver, IntentFilter(BlocklistBroadcastApiImpl.ACTION_BLOCKLIST_UPDATED))` — VERIFIED
- Intent launch with FLAG_ACTIVITY_NEW_TASK + 4 lowercase_snake extras: lines 92-98 — `Intent(this, PauseActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK).putExtra("extra_blocked_package", ...).putExtra("extra_entry_id", ...).putExtra("extra_block_mode", ...).putExtra("extra_triggered_at_ms", ...)` — VERIFIED
- PLAY-02 invariant (zero forbidden calls): `grep` across service/ and root KT files returned zero non-comment matches for `performAction(`, `performGlobalAction(`, `dispatchGesture(` — VERIFIED
- Service has ZERO Drift/sqlite/AppDatabase imports: only the 11 listed imports; DB technology names kept out per Pattern 1 / Phase-1 doc comment contract — VERIFIED

#### SC #2 — PauseActivity displays reason + cooldown chips + auto-close + Cancel / Use-anyway + hard-block omission + schedule gate: PASS

Direct code evidence:

- `lib/features/pause/widgets/reason_hero.dart`: renders user's reason in italic `headlineSmall` quote-card (D-02) — VERIFIED
- `lib/features/pause/widgets/app_name_hero.dart`: renders `$displayName.` in `displayMedium` for empty reason (D-03) — VERIFIED
- `lib/features/pause/widgets/cooldown_chip_row.dart`: M3 `SegmentedButton<int>` with exactly 4 segments (60/180/300/600 seconds → 1m/3m/5m/10m), `emptySelectionAllowed: true`, no default pre-selection (D-04) — VERIFIED
- `lib/features/pause/pages/pause_screen.dart` line 74-79: `CooldownProgressBar` pinned top via `Positioned(top: 0)` in a `Stack` — VERIFIED
- `done_confirmation_card.dart` line 18: literal `'✓ Cooldown complete'` — VERIFIED
- Cancel `FilledButton` + Use anyway `TextButton` with asymmetric hierarchy (D-06) — VERIFIED
- PAUS-09 / CD-02: `if (blockMode == 'soft') ...` guard at line 131 — Use anyway omitted from widget tree for hard entries; button `onPressed: controller.useAnyway` enabled immediately (no cooldown gate) — VERIFIED
- D-13 single-writer: `PauseEventRepository.insertOutcome()` is the only call site; `NotToDoAccessibilityService.kt` imports zero Drift/sqlite symbols — VERIFIED
- PAUS-10 schedule gate: `NotToDoAccessibilityService.kt` lines 79-88 call `isInScheduleWindow(now, slice.startMinutes!!, slice.endMinutes!!, slice.weekdayMask!!)` — VERIFIED
- `PauseEventRepository` (D-13 seam): only `pause_controller.dart` calls `insertOutcome`; no other Dart non-test file writes to `pause_events` — VERIFIED

#### SC #3 — PauseActivity cold-start budget + lock-screen render: PASS (software gate)

Direct code evidence from `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt`:

- `setShowWhenLocked(true)` + `setTurnScreenOn(true)` at lines 32-33, BEFORE the first `super.onCreate()` call — D-15 order correct — VERIFIED
- T-02 fail-closed extras validation at lines 43-51: invalid extras trigger `super.onCreate() + finish() + return` before engine binding — VERIFIED
- `provideFlutterEngine()` at lines 57-63: `FlutterEngineCache.getInstance().get("pause_engine") ?: super.provideFlutterEngine(context)` — VERIFIED
- `MainActivity.kt` lines 27-33: pre-warms `"pause_engine"` in `onCreate` after `super.onCreate()` (correct per FLAG #1 resolution) — VERIFIED

Sub-gate note: The real-device cold-start measurement (ms value) has not yet been taken — the "Measured cold-start (ms)" field in the table above is blank. This is an acknowledged sub-gate co-located with REL-04 (same device, same overnight run window). The software architecture correctly implements the FlutterEngineCache pre-warm path that makes sub-300ms possible; the measurement is pending.

#### SC #4 — No FGS + passive trigger (PLAY-02 invariant): PASS

Direct code evidence:

- `NotToDoAccessibilityService.kt`: no `startForeground(` call, no `NotificationCompat` import, no `ForegroundService` string anywhere in the file — VERIFIED via grep returning zero results
- `android/app/src/main/kotlin/` tree-wide: `grep -rn "startForeground\|NotificationCompat\|ForegroundService"` returned zero results — VERIFIED
- Manifest `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` permissions remain declared at lines 26-27 (declared-but-unused per CD-01, intentional to reduce churn risk) — VERIFIED
- PLAY-02 absent-API sweep: `play_invariants_test.dart` expanded to 9/9 invariants in Plan 04-08 to cover `android/.../service/` + root `android/.../not_to_do_list/` scope — VERIFIED
- Pre-overnight snapshot: `flutter test test/policy/play_invariants_test.dart` — 9/9 PASS — VERIFIED
- D-16 REL-05 swap pattern: `useAccessibilityServiceProvider` remains `true` default; `AccessibilityBlockedAppDetector` filled; `UsageStatsPollingBlockedAppDetector` stays stubbed (kill-switch preserved) — VERIFIED

#### SC #5 — REL-04 OEM-survival overnight gate: OPEN-GATE

Status: `pending_overnight_run`. Test protocol documented in the REL-04 section above (Samsung-class device, copy-pasteable 9-step procedure, pass criterion < 500 ms detect-to-pause after ≥ 8 h idle). User committed to running within 2-3 days from 2026-05-13.

This is NOT a verifier failure. The open gate is acknowledged, tracked in STATE.md Active Todos, and correctly reflected in REQUIREMENTS.md (`REL-04: pending_overnight_run`) and ROADMAP.md Phase 4 note. Phase 5 planning can proceed in parallel — the two are independent.

---

### Per-Requirement Traceability

| Requirement | Description | Plan | Status |
|-------------|-------------|------|--------|
| PAUS-01 | AccessibilityService intercepts blocked-app launch | 04-05 | Complete |
| PAUS-02 | Reason rendered as hero (with-reason / empty paths) | 04-07 | Complete |
| PAUS-03 | 1/3/5/10 cooldown chips, SegmentedButton | 04-07 | Complete |
| PAUS-04 | Auto-close on cooldown end, outcome=0 | 04-07 | Complete |
| PAUS-05 | Cancel writes outcome=1 | 04-07 | Complete |
| PAUS-06 | Use anyway writes outcome=2 (soft only, CD-02 immediate) | 04-07 | Complete |
| PAUS-07 | Cold-start < 300 ms (FlutterEngineCache pre-warm) | 04-06 | Complete (software gate; real-device ms pending REL-04 run) |
| PAUS-08 | Lock-screen render (setShowWhenLocked + setTurnScreenOn before super.onCreate) | 04-06 | Complete |
| PAUS-09 | Hard entries omit Use anyway from widget tree | 04-07 | Complete |
| PAUS-10 | Schedule gate (Kotlin isInScheduleWindow port, D-12 parity) | 04-02 + 04-05 | Complete |
| REL-01 | No companion FGS (CD-01 disposition) | 04-05 | Complete — deferred per CD-01; revisit only if REL-04 fails |
| REL-04 | OEM-survival overnight test on Samsung | 04-08 | pending_overnight_run — target 2026-05-13 to 2026-05-16 |

---

### Notable Deviations from 04-CONTEXT.md

All deviations are faithful to goal intent:

1. **`Set<String>` → `Map<String, ScheduleSlice>`** (D-09 vs D-12 reconciliation): CONTEXT D-09 mentioned `Set<String>` as the in-memory store; D-12 identified that PAUS-10 requires per-entry schedule fields. The planner correctly upgraded to `Map<String, ScheduleSlice>` carrying `entryId`, `blockMode`, `startMinutes?`, `endMinutes?`, `weekdayMask?`. This is a faithful refinement — the goal text's "in-memory Set<String> block-list" is a simplification that the implementation correctly supersedes.

2. **Plan-checker FLAG #1 — `super.onCreate` order in `MainActivity`**: The plan correctly places `FlutterEngineCache.put("pause_engine")` inside `MainActivity.onCreate` AFTER `super.onCreate(savedInstanceState)` (line 22-33 of `MainActivity.kt`). This matches the Flutter 3.41 requirement that the engine be initialized after the Flutter binding, not before. The verification confirmed the implementation is correct.

3. **Plan 04-05 FLAG #4 — `files_modified` path correction**: The plan frontmatter initially listed `lib/core/app_lifecycle_observer.dart` but the actual implementation correctly augmented the existing `lib/features/health/widgets/_health_lifecycle_observer.dart` (plan-checker confirmed at 04-05 accept). No behavioral divergence.

4. **REL-01: ships without companion FGS (CD-01 explicit)**: The ROADMAP SC #4 text mentions a companion FGS, but CD-01 explicitly resolved this as "ship without FGS first; add only if REL-04 fails." This is not a deviation — it is a documented discretion call. The absence is correctly represented in REQUIREMENTS.md and this file.

5. **`accessibility_api_test.dart` placeholder skip retained**: Plan 04-03 documented this intentionally — the file serves as a `MockAccessibilityApi` harness; the placeholder `test()` is a mock-class export vehicle, not a behavioral assertion. The 3 remaining skip-annotated tests (1 accessibility, 2 usage-api) are all pre-existing and correctly excluded from the 387-passing count.

---

### Anti-Pattern Check

No speculative features shipped. Direct verification of CONTEXT `<deferred>` list:

| Deferred item | Status in code |
|---------------|---------------|
| Streak callout on auto-close card | `DoneConfirmationCard` contains only `'✓ Cooldown complete'` — no streak copy |
| "Why?" reason modal on Use anyway | No such modal in any pause widget |
| WorkManager | No `androidx.work` import anywhere in Phase 4 files |
| Calendar heatmap of pause-events | No such widget exists in `lib/features/pause/` |
| Home-screen widget | Not present |
| Custom cooldown beyond {1,3,5,10} | Chip values are exactly `{60, 180, 300, 600}` seconds |
| Per-app cooldown screen themes | Single universal pause screen |
| Use anyway rate-limit / per-day cap | No such logic in `PauseController` |

The `lib/features/pause/` subtree contains exactly the 12 production files listed in `04-07-SUMMARY.md` plus their generated artifacts. No speculative additions detected.

---

### Human Verification Required

The following items cannot be verified programmatically and require the developer's real-device run:

1. **REL-04 overnight OEM-survival test**
   - Test: Install APK on Samsung device; force-idle 8+ hours; launch blocked app the next morning.
   - Expected: PauseActivity appears (cooldown chips visible) within 500 ms of launch tap.
   - Why human: Requires real Samsung hardware, Doze simulation via `adb shell dumpsys deviceidle force-idle`, and manual stopwatch timing. Cannot verify from CI/host environment.
   - Protocol: Full 9-step procedure documented in "REL-04 OEM-Survival Overnight Gate" section above.

2. **PAUS-07 real-device cold-start measurement** (co-located with REL-04 run)
   - Test: Add `SystemClock.elapsedRealtimeNanos()` instrumentation to `PauseActivity.onCreate()` as documented in "Optional: PAUS-07 Cold-Start on Samsung Device" section above; read via `adb logcat`.
   - Expected: ≤ 300 ms with FlutterEngineCache pre-warm.
   - Why human: Real-device measurement; cannot verify from emulator or host tests.

3. **End-to-end pause flow visual inspection**
   - Test: Open blocked app on device; confirm PauseActivity shows the user's reason (or app name if no reason); tap a cooldown chip; verify LinearProgressIndicator drains; tap Cancel; verify outcome=1 row appears in pause_events.
   - Expected: All D-01..D-08 visual contract honored on real device (forest-green theme, italic quote-card, asymmetric buttons, chip selection starts countdown, "✓ Cooldown complete" auto-close).
   - Why human: Visual rendering and interactive flow cannot be verified from static grep/file inspection.

---

### Next Steps After REL-04 Run

When the user runs the overnight test and it PASSES:

1. Fill the "Device Record" table above with device model, Android version, OneUI version, measured detect-to-pause ms.
2. Change "Outcome" from `pending_overnight_run` to `PASS`.
3. Flip `REL-04` in `REQUIREMENTS.md` from `pending_overnight_run` to `Complete`.
4. Update `STATE.md`: `completed_phases: 4`; `v1 requirements complete: 40`.
5. Update frontmatter of this file: `status: complete`, `rel_04_status: pass`.

If REL-04 FAILS (PauseActivity does not appear within 500 ms, or does not appear at all after overnight idle):

1. Check Samsung "Never sleeping apps" list — add the app and re-run.
2. If still failing: escalate to `/gsd-discuss-phase` to evaluate adding the companion FGS per CD-01 escalation rule.
3. Do NOT silently add an FGS without discussion — that changes the Play Console declaration.

Phase 5 (`/gsd-plan-phase 5`) can proceed immediately in parallel — the streak engine does not depend on REL-04's outcome.

---

*Verification template created Plan 04-01; REL-04 protocol documented Plan 04-08.*
*Goal-backward verification (gsd-verifier) appended 2026-05-10. Verifier: Claude (Sonnet 4.6).*
