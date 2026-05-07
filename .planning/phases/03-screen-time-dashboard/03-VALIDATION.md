---
phase: 3
slug: screen-time-dashboard
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-07
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Populated from `03-RESEARCH.md` § Validation Architecture during planning. Per-Task Verification Map fills in during planning (gsd-planner) and execution (gsd-executor).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK) + drift's NativeDatabase.memory + mocktail 1.0.5 |
| **Config file** | none — Phase 1 already installed analysis_options.yaml + pubspec dev_dependencies |
| **Quick run command** | `flutter test test/features/dashboard/ test/data/repositories/usage_repository_test.dart test/policy/play_invariants_test.dart` |
| **Full suite command** | `flutter test && dart analyze && flutter build apk --debug` |
| **Estimated runtime** | ~45 seconds (124 existing + ~25 new Phase 3 tests; add ~5 s for the perf test) |

---

## Sampling Rate

- **After every task commit:** Run quick command (subset of suite touching the changed area)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green; `play_invariants_test.dart` 8/8 green; `dart analyze` 0 errors / 0 warnings (pre-existing 18 infos in pigeons/* + permission_status_mock.dart per `deferred-items.md` are grandfathered)
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Populated by gsd-planner during planning. Each Phase 3 task gets a row.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-NN-MM | TBD | TBD | DASH-NN | TBD | TBD | TBD | TBD | TBD | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

> Stub all test files BEFORE Wave 1 lights up Pigeon impl + DAO. Mirrors Phase 2 Plan 02-01 wave-0-stubs pattern.

- [ ] `test/_fixtures/usage_summary_fixture.dart` — 30 days × 20 apps Drift seed (5 not-to-do entries highlighted) for perf + integration tests
- [ ] `test/platform/usage_api_kotlin_contract_test.dart` — exists?-and-imports stub (real impl tested in Wave 1)
- [ ] `test/data/database/daos/daily_usage_summary_dao_test.dart` — stub for upsert + watch-by-range
- [ ] `test/data/repositories/usage_repository_test.dart` — stub for `refreshIfStale` + cache TTL semantics
- [ ] `test/domain/dashboard/dashboard_range_test.dart` — stub for Day/Week/Month boundary computation
- [ ] `test/features/dashboard/dashboard_screen_test.dart` — widget test stub
- [ ] `test/features/dashboard/widgets/dashboard_row_test.dart` — bar-fill row widget test stub
- [ ] `test/features/dashboard/widgets/letter_avatar_test.dart` — fallback icon widget test stub
- [ ] `test/features/home/widgets/avoided_today_card_test.dart` — home card stub
- [ ] `test/features/home/widgets/cumulative_totals_card_test.dart` — home card stub
- [ ] `test/perf/dashboard_render_test.dart` — first-frame stopwatch stub (D-20 budget)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real-device first-frame <300 ms on mid-range Android | DASH-07 | host wall-clock perf-test is a documented proxy (see RESEARCH.md A4); real-device validation is explicitly deferred to **Phase 4 first task** per D-20 — Phase 3 ships the host-side perf test as the in-CI guardrail | Phase 4 pre-flight: launch app on Pixel emulator stock Android 16, navigate to /dashboard against a populated DB, measure first-frame via Flutter DevTools Performance tab; assert ≤300 ms |
| Visual highlight + bar-fill render correctly under DynamicColor (Android 12+ Material You) | DASH-02 | dynamic-color depends on host wallpaper; CI cannot reproduce | Pixel emulator: change wallpaper, cold-launch the app, open /dashboard, confirm not-to-do rows still pop visually |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency <60s
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] `wave_0_complete: true` set after Plan 03-01 lands

**Approval:** pending — flips to approved YYYY-MM-DD when Phase 3's exit gate signs off in 03-VERIFICATION.md
