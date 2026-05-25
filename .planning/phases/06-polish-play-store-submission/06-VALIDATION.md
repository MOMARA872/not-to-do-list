---
phase: 6
slug: polish-play-store-submission
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
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
| 06-XX-XX | XX  | N    | SETT-XX     | —          | TBD             | unit/widget | `flutter test path/...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 creates the RED test scaffold for all Phase 6 behavior before any production code is written. From 06-RESEARCH.md Validation Architecture, 17 test files are required:

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (planner completes)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all 17 RED test files
- [ ] Wave 0 deps installed before any feature task runs
- [ ] No watch-mode flags
- [ ] Feedback latency < 60 s
- [ ] `nyquist_compliant: true` set in frontmatter after per-task verify map is filled

**Approval:** pending
