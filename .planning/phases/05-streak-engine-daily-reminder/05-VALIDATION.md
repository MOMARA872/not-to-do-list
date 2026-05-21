---
phase: 5
slug: streak-engine-daily-reminder
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-21
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from `05-RESEARCH.md` §9 Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter 3.41 / Dart 3.5) + `mocktail ^1.0.5`; Kotlin side: JUnit 4.13.2 via `./gradlew :app:test` |
| **Config file** | `pubspec.yaml` (dev_dependencies); `analysis_options.yaml` (`very_good_analysis ^10.2.0`); `android/app/build.gradle.kts` (testImplementation JUnit 4) |
| **Quick run command** | `flutter test test/policy/play_invariants_test.dart test/policy/phase_5_invariants_test.dart test/features/streak/ test/features/checkin/ test/features/reminder/ test/domain/streak/ test/data/dao/daily_streak_dao_test.dart test/data/dao/daily_checkins_dao_test.dart` |
| **Full suite command** | `flutter test` + `cd android && ./gradlew :app:testDebugUnitTest` |
| **Estimated runtime** | ~20 s (Phase 5 surface) / ~140 s (full Dart suite) |

---

## Sampling Rate

- **After every task commit:** Run quick command (< 30 s)
- **After every plan wave:** Run full suite (< 140 s)
- **Before `/gsd:verify-work`:** Full suite green + `flutter analyze` 0 errors / 0 warnings + REL-05 PASS on real Xiaomi or Samsung device
- **Max feedback latency:** < 30 s (Phase 5 surface)

---

## Per-Task Verification Map

> Populated by `gsd-planner` once plan tasks exist. Each task in `05-*-PLAN.md` must include an automated verify command OR be tagged manual with REL-05 / NOTF-02 / NOTF-04 justification.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _populated by planner_ | | | | | | | | | ⬜ pending |

---

## Phase Requirements → Test Map (from RESEARCH §9)

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| **STRK-01** | per-item streak counter | unit (DAO) | `flutter test test/data/dao/daily_streak_dao_test.dart` | ❌ W0 |
| **STRK-02** | auto-break at 5-min/day threshold | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_breaks_when_usage_exceeds_threshold` | ❌ W0 |
| **STRK-03** | one check-in per entry per day (UNIQUE) | unit (DAO) | `flutter test test/data/dao/daily_checkins_dao_test.dart::test_upsert_idempotent_per_entry_per_day` | ❌ W0 |
| **STRK-04** | system-confirmed vs self-reported-only labels | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_source_resolution_matrix` | ❌ W0 |
| **STRK-05** | lazy on app open, no scheduled job | unit (policy absence-grep) | `flutter test test/policy/phase_5_invariants_test.dart::test_no_workmanager_periodic_for_streak` | ❌ W0 |
| **STRK-06** | clock-tamper > 24 h → incomplete-data | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_clock_tamper_flags_status_2` | ❌ W0 |
| **STRK-07** | home shows current + longest streak | widget | `flutter test test/features/home/widgets/streak_badge_test.dart` | ❌ W0 |
| **STRK-08** | DST 23h + 25h day correctness | unit (service) | `flutter test test/domain/streak/streak_rollover_dst_test.dart::test_spring_forward_23h_day test_fall_back_25h_day` | ❌ W0 |
| **STRK-09** | scheduled entries — only in-window usage counts | unit (service) | `flutter test test/domain/streak/streak_rollover_service_test.dart::test_scheduled_window_anchoring` | ❌ W0 |
| **STRK-09 parity** | Kotlin parity for streak day-anchoring | unit (JVM) | `cd android && ./gradlew :app:testDebugUnitTest --tests "*.StreakDayAnchoringTest"` | ❌ W0 |
| **NOTF-01** | 24-h time picker in Settings | widget | `flutter test test/features/reminder/reminder_settings_test.dart::test_time_picker_persists_to_prefs` | ❌ W0 |
| **NOTF-02** | reminder fires at chosen time | manual | logcat dump + adb time-mock OR real-device wait | manual-only |
| **NOTF-03** | tap deep-links to `/checkin` | widget + Pigeon mock | `flutter test test/features/reminder/deep_link_navigation_test.dart::test_pending_deep_link_routes_to_checkin` | ❌ W0 |
| **NOTF-04** | fires within 5 min even under Doze | manual | `adb shell dumpsys deviceidle force-idle` + wait + observe | manual-only |
| **NOTF-05** | `BOOT_COMPLETED` re-arm | unit policy + manual | `flutter test test/policy/phase_5_invariants_test.dart::test_boot_receiver_declared` + manual reboot test | ❌ W0 |
| **NOTF-06** | earned prompt after first entry | widget | `flutter test test/features/onboarding/post_notifications_earned_test.dart::test_prompt_fires_on_first_insert` | ❌ W0 |
| **NOTF-07** | denied → in-app banner | widget | `flutter test test/features/home/reminder_off_banner_test.dart::test_banner_visible_when_denied test_banner_hidden_when_granted` | ❌ W0 |
| **REL-05** | overnight OEM survival (Xiaomi or Samsung) | manual (real device) | `05-VERIFICATION.md` REL-05 protocol | manual-only |
| **Policy invariants** | no FCM / no Firebase / no WorkManager-periodic-for-streak / BootReceiver declared / no `USE_EXACT_ALARM` | unit (policy absence-grep) | `flutter test test/policy/play_invariants_test.dart test/policy/phase_5_invariants_test.dart` | ❌ W0 (extend existing) |

---

## Wave 0 Requirements

- [ ] `test/data/dao/daily_streak_dao_test.dart` — covers STRK-01, upsert idempotency
- [ ] `test/data/dao/daily_checkins_dao_test.dart` — covers STRK-03, upsert idempotency
- [ ] `test/domain/streak/streak_rollover_service_test.dart` — covers STRK-02, STRK-04, STRK-06, STRK-09 (2×2 status/source matrix)
- [ ] `test/domain/streak/streak_rollover_dst_test.dart` — covers STRK-08 (23 h + 25 h days with mocked `DateTime`)
- [ ] `test/features/streak/streak_badge_test.dart` — covers STRK-07 + D-15 day-0 rendering + D-05 strikethrough
- [ ] `test/features/streak/streak_history_section_test.dart` — covers D-07 four-dot states + grey tooltip mandatory
- [ ] `test/features/checkin/checkin_screen_test.dart` — covers D-02 + D-03 single-submit + idempotency (D-01)
- [ ] `test/features/reminder/reminder_settings_test.dart` — covers NOTF-01 time picker
- [ ] `test/features/reminder/deep_link_navigation_test.dart` — covers NOTF-03
- [ ] `test/features/onboarding/post_notifications_earned_test.dart` — covers NOTF-06
- [ ] `test/features/home/reminder_off_banner_test.dart` — covers NOTF-07
- [ ] `test/policy/phase_5_invariants_test.dart` — absence-grep for FCM, Firebase, WorkManager-periodic-for-streak, BootReceiver manifest declaration, no `USE_EXACT_ALARM`
- [ ] `test/_fixtures/streak_fixture.dart` — shared mock `(usageMinutes, checkin, a11yWasOn) → (status, source)` tuples for the 2×2 matrix
- [ ] `android/app/src/test/.../StreakDayAnchoringTest.kt` — Kotlin parity for cross-midnight day-anchoring (mirrors Phase 4 `ScheduleWindowTest.kt`)
- [ ] `.planning/phases/05-streak-engine-daily-reminder/05-VERIFICATION.md` — REL-05 overnight gate protocol (mirror Phase 4 REL-04 9-step procedure for Xiaomi or Samsung)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reminder fires at chosen wall-clock time | NOTF-02 | `AlarmManager.setExactAndAllowWhileIdle` requires real OS scheduling; instrumented tests cannot mock the system alarm queue reliably | Set reminder for T+2 min in app → lock device → wait → observe notification |
| Reminder fires within 5 min under Doze | NOTF-04 | Doze enters only after long idle; behaviour is OS-OEM-specific | `adb shell dumpsys deviceidle force-idle` → set reminder T+2 min → wait → observe |
| BOOT_COMPLETED re-arm | NOTF-05 (manual leg) | Device reboot cannot be simulated in JVM | Reboot device → wait full day → confirm next-day reminder fires |
| REL-05 overnight OEM survival | REL-05 | Real Xiaomi or Samsung device required; OEM kill behaviour is hardware-specific | Follow `05-VERIFICATION.md` REL-05 protocol (≥ 12 h unplugged Doze; reminder fires within 5 min; streak rolls over) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify OR Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (15 files listed above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30 s on quick run
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (set on Wave 0 RED stubs landed + planner Per-Task table populated)
