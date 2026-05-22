---
phase: 05-streak-engine-daily-reminder
status: software_complete
nyquist_compliant: true
wave_0_complete: true
wave_1_complete: true
wave_2_complete: true
wave_3_complete: true
wave_4_complete: false
rel_05_status: pending_overnight_run
rel_05_device_class: TBD
rel_05_device_model: TBD
rel_05_alarm_fire_delta_minutes: TBD
rel_05_boot_completed_re_arm: TBD
rel_05_pass_date: TBD
---

# Phase 5 Verification — Streak Engine & Daily Reminder

**Phase goal:** Deliver an honest per-item streak engine (system-threshold + daily self-report hybrid) and a single daily reminder at the user's chosen time. REL-05 overnight OEM-survival gate is the phase exit gate (mirrors REL-04 from Phase 4, upgraded for AlarmManager exact-alarm + BOOT_COMPLETED re-arm).

---

## Phase 5 Verification Map

| Requirement | Description | Stub test file | Fill plan | Status |
|-------------|-------------|----------------|-----------|--------|
| STRK-01 | Per-item streak counter, upsert idempotent per (entryId, day) | `test/data/dao/daily_streak_dao_test.dart` | 05-02 | Wave 0 stub |
| STRK-02 | Streak auto-breaks when usage > threshold | `test/domain/streak/streak_rollover_service_test.dart` | 05-03 | Wave 0 stub |
| STRK-03 | One check-in per entry per day (UNIQUE) | `test/data/dao/daily_checkins_dao_test.dart` | 05-02 | Wave 0 stub |
| STRK-04 | System-confirmed vs self-reported-only source labels | `test/domain/streak/streak_rollover_service_test.dart` | 05-03 | Wave 0 stub |
| STRK-05 | Lazy roll-over on every app open — no WorkManager periodic | `test/policy/phase_5_invariants_test.dart` | 05-03 | Wave 0 (REAL — passes today) |
| STRK-06 | Clock-tamper > 24h → status=2 incomplete-data | `test/domain/streak/streak_rollover_service_test.dart` | 05-03 | Wave 0 stub |
| STRK-07 | Home shows current + longest streak per entry | `test/features/streak/streak_badge_test.dart` | 05-07 | Wave 0 stub |
| STRK-08 | DST 23h and 25h day correctness | `test/domain/streak/streak_rollover_dst_test.dart` | 05-03 | Wave 0 stub |
| STRK-09 | Scheduled entries — only in-window usage counts | `test/domain/streak/streak_rollover_service_test.dart` | 05-03 | Wave 0 stub |
| STRK-09 parity | Kotlin parity for streak day-anchoring (JVM oracle) | `android/.../service/StreakDayAnchoringTest.kt` | 05-03 | Wave 0 stub (@Ignore) |
| NOTF-01 | User configures daily reminder time in Settings (24h selector) | `test/features/reminder/reminder_settings_test.dart` | 05-08 | Wave 0 stub |
| NOTF-02 | Reminder fires at chosen time | manual (real device) | 05-09 | manual-only |
| NOTF-03 | Tap notification deep-links to /checkin | `test/features/reminder/deep_link_navigation_test.dart` | 05-05 | Wave 0 stub |
| NOTF-04 | Fires within 5 min even under Doze | manual (real device) | 05-09 | manual-only |
| NOTF-05 | BOOT_COMPLETED re-arm via BootReceiver | `test/policy/phase_5_invariants_test.dart` | 05-05 | Wave 0 stub (skip until Plan 05-05) |
| NOTF-06 | POST_NOTIFICATIONS earned prompt after first entry | `test/features/onboarding/post_notifications_earned_test.dart` | 05-08 | Wave 0 stub |
| NOTF-07 | If denied, in-app banner "Reminder is off — tap to fix" | `test/features/home/reminder_off_banner_test.dart` | 05-07 | Wave 0 stub |
| REL-05 | Overnight OEM survival (Xiaomi or Samsung) | REL-05 protocol below | 05-09 | manual-only |
| Policy invariants | no FCM / Firebase / WorkManager-periodic / USE_EXACT_ALARM | `test/policy/phase_5_invariants_test.dart` | 05-01 (Wave 0) | REAL — passes today |

---

## REL-05 OEM-Survival Overnight Gate

**Pass criterion:** Reminder notification fires within 5 minutes of scheduled time after ≥ 8 h idle on a real Xiaomi or Samsung device. Tap on notification opens `/checkin`. Next-day reminder fires after BOOT_COMPLETED re-arm.

**Device class:** Xiaomi (MIUI/HyperOS) or Samsung (OneUI) — either OEM qualifies. Device model, Android version, and results filled by user when running the test.

**Status:** `pending_overnight_run` — target after Plan 05-09 software-complete.

### Test Protocol (copy-pasteable)

1. Build and install the APK:
   ```
   flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

2. Open the app. Add at least 1 entry to the not-to-do list. Grant `POST_NOTIFICATIONS` via the earned prompt. Open Settings inside the app → set reminder for T+2 minutes (e.g. if it is 20:00, set to 20:02).

3. Force the device into idle Doze:
   ```
   adb shell dumpsys deviceidle force-idle
   ```

4. Unplug USB, lock the screen, leave idle ≥ 8 hours overnight.

5. Plug back in next morning. Do NOT unlock the device yet.

6. **NOTF-04 gate:** Confirm notification fires within 5 minutes of the scheduled time. Record the delta in minutes.

7. **NOTF-03 gate:** Tap the notification. Assert the `/checkin` screen appears inside the app.

8. **NOTF-05 gate (BOOT_COMPLETED re-arm):** Reboot the device:
   ```
   adb reboot
   ```

9. Wait one full day. Set reminder for T+2 min on the next day. Confirm the next-day reminder fires (BOOT_COMPLETED re-armed the alarm after reboot).

**Pass criterion summary:**
- Alarm fires within 5 minutes of scheduled time (NOTF-04)
- Tapping notification opens `/checkin` (NOTF-03)
- BOOT_COMPLETED re-arm fires next-day reminder (NOTF-05)

### Device Record (fill when running)

| Field | Value |
|-------|-------|
| Device manufacturer | TBD |
| Device model | TBD |
| Android version | TBD |
| OEM UI version | TBD |
| Idle duration (hours) | TBD |
| Alarm fire delta (minutes from scheduled) | TBD |
| BOOT_COMPLETED re-arm outcome | TBD |
| Test date | TBD |
| REL-05 pass date | TBD |
| Sign-off | TBD |

### Outcome

**PASS / FAIL / pending_overnight_run:** `pending_overnight_run`

---

## Pre-Overnight Verification Snapshot

*Captured 2026-05-22 — Plan 05-09 software-complete; all gates green before REL-05 overnight run.*

| Check | Command | Result |
|-------|---------|--------|
| flutter test (full suite) | `flutter test` | PASS — 487 passing, 5 skipped, 0 failures |
| flutter analyze | `flutter analyze` | PASS — 0 errors / 0 warnings (589 infos, all pre-existing; no new issues from Plan 05-09) |
| flutter build apk --debug | `flutter build apk --debug` | PASS — build/app/outputs/flutter-apk/app-debug.apk |
| PLAY-02 invariants 10/10 | `flutter test test/policy/play_invariants_test.dart` | PASS — 10/10 green (was 9; Plan 05-09 added 10th: android/.../receiver/ scope) |
| Phase 5 invariants | `flutter test test/policy/phase_5_invariants_test.dart` | PASS — 5/5 real passing, 2 manual-only skips (NOTF-02, NOTF-04 — intentional real-device gates) |
| StreakDayAnchoringTest | `cd android && ./gradlew :app:testDebugUnitTest --tests "*.ScheduleWindowTest" --tests "*.StreakDayAnchoringTest"` | PASS — BUILD SUCCESSFUL |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reminder fires at chosen wall-clock time | NOTF-02 | AlarmManager exact-alarm requires real OS scheduling | Set reminder for T+2 min in app → lock device → wait → observe notification |
| Reminder fires within 5 min under Doze | NOTF-04 | Doze only enters after long idle; OEM-specific behavior | `adb shell dumpsys deviceidle force-idle` → set reminder T+2 min → wait → observe |
| BOOT_COMPLETED re-arm | NOTF-05 (manual leg) | Device reboot cannot be simulated in JVM | Reboot device → wait full day → confirm next-day reminder fires |
| REL-05 overnight OEM survival | REL-05 | Real Xiaomi or Samsung device required; OEM kill behavior is hardware-specific | Follow REL-05 protocol above (≥ 8 h unplugged Doze; alarm fires within 5 min; /checkin opens on tap; BOOT_COMPLETED re-arms next day) |

---

*Verification template created Plan 05-01 (Wave 0 skeleton — mirrors 04-VERIFICATION.md).*
*REL-05 protocol fields populated by Plan 05-09 sign-off after overnight run.*
