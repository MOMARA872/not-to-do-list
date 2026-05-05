# Roadmap: Not To-Do List

**Created:** 2026-04-27
**Granularity:** standard
**Total v1 phases:** 6
**Coverage:** 68/68 requirements mapped (updated 2026-05-05 — hard-block + schedules added)

## Project Reference

- **Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.
- **Constraints:** Solo developer, full-time, 6–12 weeks to v1. Android-only, Flutter, on-device only, no backend, no telemetry, free/OSS only.
- **Wedge:** Phase 4 (Pause UX). Ship before Phase 5 (Streak).

## Phases

- [ ] **Phase 1: Foundation & Play Declaration** - Drift schema, domain skeleton, Pigeon scaffolding, manifest, and Play Console declaration copy committed before any service code
- [ ] **Phase 2: List CRUD + Onboarding & Permissions** - User can build a not-to-do list and complete the 4-permission Settings hand-off flow with OEM-aware fallbacks
- [ ] **Phase 3: Screen-Time Dashboard** - UsageStatsManager bridge ships visible value and validates the Pigeon channel pattern on a low-risk surface
- [ ] **Phase 4: Pause UX (the wedge)** - AccessibilityService + PauseActivity + cooldown timer deliver the reflection moment, OEM-survival overnight test gate begins
- [ ] **Phase 5: Streak Engine & Daily Reminder** - Hybrid honest streak (system + self-report), daily check-in, exact-alarm daily reminder that survives reboot and Doze
- [ ] **Phase 6: Polish & Play Store Submission** - Settings, theme, export/reset, prominent disclosure, closed-track Play submission passes review

## Phase Details

### Phase 1: Foundation & Play Declaration
**Goal**: Establish layered architecture (Drift + domain + Pigeon + manifest skeleton) and commit the Play Console Permission Declaration copy before any service code is written. Pure-Dart, fast feedback. Locks all architecture-level decisions that are cheap now and very expensive to change later.
**Depends on**: Nothing (first phase)
**Requirements**: PLAY-01, PLAY-02, PLAY-03, PLAY-04, PLAY-05, PLAY-07, PLAY-09, REL-05, SETT-03
**Success Criteria** (what must be TRUE):
  1. App boots to an empty list screen; Drift schema (`block_list`, `daily_streak`, `pause_events`, `daily_checkins`, `daily_usage_summary`) is created and migrations pass round-trip tests.
  2. `docs/play-declaration.md` contains the literal mechanical declaration copy and is the single source of truth referenced by the manifest, in-app prominent disclosure, and (later) Play Console form.
  3. AndroidManifest declares `<queries>` element with LAUNCHER intent filter (no `QUERY_ALL_PACKAGES`), no `SYSTEM_ALERT_WINDOW`, `allowBackup="false"`; accessibility service config sets `isAccessibilityTool="false"` and `accessibilityEventTypes="typeWindowStateChanged"` only; `flagRequestFilterKeyEvents`, `canPerformGestures`, `canRetrieveWindowContent` are NOT set.
  4. AccessibilityService is wired behind a Riverpod-abstracted swappable provider interface so a UsageStats-polling fallback can ship without rework if Play rejects the service.
  5. No telemetry / FCM / analytics SDKs in the dependency tree; Data Safety form draft committed in `docs/data-safety.md` declaring zero data collected and verified to match code.
**Plans**: 5 plans
- [ ] 01-01-PLAN.md — Wave 0: Toolchain (Flutter 3.41.x, JDK 17, Android SDK platform-36) + Flutter scaffold + pinned pubspec + Gradle SDK lock + folder skeleton
- [ ] 01-02-PLAN.md — Wave 1: AndroidManifest + a11y config XML + data_extraction_rules + strings + NotToDoAccessibilityService.kt + PauseActivity.kt stubs + docs/play-declaration.md + docs/data-safety.md
- [ ] 01-03-PLAN.md — Wave 1: Drift 5-table schema (block_list, daily_streak, pause_events, daily_checkins, daily_usage_summary) + AppDatabase + Riverpod databaseProvider + round-trip test
- [ ] 01-04-PLAN.md — Wave 1: 3 Pigeon @HostApi inputs + codegen + MainActivity.kt stub registrations + BlockedAppDetector interface (PLAY-02 by absence) + 2 stub impls + Riverpod selector (REL-05) + unit test
- [ ] 01-05-PLAN.md — Wave 2: Empty home scaffold (main, app, theme, router, EmptyHomeScreen) + V1–V14 verification gate + APK build + 01-VALIDATION.md sign-off
**UI hint**: yes

### Phase 2: List CRUD + Onboarding & Permissions
**Goal**: User can build a not-to-do list and complete the 4-step permission Settings hand-off (notifications → Usage Access → Accessibility → battery-opt) without abandoning. Onboarding completion from install to first dashboard view is the wedge-defining UX, not a checkbox.
**Depends on**: Phase 1
**Requirements**: LIST-01, LIST-02, LIST-03, LIST-04, LIST-05, LIST-06, LIST-07, LIST-08, LIST-09, ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05, ONBD-06, ONBD-07, PLAY-06, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. User can add an Android app entry from a `<queries>` + LAUNCHER-filtered installed-app picker, add a habit entry (text-only), edit name/reason/category/block-mode/schedule, and delete entries (deletion cascades to streak history and pause-event log). Home shows a unified Apps + Habits list sorted by recent activity. Block mode is `soft` by default with `hard` as a per-item opt-in (LIST-08, Apps only); schedule is `always-on` by default with per-item active-window opt-in (LIST-09).
  2. First-run flow offers one-tap quick-add of common offenders (Instagram, TikTok, X, YouTube, Reddit) and routes to onboarding step 1.
  3. Permission flow sequences notifications → Usage Access → Accessibility → battery-opt in order; each step shows a custom rationale screen with an animated GIF before the system dialog or Settings deep-link; `onResume` return-detection auto-advances when the permission flips to granted.
  4. Each permission step has an OEM-aware fallback path keyed on `Build.MANUFACTURER` (Xiaomi/Huawei/Samsung/Oppo/Vivo/OnePlus) when the standard Settings intent fails to resolve; user can re-enter the flow from Settings if a step was skipped.
  5. Self-healing health check on every app open verifies all required permissions; shows a persistent "Tracking offline — fix" banner with actionable steps if any are revoked, including links to dontkillmyapp.com per-vendor pages. Build.FINGERPRINT change after OS update triggers re-verification on next launch.
  6. In-app prominent disclosure screen for Accessibility Service is shown before grant, in plain English, with a screenshot of the pause screen; copy matches `docs/play-declaration.md`.
**Plans**: TBD
**UI hint**: yes

### Phase 3: Screen-Time Dashboard
**Goal**: User sees their daily/weekly/monthly screen-time with not-to-do entries highlighted. Validates the Pigeon channel pattern on a low-risk surface before the blocker depends on it. Ships visible value early.
**Depends on**: Phase 2
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DASH-07
**Success Criteria** (what must be TRUE):
  1. Pigeon-typed `usage_api.dart` channel queries UsageStatsManager on a Kotlin background `Executor` (never the UI thread); Dart aggregates into Drift cache (5-min staleness for today, immutable for past days).
  2. Daily view shows per-app screen time with not-to-do entries visually highlighted; weekly view aggregates the last 7 days; monthly view reads from the pre-aggregated `daily_usage_summary` table (not raw events).
  3. Home shows an "Avoided today" card summarizing successful avoidance for today.
  4. Home shows cumulative totals: total launches blocked, total time avoided.
  5. Dashboard renders within 300 ms on a real mid-range Android device (measured, not estimated).
**Plans**: TBD
**UI hint**: yes

### Phase 4: Pause UX (the wedge)
**Goal**: When a user opens a blocked app, AccessibilityService intercepts the launch and a Flutter `PauseActivity` shows the user's own stated reason, a 1/3/5/10-minute cooldown timer, and Cancel / Use anyway choices. This is the magic moment. Ship this before Phase 5.
**Depends on**: Phase 3 (Pigeon pattern validated, app-picker complete)
**Requirements**: PAUS-01, PAUS-02, PAUS-03, PAUS-04, PAUS-05, PAUS-06, PAUS-07, PAUS-08, PAUS-09, PAUS-10, REL-01, REL-04
**Success Criteria** (what must be TRUE):
  1. AccessibilityService observes `TYPE_WINDOW_STATE_CHANGED`, debounces by 800 ms, matches against an in-memory `Set<String>` block-list (refreshed on `ACTION_BLOCKLIST_UPDATED` LocalBroadcast — service never writes to SQLite), and launches `PauseActivity` (a `FlutterActivity` with `singleInstance` + `excludeFromRecents`) via Intent extras with `FLAG_ACTIVITY_NEW_TASK`.
  2. PauseActivity displays the user's own stated reason for that entry, offers cooldown options of 1/3/5/10 minutes, auto-closes back to the launcher when the cooldown ends, and supports Cancel. For `soft` entries, "Use anyway" is shown and recorded as a `pause_events` row written by Dart (the single writer); for `hard` entries (PAUS-09), "Use anyway" is omitted entirely. Scheduled entries (PAUS-10) only intercept inside the active window — outside the window the launch passes through.
  3. Pause screen cold-start completes within 300 ms on a real mid-range Android device with `FlutterEngineCache` pre-warmed; renders correctly over the lock screen via `setShowWhenLocked(true)` + `setTurnScreenOn(true)`.
  4. Companion foreground service keeps the AccessibilityService in the Active App Standby Bucket; service does not call `performAction`, `performGlobalAction`, or `dispatchGesture`; service is architected as a passive trigger (DB is source of truth — the service can die without losing state).
  5. **OEM-survival overnight exit gate:** Pause flow passes a real-device overnight test on Xiaomi or Samsung hardware (not Pixel-only) — phone idle 8+ hours, blocked-app launch the next morning still triggers PauseActivity within 500 ms detect-to-pause.
**Plans**: TBD
**UI hint**: yes

### Phase 5: Streak Engine & Daily Reminder
**Goal**: User has a per-item hybrid honest streak (system threshold + daily self-report), is reminded once a day at their chosen time, and never feels punished by an opaque system. Streak honesty is the trust layer.
**Depends on**: Phase 4 (pause events + AccessibilityService both shipping data the streak engine reads)
**Requirements**: STRK-01, STRK-02, STRK-03, STRK-04, STRK-05, STRK-06, STRK-07, STRK-08, STRK-09, NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05, NOTF-06, NOTF-07
**Success Criteria** (what must be TRUE):
  1. Each entry has its own per-item streak counter; streak auto-breaks when blocked-app usage exceeds the 5-min default daily threshold; user does a daily self-report check-in (one prompt per entry per day); home shows current and longest streak per entry. For scheduled entries (STRK-09), only usage during the active window counts toward the streak — out-of-window usage is recorded but does not break the streak.
  2. Each streak day is labeled "system-confirmed" (data was tracked) or "self-reported only" (a11y was off); clock tampering (>24 h jump from boot-monotonic clock via `SystemClock.elapsedRealtimeNanos()`) is detected and the affected day is flagged "incomplete data" rather than silently breaking the streak.
  3. Streak roll-over is lazy-evaluated on every app open (not "fire at 00:00"); DST and timezone changes are handled correctly (LocalDate anchored to home timezone; 23 h and 25 h test days both pass).
  4. User configures a daily reminder time in Settings (24-hour selector); reminder fires within 5 minutes of scheduled time even under Doze via `AlarmManager.setExactAndAllowWhileIdle()`; re-armed after device reboot via `BOOT_COMPLETED` receiver; tapping deep-links to the daily check-in screen.
  5. `POST_NOTIFICATIONS` permission is requested only after the user adds their first not-to-do entry (earned prompt) with a custom rationale screen before the system dialog; if denied, an in-app banner reminds the user at app open.
  6. **OEM-survival overnight exit gate:** Streak rollover, alarm-fired reminder, and `BOOT_COMPLETED` re-arm all pass on a real Xiaomi or Samsung device (not Pixel-only) — overnight idle, reminder fires within 5 min of scheduled time, streak rolls over correctly the next morning.
**Plans**: TBD
**UI hint**: yes

### Phase 6: Polish & Play Store Submission
**Goal**: User can export, reset, theme, and the app passes Play Store closed-track review on the first submission. Final mile — empty states, prominent disclosure, Data Safety form, no-telemetry verification, closed-track A/B before public release.
**Depends on**: Phase 5
**Requirements**: SETT-01, SETT-02, SETT-04, SETT-05, PLAY-08
**Success Criteria** (what must be TRUE):
  1. User can export all data as CSV and JSON to local storage via `ACTION_CREATE_DOCUMENT`; user can reset all data (deletes every entry, streak day, pause event, check-in) with confirmation.
  2. User can switch theme: Light / Dark / System; Settings has a Privacy Policy link and an Accessibility Service prominent-disclosure screen mirroring `docs/play-declaration.md`.
  3. App passes a closed-track Play review submission before any public release; no rejection on AccessibilityService declaration, no rejection on `<queries>` / app-list policy, no rejection on battery-opt exemption justification.
  4. Data Safety form ML cross-check passes — declared zero data collected matches actual code (no telemetry, no FCM, no analytics SDK in dependency tree, verified via APK inspection).
  5. **OEM-survival overnight exit gate:** Full happy-path flow (onboarding → list add → blocked-app launch → pause → cooldown → streak roll-over → reminder fire) passes overnight on a real Xiaomi AND a real Samsung device.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Play Declaration | 0/0 | Not started | - |
| 2. List CRUD + Onboarding & Permissions | 0/0 | Not started | - |
| 3. Screen-Time Dashboard | 0/0 | Not started | - |
| 4. Pause UX (the wedge) | 0/0 | Not started | - |
| 5. Streak Engine & Daily Reminder | 0/0 | Not started | - |
| 6. Polish & Play Store Submission | 0/0 | Not started | - |

## Coverage Summary

| Category | Total | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 | Phase 6 |
|----------|-------|---------|---------|---------|---------|---------|---------|
| LIST | 7 | — | 7 | — | — | — | — |
| ONBD | 7 | — | 7 | — | — | — | — |
| PAUS | 8 | — | — | — | 8 | — | — |
| DASH | 7 | — | — | 7 | — | — | — |
| STRK | 8 | — | — | — | — | 8 | — |
| NOTF | 7 | — | — | — | — | 7 | — |
| SETT | 5 | 1 | — | — | — | — | 4 |
| PLAY | 9 | 7 | 1 | — | — | — | 1 |
| REL | 5 | 1 | 2 | — | 2 | — | — |
| **Total** | **63** | **9** | **17** | **7** | **10** | **15** | **5** |

✓ All 63 v1 requirements mapped to exactly one phase. No orphans, no duplicates.

## Notes

- **Wedge ordering:** Phase 4 (Pause UX) is the differentiator and ships before Phase 5 (Streak), per project context. Phase 3 (Dashboard) intentionally precedes Phase 4 to validate the Pigeon channel pattern on a low-risk surface before the blocker depends on it.
- **OEM-survival overnight test** is a per-phase exit gate from Phase 4 onwards (REL-04). Pixel-only testing is insufficient; real Xiaomi or Samsung hardware required.
- **Architecture is locked in Phase 1.** Play declaration copy, manifest skeleton, swappable AccessibilityService abstraction, and zero-telemetry stance are all committed before any feature work — these are cheap to fix in Phase 1 and very expensive later.
- **Phases 4–6 carry the most research risk.** `/gsd-research-phase` recommended for Phase 4 (FlutterEngineCache cold-start, OEM fix-it flows, native Kotlin a11y fallback prototype) and Phase 5 (Doze-window behavior, lazy-rollover edge cases). Phases 1–3 use standard patterns.

---
*Roadmap created: 2026-04-27*
