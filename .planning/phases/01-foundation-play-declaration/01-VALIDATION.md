---
phase: 1
slug: foundation-play-declaration
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-27
completed: 2026-04-26
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (bundled with Flutter SDK) |
| **Config file** | `test/` directory at project root; `analysis_options.yaml` extends `very_good_analysis` |
| **Quick run command** | `flutter analyze && flutter test test/data/database/app_database_test.dart -r expanded` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | ~30 s (quick); ~90 s (full) |

---

## Sampling Rate

- **After every task commit:** `flutter analyze && flutter test` (quick)
- **After every plan wave:** Full suite + V1–V14 verification commands
- **Before `/gsd-verify-work`:** All 14 verification commands green + `flutter build apk --debug` succeeds
- **Max feedback latency:** 30 seconds per task

---

## Per-Task Verification Map

> Skeleton — populated as tasks land. Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | (env) | — | Toolchain present | shell | `flutter --version && java -version && sdkmanager --list` | ✅ | ✅ |
| 1-01-02 | 01 | 1 | PLAY-04 | — | `<queries>` element + LAUNCHER intent filter; no `QUERY_ALL_PACKAGES` | static | `grep -q '<queries>' android/app/src/main/AndroidManifest.xml && ! grep -q 'QUERY_ALL_PACKAGES' android/app/src/main/AndroidManifest.xml` | ✅ | ✅ |
| 1-01-03 | 01 | 1 | PLAY-05 | — | Manifest excludes `SYSTEM_ALERT_WINDOW`; PauseActivity is FlutterActivity (declared but stub) | static | `! grep -q 'SYSTEM_ALERT_WINDOW' android/app/src/main/AndroidManifest.xml` | ✅ | ✅ |
| 1-01-04 | 01 | 1 | PLAY-01 | — | A11y config XML sets `isAccessibilityTool="false"` | static | `grep -q 'isAccessibilityTool="false"' android/app/src/main/res/xml/not_todo_a11y_config.xml` | ✅ | ✅ |
| 1-01-05 | 01 | 1 | PLAY-03 | — | Event types scoped to `typeWindowStateChanged` only | static | `grep -q 'accessibilityEventTypes="typeWindowStateChanged"' android/app/src/main/res/xml/not_todo_a11y_config.xml && ! grep -qE 'typeAllMask\|typeViewClicked\|typeViewFocused\|canPerformGestures\|canRetrieveWindowContent\|flagRequestFilterKeyEvents' android/app/src/main/res/xml/not_todo_a11y_config.xml` | ✅ | ✅ |
| 1-02-01 | 02 | 1 | (foundation) | — | Drift schema compiles | unit | `flutter test test/data/database/app_database_test.dart` | ✅ | ✅ |
| 1-02-02 | 02 | 1 | (foundation) | — | Round-trip test passes (insert → query → assert) | unit | `flutter test test/data/database/app_database_test.dart -r expanded` | ✅ | ✅ |
| 1-03-01 | 03 | 1 | PLAY-02 | — | `BlockedAppDetector` interface has no `performAction`/`dispatchGesture`/`performGlobalAction` | static | `! grep -qE 'performAction\|dispatchGesture\|performGlobalAction' lib/domain/blocked_app_detector.dart` | ✅ | ✅ |
| 1-03-02 | 03 | 1 | REL-05 | — | Riverpod selector switches concrete type when flag flips | unit | `flutter test test/domain/providers/blocked_app_detector_provider_test.dart` | ✅ | ✅ |
| 1-04-01 | 04 | 1 | PLAY-07 | — | `docs/play-declaration.md` exists, non-empty | static | `test -s docs/play-declaration.md` | ✅ | ✅ |
| 1-04-02 | 04 | 1 | PLAY-09 | — | `docs/data-safety.md` exists, declares zero collection | static | `test -s docs/data-safety.md && grep -q "no data collected\|Data Collected: None" docs/data-safety.md` | ✅ | ✅ |
| 1-04-03 | 04 | 1 | PLAY-09, SETT-03 | — | No telemetry / FCM / analytics SDKs in dep tree | static | `! flutter pub deps \| grep -iE "firebase\|fcm\|analytics\|crashlytics\|amplitude\|mixpanel\|segment"` | ✅ | ✅ |
| 1-04-04 | 04 | 1 | SETT-03 | — | No `INTERNET` permission in manifest | static | `! grep -q 'android.permission.INTERNET' android/app/src/main/AndroidManifest.xml` | ✅ | ✅ |
| 1-05-01 | 05 | 2 | (foundation) | — | App boots to empty home in debug build | shell | `flutter build apk --debug` | ✅ | ✅ |

---

## Wave 0 Requirements

- [ ] **Toolchain install** — Flutter SDK 3.41.x stable, JDK 17 (Temurin), Android command-line tools, platform-36 + build-tools-36 + cmdline-tools-latest. Without these, no test in this matrix can run.
- [ ] `analysis_options.yaml` — extends `very_good_analysis ^7.0.0`.
- [ ] `test/data/database/app_database_test.dart` — Drift schema round-trip stub for foundation.
- [ ] `test/domain/providers/blocked_app_detector_provider_test.dart` — REL-05 stub.
- [ ] `tool/pigeon.sh` — codegen helper.
- [ ] `pigeons/usage_api.dart`, `pigeons/accessibility_api.dart`, `pigeons/notification_api.dart` — interface stubs (codegen runs once to lock generated signatures).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `docs/play-declaration.md` reads as literal mechanical Play Console copy | PLAY-07 | Subjective: "is the language right for a reviewer?" | Have user read the doc and confirm it mirrors the Use-of-AccessibilityService policy lane (rule-based, non-autonomous, never `performAction`/`dispatchGesture`). Sign off in `docs/play-declaration.md` footer. |
| `docs/data-safety.md` matches the actual code | PLAY-09 | Cross-check between document claims and implementation requires human reading of both | After dep audit (V10) is green, user reads doc and confirms "Data Collected: None" matches `flutter pub deps` output. |
| App boots to an empty list screen on a real Android device | (success criterion #1) | Subjective UX check — simulator can lie about build success | `flutter run -d <device>`; user verifies the app launches and shows an empty list scaffold. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are explicitly listed under Wave 0 dependencies above
- [ ] Sampling continuity: no 3 consecutive tasks without an automated verify
- [ ] Wave 0 covers all MISSING references (toolchain + lints + test stubs + Pigeon inputs)
- [ ] No watch-mode flags (`flutter test --watch`, `dart run build_runner watch` are forbidden in CI gates)
- [ ] Feedback latency < 30 s for the quick command
- [ ] `nyquist_compliant: true` set in frontmatter once planner finishes and all task IDs above are filled in

**Approval:** granted (auto) — 2026-04-26 — V1–V14 + SETT-03 all green; `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk` (171.6 MB).
