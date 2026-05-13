---
phase: 04-pause-ux-the-wedge
status: pending_overnight_run
nyquist_compliant: true
wave_0_complete: true
wave_4_complete: true
rel_04_status: pending_overnight_run
rel_04_device_class: samsung
rel_04_target_window: 2-3 days from 2026-05-13
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
| Device model | __________ (fill when running — e.g., Galaxy S22, Galaxy A54) |
| Android version | __________ |
| OneUI version | __________ |
| Idle duration (hours) | ≥ 8 |
| Battery saver OFF — detect-to-pause (ms) | __________ |
| Battery saver ON — detect-to-pause (ms, optional) | __________ |
| Test date | __________ |
| Sign-off date | __________ |

### Outcome

**PASS / FAIL / pending_overnight_run:** `pending_overnight_run`

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
| flutter test (full suite) | `flutter test` | pending |
| flutter analyze | `flutter analyze` | pending |
| flutter build apk --debug | `flutter build apk --debug` | pending |
| PLAY-02 invariants 9/9 | `flutter test test/policy/play_invariants_test.dart` | pending |
| ScheduleWindowTest | `cd android && ./gradlew :app:testDebugUnitTest --tests "com.nottodo.not_to_do_list.service.ScheduleWindowTest"` | pending |

*(Results to be filled by Task 7 of the continuation plan.)*

---

*Verification template created Plan 04-01; REL-04 protocol documented Plan 04-08; sign-off fields to be populated after user runs overnight test.*
