# Project State: Not To-Do List

**Initialized:** 2026-04-27
**Last updated:** 2026-04-26

## Project Reference

- **Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.
- **Wedge:** Phase 4 (Pause UX) — user-defined avoidance + reason-aware soft-block + cooldown timer.
- **Stack:** Flutter 3.41 + Dart 3.x, Riverpod 3.3, Drift 2.32, Pigeon-typed Kotlin channels, Android-only (minSdk 29 / targetSdk 36), 100% on-device.
- **Timeline:** 6–12 weeks to v1, solo full-time.

## Current Position

- **Milestone:** v1
- **Phase:** Phase 1 — Foundation & Play Declaration (✅ COMPLETE)
- **Plan:** All 5 plans (01-01 through 01-05) committed; phase exit gate green
- **Status:** Phase 1 exits cleanly. Ready for `/gsd-transition` and `/gsd-plan-phase 2`.
- **Progress:** 1/6 phases complete

```
[███░░░░░░░░░░░░░░░░░] 17%
```

## Performance Metrics

- Phases planned: 6
- Phases complete: 1
- v1 requirements: 63 (all mapped)
- v1 requirements complete: 8 (PLAY-01, PLAY-02, PLAY-03, PLAY-04, PLAY-05, PLAY-07, PLAY-09, SETT-03 — Phase 1 closed; REL-05 abstraction shipped, full satisfaction in Phase 4)
- OEM-survival overnight tests passed: 0/3 (Phase 4, Phase 5, Phase 6)

## Accumulated Context

### Key Decisions (from PROJECT.md + research)

| Decision | Source | Rationale |
|----------|--------|-----------|
| Android-only for v1 | PROJECT.md | Avoid Apple $99/yr + Family Controls entitlement; ship faster |
| Flutter (not RN, not native) | PROJECT.md | Reusable UI for future iOS port; native channels for platform APIs |
| No backend in v1 | PROJECT.md | Privacy + zero sign-up friction; aligns with free/OSS budget |
| Pause UI is FlutterActivity, NOT `SYSTEM_ALERT_WINDOW` | research/ARCHITECTURE.md | Play policy + Android 12+ overlay restrictions + flutter_overlay_window hosting complexity |
| AccessibilityService is a passive trigger; DB is source of truth | research/ARCHITECTURE.md | Sidesteps flutter#76988 background-isolate-EventChannel footgun; service can die without losing state |
| Pigeon-typed channels for all Dart↔Kotlin calls | research/ARCHITECTURE.md | Catches type mismatches at build time; eliminates `MissingPluginException` class of bugs |
| AlarmManager for user-perceived precise time; WorkManager for Doze-tolerant rollover | research/ARCHITECTURE.md | Canonical split — never both for the same job |
| `isAccessibilityTool="false"` | research/PITFALLS.md (#1) | We are NOT assistive tech; required for Play declaration to pass |
| Streak roll-over lazy-evaluated on every app open | research/PITFALLS.md (#6) | Robust against Doze, reboots, offline; "fire at 00:00" is fragile |
| AccessibilityService swappable behind Riverpod abstraction | research/PITFALLS.md (#1) | UsageStats-polling fallback ships without rework if Play rejects the service |
| Earned `POST_NOTIFICATIONS` prompt (after first not-to-do added) | research/PITFALLS.md (#10) | Roughly doubles allow rates vs first-launch prompt |

### Active Todos

None — awaiting `/gsd-plan-phase 1`.

### Blockers

None.

### Risks Being Tracked

| Risk | Source | Mitigation |
|------|--------|------------|
| Play Store rejection of AccessibilityService declaration | research/PITFALLS.md #1 | Phase 1: literal mechanical declaration in `docs/play-declaration.md`; `isAccessibilityTool="false"`; closed-track build before public release; UsageStats-polling fallback prototyped |
| OEM battery managers silently kill the service (Xiaomi, Huawei, Samsung) | research/PITFALLS.md #2 | Phase 2: OEM-aware fix-it flows; Phases 4–6: real-device overnight test as phase-exit gate |
| 4-Settings permission funnel collapses onboarding < 50% | research/PITFALLS.md #3 | Phase 2: sequenced contextual asks, animated GIFs, `onResume` auto-advance, OEM-specific fallbacks |
| Pause screen >300 ms cold-start | research/PITFALLS.md (#perf) | Phase 4: `FlutterEngineCache` pre-warm; stopwatch-test on real low-end device as exit criterion |
| Doze defers daily reminder | research/PITFALLS.md #6 | Phase 5: `setExactAndAllowWhileIdle`; `dumpsys deviceidle force-idle` test as exit criterion |
| `POST_NOTIFICATIONS` denial on Android 13+ | research/PITFALLS.md #10 | Phase 5: earned prompt + custom rationale + in-app fallback banner |

## Session Continuity

### Last Session

- 2026-04-26: Phase 1 complete. All 5 plans (01-01 toolchain, 01-02 manifest+a11y+Play docs, 01-03 Drift schema, 01-04 Pigeon stubs+BlockedAppDetector, 01-05 empty home scaffold + V1-V14 phase exit gate) landed. `flutter build apk --debug` produces `build/app/outputs/flutter-apk/app-debug.apk` (171.6 MB).
- 2026-04-27: PROJECT.md, REQUIREMENTS.md, research bundle, and ROADMAP.md initialized.

### Next Session

- Run `/gsd-transition` then `/gsd-plan-phase 2` to decompose Phase 2 (List CRUD + Onboarding & Permissions).
- Phase 2 is the first phase where the home screen subscribes to `blockedAppDetectorProvider` (RESEARCH §6 Open Question #2 unblocks here).
- First real-device overnight test is still the Phase 4 exit gate — Phase 2/3 stay simulator-friendly.

### Files of Record

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — vision, constraints, key decisions
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 63 v1 REQ-IDs + traceability table
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` — 6-phase plan with success criteria
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` — research executive summary
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` — Flutter + Android architecture, build order
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` — 10 critical pitfalls + phase mapping
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/config.json` — granularity=standard, mode=yolo

---
*State initialized: 2026-04-27 by gsd-roadmapper*
