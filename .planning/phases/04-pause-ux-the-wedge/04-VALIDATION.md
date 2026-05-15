---
phase: 4
slug: pause-ux-the-wedge
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-15
reconstructed_from: artifacts
---

# Phase 4 — Validation Strategy

Reconstructed retroactively from PLAN/SUMMARY artifacts. Wave 0 test scaffold landed in Plan 04-01 (11 RED stubs + fixture). Five Phase-4-specific source-policy invariants added 2026-05-15 to close MISSING gaps (PAUS-01, PAUS-08, REL-01, T-02, T-03). Remaining MANUAL-ONLY items (PAUS-07 cold-start, REL-04 OEM-survival) are device-bound by nature and tracked in `04-VERIFICATION.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter 3.41 / Dart 3.5) + `mocktail ^1.0.5`; Kotlin side: JUnit 4.13.2 via `./gradlew :app:test` |
| **Config file** | `pubspec.yaml` (dev_dependencies); `analysis_options.yaml` (`very_good_analysis ^10.2.0`); `android/app/build.gradle.kts` (testImplementation JUnit 4) |
| **Quick run command** | `flutter test test/policy/play_invariants_test.dart test/policy/phase_4_invariants_test.dart test/features/pause/` |
| **Full suite command** | `flutter test` + `cd android && ./gradlew :app:testDebugUnitTest` |
| **Estimated runtime** | ~15 s (Phase 4 surface) / ~120 s (full Dart suite, excludes `dashboard_render_test.dart` perf flake) |

---

## Sampling Rate

- **After every task commit:** quick command
- **After every plan wave:** full suite
- **Before `/gsd-verify-work`:** full suite must be green; `flutter analyze` 0 errors / 0 warnings
- **Max feedback latency:** < 30 s (Phase 4 surface)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 0 | PAUS-01..10 + REL-04 | — | 11 RED stubs + D-11 fixture constants | unit | `flutter test test/_fixtures/ test/features/pause/ test/data/repositories/blocklist_broadcast_test.dart test/data/detectors/accessibility_blocked_app_detector_test.dart test/data/repositories/pause_event_repository_test.dart test/domain/schedule/schedule_window_parity_test.dart test/features/health/permission_health_provider_a11y_live_test.dart` | ✅ | ✅ green |
| 04-01-02 | 01 | 0 | REL-04 | — | overnight-gate sign-off template | manual | `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` exists | ✅ | ✅ green |
| 04-02-01 | 02 | 1 | PAUS-10 | T-01 | Dart parity oracle, 201 deterministic tuples (cross-midnight, DST-safe) | unit | `flutter test test/domain/schedule/schedule_window_parity_test.dart` | ✅ | ✅ green |
| 04-02-02 | 02 | 1 | PAUS-10 | T-01 | Kotlin `isInScheduleWindow` port — byte-for-byte parity with Dart | unit (JVM) | `cd android && ./gradlew :app:testDebugUnitTest` | ✅ | ✅ green |
| 04-02-03 | 02 | 1 | PAUS-10 | T-01 | 200 `assertEquals` parity assertions (18 `@Test` methods) | unit (JVM) | `cd android && ./gradlew :app:testDebugUnitTest --tests "*.ScheduleWindowTest"` | ✅ | ✅ green |
| 04-03-01 | 03 | 1 | (foundation) | T-4-03-01 | `AccessibilityApiImpl.isServiceEnabled` matches by full FQCN (spoofing mitigation) | unit | `flutter test test/features/health/permission_health_provider_a11y_live_test.dart` | ✅ | ✅ green |
| 04-03-02 | 03 | 1 | (foundation, PAUS-07) | T-4-03-03 | FlutterEngine pre-warm in `MainActivity.onCreate` with null-guard against duplication | manual / build | `cd android && ./gradlew :app:compileDebugKotlin` | ✅ | ✅ green |
| 04-04-01 | 04 | 2 | (foundation) | T-01, T-04 | `BlocklistBroadcastApi` Pigeon schema (no reasonNote PII in snapshot DTO) | unit | `flutter test test/data/repositories/blocklist_broadcast_test.dart` | ✅ | ✅ green |
| 04-04-02 | 04 | 2 | (foundation) | T-01 | `LocalBroadcastManager` + `Intent.setPackage()` defence-in-depth (in-process only) | manual / build | `cd android && ./gradlew :app:compileDebugKotlin` | ✅ | ✅ green |
| 04-04-03 | 04 | 2 | (foundation) | T-01 | Repository emit hook + detector body (REL-05 preserved, `detections = Stream.empty()`) | unit | `flutter test test/data/repositories/blocklist_broadcast_test.dart test/data/detectors/accessibility_blocked_app_detector_test.dart test/domain/providers/blocked_app_detector_provider_test.dart` | ✅ | ✅ green |
| 04-05-01 | 05 | 2 | PAUS-01, REL-01 | T-01..T-05 | Service body: `TYPE_WINDOW_STATE_CHANGED` only, 800 ms debounce, in-memory blockMap, no SQLite, no FGS, no forbidden a11y APIs, explicit-component Intent launch | unit (policy) | `flutter test test/policy/play_invariants_test.dart test/policy/phase_4_invariants_test.dart` | ✅ | ✅ green |
| 04-05-02 | 05 | 2 | PAUS-10 (D-10 refresh) | T-01 | `republishCurrent()` on `AppLifecycleState.resumed` — D-10 resume-refresh chain closed | unit / build | `flutter test test/features/health/ && cd android && ./gradlew :app:compileDebugKotlin` | ✅ | ✅ green |
| 04-06-01 | 06 | 3 | PAUS-07, PAUS-08 | T-02, T-03 | Lock-screen flags before super.onCreate; fail-closed extras validation; `provideFlutterEngine` reads cache; `getInitialRoute` builds /pause route | unit (policy) | `flutter test test/policy/phase_4_invariants_test.dart` | ✅ | ✅ green |
| 04-07-01 | 07 | 3 | (PAUS-04..06 prep) | T-04 | `PauseEventDao` + `PauseEventRepository` — D-13 single-writer, insert-at-end | unit | `flutter test test/data/repositories/pause_event_repository_test.dart` | ✅ | ✅ green |
| 04-07-02 | 07 | 3 | PAUS-04, PAUS-05, PAUS-06 | T-04 | `PauseController`: cooldown timer, outcome resolution, 1500 ms auto-close; CR-02 isComplete guard; WR-05 fakeAsync drain → outcome=0 | unit | `flutter test test/features/pause/pause_controller_test.dart` | ✅ | ✅ green |
| 04-07-03 | 07 | 3 | PAUS-02, PAUS-03, PAUS-09 | — | `PauseScreen` D-01..D-08 widget tree; hard entries OMIT Use anyway from tree (D-06/PAUS-09) | unit (widget) | `flutter test test/features/pause/pause_screen_test.dart test/features/pause/widgets/` | ✅ | ✅ green |
| 04-08-01 | 08 | 4 | REL-04 (router seam) | — | `/pause/:entryId` GoRoute appended to `app_router.dart`; Phase 2 onboarding redirect preserved | unit | `flutter test test/features/health/permission_health_provider_a11y_live_test.dart` | ✅ | ✅ green |
| 04-08-02 | 08 | 4 | (cross-tree) | T-05 (PLAY-02) | 9th PLAY-02 invariant — `android/.../service/` + root `android/.../not_to_do_list/` Kotlin scope | unit (policy) | `flutter test test/policy/play_invariants_test.dart` | ✅ | ✅ green |
| 04-08-03 | 08 | 4 | REL-04 | — | OEM-survival overnight protocol documented in `04-VERIFICATION.md` (copy-pasteable 9-step Samsung procedure) | manual | `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` Test Protocol section | ✅ | ⚠️ pending_overnight_run |
| post-CR | 07 | 3 | PAUS-04 (drain), CR-02 | T-02 | `fakeAsync` timer drain to outcome=0 + idempotent second-write guard (memory 2746-2747) | unit | `flutter test test/features/pause/pause_controller_test.dart` (WR-05 group) | ✅ | ✅ green |
| post-CR | 08 | 4 | (T-02 reinforcement) | T-02 | GoRouter `blockMode` fail-closed (CR-01 fix — no fail-open default) | unit | `flutter test test/features/pause/pause_screen_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/manual-pending*

---

## Wave 0 Requirements

Wave 0 (Plan 04-01) shipped 11 RED stubs + `pause_intent_fixture.dart` + REL-04 sign-off template. All stubs flipped to real tests during Waves 1–4. No outstanding Wave-0 items remain.

- ✅ `test/_fixtures/pause_intent_fixture.dart` — D-11 Intent extras as compile-time constants
- ✅ `test/platform/accessibility_api_test.dart` — `MockAccessibilityApi` (reused; placeholder skip is fixture-only)
- ✅ `test/data/repositories/blocklist_broadcast_test.dart` — 3 real tests
- ✅ `test/data/repositories/pause_event_repository_test.dart` — 3 real tests
- ✅ `test/data/detectors/accessibility_blocked_app_detector_test.dart` — 3 real tests
- ✅ `test/domain/schedule/schedule_window_parity_test.dart` — 201 tuples
- ✅ `test/features/pause/pause_screen_test.dart` — 4 tests
- ✅ `test/features/pause/widgets/cooldown_chip_row_test.dart` — 2 tests
- ✅ `test/features/pause/widgets/cooldown_progress_bar_test.dart` — 2 tests
- ✅ `test/features/pause/widgets/done_confirmation_card_test.dart` — 1 test
- ✅ `test/features/pause/pause_controller_test.dart` — 5 tests + 2 WR-05 fakeAsync tests
- ✅ `test/features/health/permission_health_provider_a11y_live_test.dart` — 2 tests
- ✅ `.planning/phases/04-pause-ux-the-wedge/04-VERIFICATION.md` — REL-04 sign-off template

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PauseActivity cold-start < 300 ms with cached `pause_engine` | PAUS-07 | Performance budget measured on real hardware via `adb logcat -e PauseActivity` timestamp diff — unit-testable only as cache-hit grep (already covered by `provideFlutterEngine` source); the 300 ms ceiling is a wall-clock constraint | 1. `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`. 2. `adb logcat -c`. 3. Trigger pause by opening a blocked app on a Pixel emulator. 4. Read PauseActivity onCreate → first Flutter frame timestamps in logcat. 5. Diff < 300 ms. Record in `04-VERIFICATION.md` Notes. |
| OEM-survival detect-to-pause < 500 ms after ≥ 8 h idle on Samsung/Xiaomi | REL-04 / CD-03 | Overnight Doze-survival cannot be simulated reliably in unit tests; depends on real OEM scheduler behaviour | See copy-pasteable 9-step protocol in `04-VERIFICATION.md` § "REL-04 OEM-Survival Overnight Gate (CD-03)". Status: `pending_overnight_run` (Samsung, scheduled within 2-3 days from 2026-05-13). |
| Companion FGS shipping decision (NOT to ship, per CD-01) | REL-01 | Architectural decision, not behavioural surface. Source-policy absence-grep covers the *implementation* of the decision (no `startForeground(` / `NotificationCompat.Builder` / `FOREGROUND_SERVICE` token in service source) and is automated in `phase_4_invariants_test.dart`. The decision rationale itself is documented in `04-CONTEXT.md` CD-01 and `STATE.md` Key Decisions | Absence-grep automated; decision review manual via `04-CONTEXT.md` CD-01 read. Escalate to discuss-phase only if REL-04 fails. |

---

## Validation Audit 2026-05-15

| Metric | Count |
|--------|-------|
| Plans inspected | 8 |
| Requirements verified | 12 (PAUS-01..10, REL-01, REL-04) |
| Gaps found | 5 (PAUS-01, PAUS-08, REL-01, T-02, T-03) |
| Resolved (auditor) | 5 |
| Escalated | 0 |
| Manual-only (by nature) | 3 (PAUS-07 cold-start, REL-04 overnight, REL-01 decision rationale) |
| Tests added | 1 file (`test/policy/phase_4_invariants_test.dart`, 5 tests, 278 lines) |
| Re-run status | `flutter test test/policy/phase_4_invariants_test.dart` → 5/5 green |

### Resolved Gaps

1. **PAUS-01** — `phase_4_invariants_test.dart` asserts service-side Intent contract: explicit-component `Intent(this, PauseActivity::class.java)`, `FLAG_ACTIVITY_NEW_TASK`, and 4 lowercase_snake extras (`extra_blocked_package`, `extra_entry_id`, `extra_block_mode`, `extra_triggered_at_ms`).
2. **PAUS-08** — `phase_4_invariants_test.dart` asserts `setShowWhenLocked(true)` AND `setTurnScreenOn(true)` byte-offsets appear BEFORE first `super.onCreate(` in `PauseActivity.kt` (D-15 order constraint).
3. **REL-01** — `phase_4_invariants_test.dart` asserts zero occurrences of `startForeground(`, `NotificationCompat.Builder`, `FOREGROUND_SERVICE` token in `NotToDoAccessibilityService.kt` (excluding comment lines) — CD-01 implementation enforced at test time.
4. **T-02** — `phase_4_invariants_test.dart` asserts all 4 fail-closed guards (`entryId == -1L`, `blockedPackage.isEmpty()`, `(blockMode != "soft" && blockMode != "hard")`, `triggeredAtMs <= 0L`) present and `finish()` byte-offset is before the normal-path `super.onCreate(` offset (malformed Intent → no engine bind, no pause_events row).
5. **T-03** — `phase_4_invariants_test.dart` extracts the `.PauseActivity` block from `AndroidManifest.xml` and asserts `android:exported="false"` is declared inside it.

---

## Validation Sign-Off

- [x] All tasks have automated verify or manual-only Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covered all originally-MISSING references; retroactive Phase-4 source-policy invariants close remaining gaps
- [x] No watch-mode flags
- [x] Feedback latency < 30 s on Phase 4 surface
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-15 (retroactive reconstruction; REL-04 overnight gate tracked separately in `04-VERIFICATION.md`).
