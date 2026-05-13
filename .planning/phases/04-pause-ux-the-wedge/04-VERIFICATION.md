---
phase: 04-pause-ux-the-wedge
status: pending
nyquist_compliant: false
wave_0_complete: true
rel_04_signed_off: false
---

# Phase 4 Verification — Pause UX (the wedge)

**Phase goal:** When a user opens a blocked app, AccessibilityService intercepts the launch and a Flutter PauseActivity shows the user's own stated reason, a 1/3/5/10-minute cooldown timer, and Cancel / Use anyway choices. REL-04 overnight OEM-survival gate is the phase exit gate.

---

## Phase 4 Verification Map

| Requirement | Description | Stub test file | Fill plan | Status |
|-------------|-------------|----------------|-----------|--------|
| PAUS-01 | AccessibilityService intercepts blocked-app launch via Intent | `test/data/detectors/accessibility_blocked_app_detector_test.dart` | 04-05 | pending |
| PAUS-02 | Reason rendered as hero (D-02 with-reason / D-03 empty) | `test/features/pause/pause_screen_test.dart` | 04-07 | pending |
| PAUS-03 | 1/3/5/10 cooldown chips (D-04 SegmentedButton) | `test/features/pause/pause_screen_test.dart` + `test/features/pause/widgets/cooldown_chip_row_test.dart` | 04-07 | pending |
| PAUS-04 | Auto-close on cooldown end, outcome=0 (D-07) | `test/features/pause/pause_controller_test.dart` | 04-07 | pending |
| PAUS-05 | Cancel button (D-06) writes outcome=1 | `test/features/pause/pause_controller_test.dart` | 04-07 | pending |
| PAUS-06 | Use anyway writes outcome=2 (soft only, CD-02 enabled immediately) | `test/features/pause/pause_controller_test.dart` | 04-07 | pending |
| PAUS-07 | PauseActivity cold-start < 300 ms with FlutterEngineCache pre-warm | `test/features/health/permission_health_provider_a11y_live_test.dart` | 04-06 | pending |
| PAUS-08 | Lock-screen render via setShowWhenLocked + setTurnScreenOn | (Kotlin-side — verified manually in Plan 04-06 acceptance) | 04-06 | pending |
| PAUS-09 | Hard entries omit Use anyway from widget tree | `test/features/pause/pause_screen_test.dart` | 04-07 | pending |
| PAUS-10 | Schedule gate via Kotlin port of isInScheduleWindow (D-12 parity) | `test/domain/schedule/schedule_window_parity_test.dart` | 04-02 + 04-05 | pending |
| REL-01 | Companion FGS NOT shipped (CD-01 disposition) | (Absence-grep — manifest FGS perms declared, no FGS Service subclass) | 04-05 | pending |
| REL-04 | OEM-survival overnight gate — detect-to-pause < 500 ms after 8h idle | `test/features/health/permission_health_provider_a11y_live_test.dart` | 04-08 | pending |

---

## REL-04 OEM-Survival Overnight Gate (CD-03)

**Pass criterion:** detect-to-pause < 500 ms after ≥ 8 h idle on a real Xiaomi or Samsung device.

### Device Acquisition

> **Escalation rule (CD-03):** If no Xiaomi or Samsung is on-hand at sign-off time,
> do NOT silently substitute Pixel + MIUI emulator image. Escalate to discuss-phase
> for a one-time gate relaxation.

- [ ] Real Xiaomi or Samsung confirmed (model __________, OS __________)
- [ ] Device is borrowed-or-owned (not emulator)
- [ ] Charge level at test start: __________
- [ ] Charge level next morning: __________

### Test Procedure

1. Install fresh APK + complete onboarding (enable a11y service when prompted).
2. Add 1 not-to-do app (e.g., `com.android.chrome` — free to test, no cost).
3. Lock the device, then run: `adb shell dumpsys deviceidle force-idle`
4. Wait ≥ 8 h (real overnight — NOT adb-fast-forwarded).
5. Next morning: unlock device + tap the blocked app from the launcher + start stopwatch on first tap.
6. Stop stopwatch when PauseActivity becomes the foreground window.

### Pass Criterion

**detect-to-pause < 500 ms**

| Field | Value |
|-------|-------|
| Device manufacturer | __________ |
| Device model | __________ |
| Android version | __________ |
| Idle duration (hours) | __________ |
| Detect-to-pause (ms) | __________ |
| Test date | __________ |
| Sign-off date | __________ |

### Outcome

**PASS / FAIL / DEFERRED-FOR-DEVICE:** __________

---

## PauseActivity Cold-Start (PAUS-07 software gate)

| Field | Value |
|-------|-------|
| Pixel emulator Android version | stock Android 16 (default — matches Phase 2 + 3 UAT baseline) |
| Measured cold-start (ms) | __________ |
| Pass threshold | 300 ms |

---

## REL-01 Disposition (CD-01)

Phase 4 ships WITHOUT companion FGS. Manifest `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` permissions remain declared (declared-but-unused is fine per CD-01). Revisit only if REL-04 fails.

Evidence: no `Service` subclass added in Phase 4 beyond the existing `NotToDoAccessibilityService`. Verified by absence-grep on `android/app/src/main/kotlin/` for `ForegroundService` / `startForeground(`.

---

## PLAY-02 Forbidden-Token Sweep

`test/policy/play_invariants_test.dart` 8/8 invariants green (verified by Plan 04-08 final gate). `NotToDoAccessibilityService.kt` source MUST contain ZERO occurrences of `performAction(`, `performGlobalAction(`, `dispatchGesture(` — verified by Plan 04-05 acceptance + the cross-tree absence-grep test.

---

*Verification template created Plan 04-01; sign-off fields populated by Plan 04-08.*
