---
phase: 6
slug: polish-play-store-submission
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
last_updated: 2026-05-24
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from 06-RESEARCH.md Validation Architecture section. The planner is responsible for finalizing per-task rows and flipping `nyquist_compliant: true` after the per-task verify map is complete.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) + project's existing `mocktail` / Drift in-memory pattern |
| **Config file** | `pubspec.yaml` (dev_dependencies block); no separate config |
| **Quick run command** | `flutter test test/features/settings/ test/policy/play_invariants_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~45 s quick / ~3 min full |

---

## Sampling Rate

- **After every task commit:** Run quick command above
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite green + release APK builds clean + APK absence-grep PASS
- **Max feedback latency:** 60 s

---

## Per-Task Verification Map

> The planner fills this table during planning. Each task in each PLAN.md must have an entry here OR a Wave 0 dependency that creates the test scaffold it relies on.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-T1 | 06-01 | 0 | SETT-01 | — | Pubspec dep install + DAO read surface for export | infra/static | `flutter pub get && dart analyze pubspec.yaml lib/data/database/daos/ docs/` | ✅ on landing | ⬜ pending |
| 06-01-T2 | 06-01 | 0 | SETT-01/02/04/05, PLAY-08 | — | 19 RED test stubs + FileSavePort mock fixture | unit/widget scaffold | `flutter test test/features/settings/ test/features/home/home_appbar_settings_action_test.dart test/app/theme_rebuild_test.dart test/policy/apk_telemetry_strings_test.dart test/policy/privacy_policy_url_present_test.dart integration_test/phase6_happy_path_test.dart` | ✅ on landing | ⬜ pending |
| 06-02-T1 | 06-02 | 1 | SETT-04 | — | themeModeProvider AsyncNotifier read/write + decode/encode | unit | `flutter test test/features/settings/theme_mode_provider_test.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-02-T2 | 06-02 | 1 | SETT-04 | — | MaterialApp.router themeMode rebuild on provider change | widget | `flutter test test/app/theme_rebuild_test.dart test/features/settings/theme_mode_provider_test.dart && dart analyze lib/app.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-03-T1 | 06-03 | 2 | SETT-04, SETT-05, PLAY-08 | — | SectionHeader + ThemeTile + AboutTile + StreakThresholdTile widget render | widget | `flutter test test/features/settings/theme_segmented_button_test.dart test/features/settings/about_tile_test.dart && dart analyze lib/features/settings/widgets/` | ✅ W0 06-01 | ⬜ pending |
| 06-03-T2 | 06-03 | 2 | SETT-04, SETT-05, PLAY-08 | — | SettingsScreen tile order + 4 GoRouter routes + placeholder Export/Privacy screens | widget/router | `flutter test test/features/settings/settings_screen_test.dart && dart analyze lib/features/settings/pages/ lib/core/router/app_router.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-03-T3 | 06-03 | 2 | SETT-04, SETT-05, PLAY-08 | — | HomeScreen AppBar gear icon insertion | widget | `flutter test test/features/home/home_appbar_settings_action_test.dart && dart analyze lib/features/home/pages/home_screen.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-04-T1 | 06-04 | 3 | SETT-01 | V5 CSV-injection / file I/O port | FileSavePort port + FlutterFileDialogSavePort impl + mock fixture activation | unit | `flutter test test/features/settings/file_save_port_test.dart && dart analyze lib/features/settings/services/file_save_port.dart lib/domain/providers/file_save_port_provider.dart test/_fixtures/file_save_port_mock.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-04-T2 | 06-04 | 3 | SETT-01 | V5 CSV-injection | ExportController DAO reads + CSV escape + JSON envelope + ZIP build | unit | `flutter test test/features/settings/export_controller_test.dart test/features/settings/export_csv_format_test.dart test/features/settings/export_json_envelope_test.dart && dart analyze lib/features/settings/services/export_controller.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-04-T3 | 06-04 | 3 | SETT-01 | Pitfall 3 cancel/error | ExportScreen widget + SAF cancel/error SnackBar | widget | `flutter test test/features/settings/ && dart analyze lib/features/settings/pages/export_screen.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-05-T1 | 06-05 | 3 | SETT-02 | Pitfall 2 transactional wipe | ResetController transactional wipe + alarm cancel + provider invalidation | unit | `flutter test test/features/settings/reset_controller_test.dart && dart analyze lib/features/settings/services/reset_controller.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-05-T2 | 06-05 | 3 | SETT-02 | D-13 verbatim copy | Reset AlertDialog verbatim body + cs.error FilledButton + ResetController invocation | widget | `flutter test test/features/settings/reset_dialog_test.dart test/features/settings/reset_controller_test.dart && dart analyze lib/features/settings/pages/settings_screen.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-06-T1 | 06-06 | 3 | SETT-05 | Pitfall 6 no external links | PrivacyScreen FutureBuilder + Markdown render of bundled PRIVACY.md | widget | `flutter test test/features/settings/privacy_screen_test.dart && dart analyze lib/features/settings/pages/privacy_screen.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-06-T2 | 06-06 | 3 | SETT-05, PLAY-08 | RESEARCH §Pattern 5 nav-branch | AccessibilityStep fromSettings param + nav-branch fork (5 verbatim phrases preserved) | widget/policy | `flutter test test/features/settings/disclosure_route_test.dart test/features/onboarding/prominent_disclosure_test.dart test/policy/play_invariants_test.dart && dart analyze lib/features/onboarding/pages/accessibility_step.dart lib/core/router/app_router.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-07-T1 | 06-07 | 4 | PLAY-08 | PLAY-09 telemetry absence (Spoofing/Info-disclosure) | play_invariants extension + apk_telemetry_strings + privacy_policy_url_present activation | policy/static | `flutter test test/policy/play_invariants_test.dart test/policy/apk_telemetry_strings_test.dart test/policy/privacy_policy_url_present_test.dart` | ✅ W0 06-01 | ⬜ pending |
| 06-07-T2 | 06-07 | 4 | PLAY-08 | D-15 Play App Signing | pubspec version bump 1.0.0+1 + build.gradle.kts Play App Signing comment | static | `grep -qF 'version: 1.0.0+1' pubspec.yaml && grep -qF 'Play App Signing' android/app/build.gradle.kts && flutter pub get` | ✅ on landing | ⬜ pending |
| 06-08-T1 | 06-08 | 5 | SETT-05, PLAY-07, PLAY-08 | Pitfall 1 declaration-vs-in-app | Final PRIVACY.md + docs/play-listing/ asset tree + onboarding README | static + widget regression | `test "$(wc -c < docs/play-listing/short-description.txt)" -le 80 && test "$(wc -c < docs/play-listing/full-description.txt)" -le 4000 && test -f docs/PRIVACY.md && test -f docs/play-listing/permission-declaration.md && test -f docs/play-listing/screenshots/README.md && test -f docs/play-listing/README.md && test -f assets/onboarding/README.md && grep -F "zero data" docs/PRIVACY.md && flutter test test/policy/privacy_policy_url_present_test.dart` | ✅ on landing | ⬜ pending |
| 06-08-T2 | 06-08 | 5 | PLAY-08 | REL bookend evidence | 06-VERIFICATION.md draft + evidence directory | static | `test -f .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && grep -F "PHASE-6 OEM PASS" .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && grep -F "rel_06_status" .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && grep -F "play_08_status" .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && grep -F "Phase 5 D-08" .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && test -d .planning/phases/06-polish-play-store-submission/evidence` | ✅ on landing | ⬜ pending |
| 06-08-T3a | 06-08 | 5 | PLAY-08 | OEM-survival overnight (Doze + manufacturer profiles) | OEM overnight gate (Samsung + Xiaomi) | **manual** checkpoint:human-action | MANUAL — `PHASE-6 OEM PASS` resume signal; evidence under `.planning/phases/06-polish-play-store-submission/evidence/samsung-*/` + `xiaomi-*/` | n/a (manual gate) | ⬜ pending |
| 06-08-T3b | 06-08 | 5 | PLAY-07, PLAY-08 | Play Console closed-track policy review | Play Internal → Closed submission + review verdict + GitHub Pages + demo video | **manual** checkpoint:human-action | MANUAL — `PLAY-08 CLOSED TRACK PASS` resume signal; evidence: closed-track verdict screenshot + curl 200 + YouTube URL | n/a (manual gate) | ⬜ pending |
| 06-08-T4 | 06-08 | 5 | SETT-01/02/04/05, PLAY-07, PLAY-08 | Bookkeeping closure | REQUIREMENTS/ROADMAP/STATE/06-VERIFICATION flips (gated on 3b PASS) | static | `grep -qF 'PLAY-08' .planning/REQUIREMENTS.md && grep -qF 'PLAY-07' .planning/REQUIREMENTS.md && grep -qF 'completed_phases: 6' .planning/STATE.md && grep -qF 'rel_06_status: pass' .planning/phases/06-polish-play-store-submission/06-VERIFICATION.md && flutter test` | ✅ on landing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 creates the RED test scaffold for all Phase 6 behavior before any production code is written. From 06-RESEARCH.md Validation Architecture, 19 test files are required (17 original + 2 added per plan-checker iteration 1 2026-05-24):

- [ ] `test/features/settings/settings_screen_test.dart` — Settings hub tile rendering, order, gear-icon entry
- [ ] `test/features/settings/theme_mode_provider_test.dart` — AsyncNotifier read/write, default = `ThemeMode.system`, persistence round-trip
- [ ] `test/features/settings/theme_segmented_button_test.dart` — widget test for inline 3-segment selector
- [ ] `test/features/settings/about_tile_test.dart` — `package_info_plus` version surface
- [ ] `test/features/settings/export_controller_test.dart` — ZIP archive contents: 5 CSVs + data.json envelope, schemaVersion 1, ISO-8601 UTC timestamps
- [ ] `test/features/settings/export_csv_format_test.dart` — header row = Drift column names verbatim, CSV escaping
- [ ] `test/features/settings/export_json_envelope_test.dart` — envelope shape, appVersion stamp, table keys
- [ ] `test/features/settings/file_save_port_test.dart` — abstraction over `ACTION_CREATE_DOCUMENT` (mock pattern matching Phase 3/4/5 Pigeon ports)
- [ ] `test/features/settings/reset_controller_test.dart` — Drift transactional wipe across 5 tables in FK-safe order + `shared_preferences.clear()` + `cancelDailyReminder()` + provider invalidation order
- [ ] `test/features/settings/reset_dialog_test.dart` — literal body copy, Cancel default-focused, calm-tone source-grep
- [ ] `test/features/settings/privacy_screen_test.dart` — bundled `assets/PRIVACY.md` renders via `flutter_markdown_plus`
- [ ] `test/features/settings/disclosure_route_test.dart` — `/settings/disclosure` wraps `accessibility_step.dart` with `fromSettings: true` → Cancel/Done pops instead of pushing `/onboarding/permissions/battery-opt`
- [ ] `test/features/home/home_appbar_settings_action_test.dart` — gear icon present, routes to `/settings`
- [ ] `test/policy/play_invariants_test.dart` — **extend** with `firebase|crashlytics|analytics|FCM|RemoteConfig` absence-grep across `pubspec.lock`, Dart sources, Kotlin sources
- [ ] `test/policy/apk_telemetry_strings_test.dart` — decoded release APK `classes*.dex strings | grep -iE '(firebase|crashlytics|analytics|fcm|remoteconfig)'` returns no matches (uses `Process.runSync('sh', ['-c', ...])`)
- [ ] `test/policy/privacy_policy_url_present_test.dart` — verifies `docs/PRIVACY.md` exists and Settings → Privacy screen links to public URL constant
- [ ] `integration_test/phase6_happy_path_test.dart` — overnight checklist (manual, but documented as runnable script for the REL bookend)
- [ ] `test/app/theme_rebuild_test.dart` — MaterialApp.router themeMode rebuild on themeModeProvider change (Test 1-3 from 06-02)
- [ ] `test/features/settings/export_screen_test.dart` — ExportScreen widget render + save flow (from 06-04 Task 3)

**Pubspec dep installs (Wave 0):**
- [ ] `archive: ^4.0.9`
- [ ] `flutter_file_dialog: ^3.0.3`
- [ ] `flutter_markdown_plus: ^1.0.7`
- [ ] `package_info_plus: ^10.1.0`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Export ZIP opens cleanly in Excel/Sheets/text editor; 5 CSVs + data.json present | SETT-01 | Real SAF intent + external app round-trip cannot be unit-tested | (a) Run app on device, Settings → Export, pick Downloads, name file. (b) Pull via `adb pull`, unzip, open each CSV in LibreOffice; (c) `jq .schemaVersion data.json` returns `1` |
| Reset → /onboarding/welcome with no flashing of pre-reset state | SETT-02 | Visual race-window check | Record screen, confirm no glimpse of home with stale data between dialog dismiss and onboarding load |
| Theme switch effect on dynamic_color seed | SETT-04 | Material You is Android-12+ device-only | Test on Pixel (dynamic-color) AND Samsung (fallback seed); confirm theme selector flips brightness only, seed source unchanged |
| Privacy Policy GitHub Pages URL renders publicly | SETT-05 / PLAY-08 | External web infrastructure | Open URL in private-browser tab, confirm rendered Markdown matches `docs/PRIVACY.md` |
| Play Console Permission Declaration form acceptance | PLAY-08 | Human reviewer at Google | Submit Internal track → no rejection. Then submit Closed track → policy review PASS (no AccessibilityService rejection, no `<queries>` rejection, no Data Safety mismatch, no battery-opt justification rejection) |
| Data Safety form ML cross-check pass | PLAY-08 | Google's ML scanner | Submit form declaring zero data collected; confirm no warning in Play Console after upload + scan |
| OEM-survival overnight exit gate (Phase 6 success criterion 5) | PLAY-08 + ROADMAP | Real-device Doze + manufacturer power profiles | Full happy-path on real Xiaomi AND real Samsung overnight (≥8 h unplugged). Mirror Phase 4 REL-04 evidence pattern: logcat, screenshots, time-stamped run notes saved to 06-VERIFICATION.md |
| Demo video URL for AccessibilityService form | PLAY-08 | Required field for 2026 Play Console form | Record ≤90s demo showing app's AccessibilityService usage matches declared purpose; upload to unlisted YouTube; URL into form |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (planner completes — filled per checker iteration 1 2026-05-24)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (manual 3a/3b are checkpoint:human-action by design, with automated 3a pre-flight + 4 bookkeeping bracket)
- [x] Wave 0 covers all 19 RED test files (was 17; +theme_rebuild_test.dart +export_screen_test.dart per checker iteration 1)
- [x] Wave 0 deps installed before any feature task runs
- [x] No watch-mode flags
- [x] Feedback latency < 60 s
- [x] `nyquist_compliant: true` set in frontmatter after per-task verify map is filled

**Approval:** approved 2026-05-24 plan-checker iteration 1
