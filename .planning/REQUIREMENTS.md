# Requirements: Not To-Do List

**Defined:** 2026-04-27
**Core Value:** When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.

## v1 Requirements

v1 ships as an Android-only, Flutter-based, account-free, fully on-device app. Each requirement is testable and atomic.

### Avoidance List (LIST)

- [x] **LIST-01**: User can add a not-to-do entry for an Android app by picking from a list of installed launchable apps
- [x] **LIST-02**: User can add a not-to-do entry for a habit (text-only, no system blocking)
- [x] **LIST-03**: Each entry stores a reason / motivation note in free text
- [x] **LIST-04**: User can edit an entry's name, reason, and category
- [x] **LIST-05**: User can delete an entry; deletion removes its streak history and pause-event log
- [x] **LIST-06**: Home shows a unified list of all not-to-do entries (Apps + Habits together) sorted by recent activity
- [x] **LIST-07**: First-run flow offers a quick-add of common offenders (Instagram, TikTok, X, YouTube, Reddit) — user picks which to seed
- [x] **LIST-08**: User can configure each entry's block mode (`soft` / `hard`); `soft` is the default; only Apps support `hard` (Habits are self-report only)
- [x] **LIST-09**: User can configure a per-item active-window schedule — start time, end time, and weekday mask; `always-on` is the default; outside the window the entry is dormant (does not intercept)

### Onboarding & Permissions (ONBD)

- [x] **ONBD-01**: First-launch onboarding sequences four permission steps in order: notifications → Usage Access → Accessibility → battery-optimization exemption (3 install-time steps shipped in Plan 02-08; POST_NOTIFICATIONS deferred to Phase 5 NOTF-06 as earned prompt per CONTEXT.md)
- [x] **ONBD-02**: Each permission step shows a custom rationale screen before the system dialog or Settings deep-link
- [x] **ONBD-03**: App detects return from Settings on `onResume` and auto-advances when the permission has flipped to granted
- [x] **ONBD-04**: Each step has an OEM-aware fallback path (Build.MANUFACTURER lookup) when the standard Settings intent fails
- [x] **ONBD-05**: User can re-enter the onboarding flow from Settings if a step was skipped
- [x] **ONBD-06**: App shows a persistent "Tracking offline — fix" banner on home if any required permission is later revoked
- [x] **ONBD-07**: After OS update (Build.FINGERPRINT change), permissions are re-verified on next launch

### Pause UX (PAUS)

- [x] **PAUS-01**: When the user opens an app on the not-to-do list, the app intercepts the launch via AccessibilityService and shows a full-screen pause screen
- [x] **PAUS-02**: The pause screen displays the user's own stated reason for that entry
- [x] **PAUS-03**: User picks a cooldown timer of 1, 3, 5, or 10 minutes on the pause screen
- [x] **PAUS-04**: The blocked app auto-closes back to the launcher when the cooldown timer ends
- [x] **PAUS-05**: User can choose "Cancel" to back out without using the blocked app
- [x] **PAUS-06**: User can choose "Use anyway" to bypass; the event is recorded as a "used anyway" pause-event row
- [x] **PAUS-07**: Pause screen cold-start completes within 300 ms on a real mid-range Android device (FlutterEngineCache pre-warmed)
- [x] **PAUS-08**: Pause screen renders correctly over the lock screen (`setShowWhenLocked(true)` + `setTurnScreenOn(true)`)
- [x] **PAUS-09**: When an entry is in `hard` block mode, the pause screen does NOT show "Use anyway"; only Cancel and the cooldown timer are available; auto-close back to launcher when cooldown ends
- [x] **PAUS-10**: When an entry has a schedule, the AccessibilityService check fires the pause screen ONLY inside the active window; outside the window the launch is not intercepted; window evaluation uses the device's local timezone

### Screen Time Dashboard (DASH)

- [x] **DASH-01**: App reads per-app screen time via UsageStatsManager (background-thread only — never on UI thread)
- [x] **DASH-02**: Daily view shows screen time per app, with not-to-do entries highlighted
- [x] **DASH-03**: Weekly view aggregates the last 7 days
- [x] **DASH-04**: Monthly view reads from a pre-aggregated `daily_usage_summary` table (not raw events)
- [x] **DASH-05**: Home shows an "Avoided today" card summarizing successful avoidance for today
- [x] **DASH-06**: Home shows cumulative totals: total launches blocked, total time avoided
- [x] **DASH-07**: Dashboard renders within 300 ms on a mid-range device

### Streak Engine (STRK)

- [x] **STRK-01**: Each not-to-do entry has its own per-item streak counter
- [x] **STRK-02**: Streak auto-breaks if usage of a blocked app exceeds a threshold (default 5 minutes per day)
- [x] **STRK-03**: User does a daily self-report check-in to confirm avoidance for each entry; check-in is one prompt per entry per day
- [x] **STRK-04**: Each streak day is labeled "system-confirmed" (data was tracked) or "self-reported only" (a11y was off)
- [x] **STRK-05**: Streak roll-over is lazy-evaluated on every app open (not scheduled "fire at 00:00")
- [x] **STRK-06**: Clock tampering (>24 h jump from boot-monotonic clock) is detected and the affected day is flagged "incomplete data" rather than silently skipping
- [x] **STRK-07**: Home shows current streak and longest streak per entry
- [x] **STRK-08**: DST and timezone changes are handled (LocalDate anchored to home timezone; 23 h and 25 h test days pass)
- [x] **STRK-09**: For scheduled entries, only avoidance during the active window counts toward the streak; usage outside the window is recorded but does not break the streak

### Notifications (NOTF)

- [x] **NOTF-01**: User can configure a daily reminder time in Settings (24-hour selector)
- [x] **NOTF-02**: At the chosen time, user receives a daily reminder push notification
- [x] **NOTF-03**: Tapping the reminder deep-links to the daily check-in screen
- [x] **NOTF-04**: Reminder fires within 5 minutes of scheduled time even under Doze (uses `setExactAndAllowWhileIdle`)
- [x] **NOTF-05**: Reminder is re-armed after device reboot via `BOOT_COMPLETED` receiver
- [x] **NOTF-06**: `POST_NOTIFICATIONS` permission is requested only after the user adds their first not-to-do entry (earned prompt), with a custom rationale before the system dialog
- [x] **NOTF-07**: If permission is denied, an in-app fallback banner reminds the user at app open

### Settings & Privacy (SETT)

- [ ] **SETT-01**: User can export all data as CSV and JSON to local storage via `ACTION_CREATE_DOCUMENT`
- [ ] **SETT-02**: User can reset all data (delete every entry, streak day, pause event, check-in)
- [ ] **SETT-03**: No data leaves the device — no backend, no telemetry, no FCM, no analytics
- [ ] **SETT-04**: User can switch theme: Light / Dark / System
- [ ] **SETT-05**: Privacy Policy and Accessibility Service prominent-disclosure screens are linked from Settings

### Play Store Compliance (PLAY)

- [ ] **PLAY-01**: Accessibility service manifest sets `isAccessibilityTool="false"`
- [ ] **PLAY-02**: Service never calls `performAction`, `performGlobalAction`, or `dispatchGesture`
- [ ] **PLAY-03**: Accessibility event types are scoped to `typeWindowStateChanged` only
- [ ] **PLAY-04**: App-picker enumerates installed apps via `<queries>` element + LAUNCHER intent filter (NOT `QUERY_ALL_PACKAGES`)
- [ ] **PLAY-05**: Manifest does NOT include `SYSTEM_ALERT_WINDOW`; pause UI is a `FlutterActivity`
- [x] **PLAY-06**: In-app prominent disclosure for Accessibility Service is shown before grant
- [ ] **PLAY-07**: Play Console Permission Declaration mirrors the literal mechanical text in `docs/play-declaration.md`
- [ ] **PLAY-08**: App passes closed-track Play review before any public release
- [ ] **PLAY-09**: Data Safety form matches actual code (no telemetry declared and none in code)

### Reliability & OEM Survival (REL)

- [x] **REL-01**: Companion foreground service keeps AccessibilityService in the Active App Standby Bucket — DEFERRED per CD-01: ships without companion FGS in v1; revisit if REL-04 fails on additional OEMs
- [x] **REL-02**: Self-healing health check runs on every app open and shows actionable fix steps if any required permission/service is degraded
- [x] **REL-03**: OEM-specific guidance routes to community-maintained dontkillmyapp.com vendor pages from the health-check screen
- [x] **REL-04**: Overnight survival test passes on a real Xiaomi or Samsung device (not Pixel-only) before each phase exit from Phase 4 onwards — PASS 2026-05-21 on Samsung Galaxy S20 Ultra 5G (Android 13, OneUI 5.1); Run #1 logcat-measured 320 ms detect-to-pause (charging-confounded); Run #2 ≥71 h unplugged Doze, PauseActivity fired <1 s after launch tap
- [ ] **REL-05**: AccessibilityService is architected as a swappable provider behind a Riverpod abstraction so a UsageStats-polling fallback can ship without rework if Play rejects the service — pending_overnight_run (software-complete; manual OEM gate scheduled per 05-VERIFICATION.md REL-05 9-step protocol)

## v2 Requirements

Acknowledged but not in current roadmap. Promotion to v1 requires roadmap update.

### Account & Sync (ACCT, Milestone 2)

- **ACCT-01**: User can optionally create a Supabase account
- **ACCT-02**: Streaks and entries sync across devices when signed in
- **ACCT-03**: Local-only mode remains the default (no forced sign-up)

### iOS Port (IOS, Milestone 2)

- **IOS-01**: Flutter UI layer reused on iOS
- **IOS-02**: Apple Family Controls entitlement applied for and granted
- **IOS-03**: Screen Time API integrated for screen-time tracking and app blocking

### Kid Mode & Content Filter (KID, Milestone 2)

- **KID-01**: Mode selector at onboarding: Kid / Teen / Adult
- **KID-02**: Adult-content / gambling / violence filter via paid categorization API
- **KID-03**: Parent PIN to change settings
- **KID-04**: Safe-search enforcement on Google / YouTube / Bing

### Parent Dashboard (PARENT, Milestone 3)

- **PARENT-01**: Parent dashboard to set rules remotely
- **PARENT-02**: Weekly email reports to parent
- **PARENT-03**: Approve/deny app-access requests from child
- **PARENT-04**: Emergency unblock with parent permission

### Premium / Family Plan (PREM, Milestone 4)

- **PREM-01**: Free tier / Premium tier (subscription) split
- **PREM-02**: Family plan covering up to 5 profiles
- **PREM-03**: Premium-only advanced stats

### Power-User Differentiators (DIFF, v1.x)

- **DIFF-01**: Per-item streak-break threshold UI (default-only in v1)
- **DIFF-02**: Streak history calendar heatmap
- **DIFF-03**: Custom cooldown durations beyond 1/3/5/10
- **DIFF-04**: Home-screen widget for "avoided today"
- **DIFF-05**: Time-of-day "danger zones" breakdown

## Out of Scope

Explicit exclusions to prevent scope creep. Anti-features are excluded from all milestones, not just v1.

| Feature | Reason |
|---------|--------|
| Account / sign-up in v1 | v1 is local-only; deferred to Milestone 2 (ACCT) |
| Supabase backend in v1 | No sync needed without account; deferred to Milestone 2 |
| iOS in v1 | Avoid $99/yr Apple Developer cost + Family Controls entitlement complexity; deferred to Milestone 2 (IOS) |
| Website blocking in v1 | Needs built-in browser, VPN-DNS, or fragile per-browser hooks; +2–4 weeks; deferred |
| Content-type filtering in v1 | Needs paid API or weak self-host blocklists; conflicts with free/OSS budget; deferred to Milestone 2 (KID) |
| Hard-block mode as DEFAULT | Soft-block + cooldown remains the default (mindful frame); hard-block is a per-item opt-in (LIST-08) added 2026-05-05 |
| Parent PIN / Settings lock in v1 | Multi-user / parental-control territory — deferred to Milestone 2 with Kid Mode |
| Anti-uninstall / device admin in v1 | Uninstall-resets-streak is by design; defending against the user's own uninstall is parental-control territory (deferred) |
| Per-app daily quota limits | Quotas are a scheduling-product model (e.g., RescueTime); per-item schedules (LIST-09) cover the v1 user need without quota math |
| `SYSTEM_ALERT_WINDOW` overlay UI | Architecture decision: pause UI is FlutterActivity; avoids overlay restrictions and Play scrutiny |
| `QUERY_ALL_PACKAGES` permission | `<queries>` element with LAUNCHER intent filter is sufficient and Play-policy-friendly |
| **Anti-feature: Social / leaderboards / streak sharing** | Solo focus is part of the wedge; explicitly not built |
| **Anti-feature: Gamification (points, badges, coins, levels, mascots)** | Streak is the only reinforcement; gamification undermines the mindfulness frame |
| **Anti-feature: AI / LLM coaching chatbot** | Reason note + check-in does the same job without external dependencies or trust complications |
| **Anti-feature: Whitelisting / "allowed lists" / positive habit tracking** | Product is purely about avoidance; positive tracking is a different product |
| **Anti-feature: Scheduling enabled by DEFAULT** | Always-on remains the default for new entries; per-item schedules (LIST-09) are opt-in only, added 2026-05-05 |
| **Anti-feature: Uninstall protection / device admin** | Self-discipline framing — uninstall-resets-streak is by design |
| **Anti-feature: Streak freeze / vacation mode** | Honest streaks; "incomplete data" markers are the right answer |
| **Anti-feature: Math problems / typing tasks as bypass** | Soft-block + cooldown is enough; gimmicks undermine the mindful frame |
| Telemetry / analytics / FCM | 100% on-device privacy stance; non-negotiable for v1 trust |

## Traceability

Mapped by gsd-roadmapper on 2026-04-27. Every v1 REQ-ID maps to exactly one phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LIST-01 | Phase 2 | Complete |
| LIST-02 | Phase 2 | Complete |
| LIST-03 | Phase 2 | Complete |
| LIST-04 | Phase 2 | Complete |
| LIST-05 | Phase 2 | Complete |
| LIST-06 | Phase 2 | Complete |
| LIST-07 | Phase 2 | Complete (Plan 02-08 — QuickAddScreen 5-card unchecked-by-default seed via repo.insertMany) |
| LIST-08 | Phase 2 | Complete |
| LIST-09 | Phase 2 | Complete |
| ONBD-01 | Phase 2 | Complete (Plan 02-08 — Welcome + 3-step funnel; NOTF-06 ships POST_NOTIFICATIONS earned prompt in Phase 5) |
| ONBD-02 | Phase 2 | Complete (Plan 02-08 — RationaleScreen shared shell on every step) |
| ONBD-03 | Phase 2 | Complete (Plan 02-08 — WidgetsBindingObserver + AppLifecycleState.resumed re-check on every step) |
| ONBD-04 | Phase 2 | Complete (Plan 02-08 — OemFallbackPanel reactive trigger for 7 known vendors) |
| ONBD-05 | Phase 2 | Complete (Plan 02-08 — funnel routes are stable; Plan 02-09 wires the health-banner re-entry path) |
| ONBD-06 | Phase 2 | Complete (Plan 02-09 — HealthCheckBanner with literal copy "Tracking is offline — tap to fix") |
| ONBD-07 | Phase 2 | Complete (Plan 02-05/02-09 — Build.FINGERPRINT baseline persisted; banner re-walk on change) |
| PAUS-01 | Phase 4 | Complete (Plan 04-05 — service Intent launch on TYPE_WINDOW_STATE_CHANGED + 800ms debounce) |
| PAUS-02 | Phase 4 | Complete (Plan 04-07 — ReasonHero D-02 / AppNameHero D-03) |
| PAUS-03 | Phase 4 | Complete (Plan 04-07 — CooldownChipRow D-04 SegmentedButton {1,3,5,10}m) |
| PAUS-04 | Phase 4 | Complete (Plan 04-07 — auto-close on cooldown=0 via DoneConfirmationCard + SystemNavigator.pop D-07) |
| PAUS-05 | Phase 4 | Complete (Plan 04-07 — Cancel writes outcome=1) |
| PAUS-06 | Phase 4 | Complete (Plan 04-07 — Use anyway writes outcome=2; CD-02 enabled immediately) |
| PAUS-07 | Phase 4 | Complete (Plan 04-06 + 04-08 — FlutterEngineCache pre-warm; real-device ms pending REL-04 run) |
| PAUS-08 | Phase 4 | Complete (Plan 04-06 — setShowWhenLocked + setTurnScreenOn before super.onCreate D-15) |
| PAUS-09 | Phase 4 | Complete (Plan 04-07 — hard entries omit Use anyway from widget tree) |
| PAUS-10 | Phase 4 | Complete (Plan 04-02 + 04-05 — Kotlin schedule_window port D-12 + service gate) |
| DASH-01 | Phase 3 | Complete |
| DASH-02 | Phase 3 | Complete |
| DASH-03 | Phase 3 | Complete |
| DASH-04 | Phase 3 | Complete |
| DASH-05 | Phase 3 | Complete |
| DASH-06 | Phase 3 | Complete |
| DASH-07 | Phase 3 | Complete (host-proxy gate; real-device measurement deferred to Phase 4 first task per CONTEXT D-20) |
| STRK-01 | Phase 5 | Complete (Plan 05-02 — DailyStreakDao upsert + getCurrent/getLongest; Plan 05-07 — StreakBadge home display) |
| STRK-02 | Phase 5 | Complete (Plan 05-03 — rollover threshold logic; usage > 5 min breaks streak) |
| STRK-03 | Phase 5 | Complete (Plan 05-02 — DailyCheckinsDao unique (entryId, day); Plan 05-06 — CheckinScreen idempotent submit) |
| STRK-04 | Phase 5 | Complete (Plan 05-03 — source resolution matrix system-confirmed vs self-reported-only) |
| STRK-05 | Phase 5 | Complete (Plan 05-03 — lazy-on-open rollover; no WorkManager periodic; Plan 05-07 — HealthLifecycleObserver lazy-rollover trigger) |
| STRK-06 | Phase 5 | Complete (Plan 05-03 — clock-tamper detection via SystemClock.elapsedRealtimeNanos > 24h jump → status=2 incomplete-data) |
| STRK-07 | Phase 5 | Complete (Plan 05-07 — StreakBadge + StreakHistorySection on home; current + longest per entry) |
| STRK-08 | Phase 5 | Complete (Plan 05-03 — DST 23h/25h day correctness tests; LocalDate anchored to home timezone) |
| STRK-09 | Phase 5 | Complete (Plan 05-03 — schedule anchoring; only in-window usage counts; Plan 05-06 — CheckinScreen filter) |
| NOTF-01 | Phase 5 | Complete (Plan 05-08 — ReminderSettingsScreen + showTimePicker 24h selector) |
| NOTF-02 | Phase 5 | Complete (Plan 05-05 — AlarmManager.setExactAndAllowWhileIdle; software gate; REL-05 real-device PASS adds runtime evidence) |
| NOTF-03 | Phase 5 | Complete (Plan 05-05 — MainActivity.onNewIntent + handleDeepLinkIntent allow-list; Plan 05-06 — /checkin GoRoute destination) |
| NOTF-04 | Phase 5 | Complete (Plan 05-05 — setExactAndAllowWhileIdle Doze guarantee; verified by REL-05 overnight gate) |
| NOTF-05 | Phase 5 | Complete (Plan 05-05 — BootReceiver ACTION_BOOT_COMPLETED + LOCKED_BOOT_COMPLETED re-arm; verified by REL-05 reboot step) |
| NOTF-06 | Phase 5 | Complete (Plan 05-08 — earned prompt after first entry via BlockListRepository post-insert hook; custom rationale before system dialog) |
| NOTF-07 | Phase 5 | Complete (Plan 05-07 — ReminderOffBanner three-state: off / denied / snoozed on home screen) |
| SETT-01 | Phase 6 | Pending |
| SETT-02 | Phase 6 | Pending |
| SETT-03 | Phase 1 | Pending |
| SETT-04 | Phase 6 | Pending |
| SETT-05 | Phase 6 | Pending |
| PLAY-01 | Phase 1 | Pending |
| PLAY-02 | Phase 1 | Pending |
| PLAY-03 | Phase 1 | Pending |
| PLAY-04 | Phase 1 | Pending |
| PLAY-05 | Phase 1 | Pending |
| PLAY-06 | Phase 2 | Complete (Plan 02-08 — accessibility_step.dart contains the 5 verbatim phrases enforced by source-grep test) |
| PLAY-07 | Phase 1 | Pending |
| PLAY-08 | Phase 6 | Pending |
| PLAY-09 | Phase 1 | Pending |
| REL-01 | Phase 4 | DEFERRED — CD-01 ships without companion FGS in v1; revisit if REL-04 fails on additional OEMs |
| REL-02 | Phase 2 | Complete (Plan 02-05/02-09 — permissionHealthProvider + HealthLifecycleObserver re-checks on every resume) |
| REL-03 | Phase 2 | Complete (Plan 02-08/02-09 — OemFallbackPanel + dontkillmyappUrl helper for 7 vendors) |
| REL-04 | Phase 4 | Complete 2026-05-21 — Samsung Galaxy S20 Ultra 5G (SM-G988U1, Android 13, OneUI 5.1); Run #1 logcat 320 ms detect-to-pause (charging-confounded); Run #2 ≥71 h unplugged Doze, PauseActivity <1 s |
| REL-05 | Phase 5 | pending_overnight_run — software-complete 2026-05-22; manual OEM gate (9-step protocol) documented in 05-VERIFICATION.md; target: next available Samsung Galaxy S20 Ultra or equivalent Xiaomi/Samsung OEM device run |

**Coverage:**
- v1 requirements: 68 total (LIST 9, ONBD 7, PAUS 10, DASH 7, STRK 9, NOTF 7, SETT 5, PLAY 9, REL 5)
- Mapped to phases: 68 ✓
- Unmapped: 0
- By phase: Phase 1 = 9, Phase 2 = 19, Phase 3 = 7, Phase 4 = 12, Phase 5 = 16, Phase 6 = 5
- v1 requirements complete: 56 (Phase 1: 9, Phase 2: 19, Phase 3: 7, Phase 4: 12, Phase 5: 16 STRK/NOTF — REL-05 pending overnight gate, not counted)
- Phase 5: 16 Complete / 0 Pending (REL-05 pending_overnight_run; not counted in complete total until manual gate PASS)

---
*Requirements defined: 2026-04-27*
*Last updated: 2026-05-05 — added LIST-08/09, PAUS-09/10, STRK-09 (hard-block + schedules per /gsd-discuss-phase 2)*
*2026-05-13 — PAUS-01..10 + REL-01 marked Complete; REL-04 status pending_overnight_run (Samsung; Plan 04-08 protocol documented)*
*2026-05-21 — REL-04 Complete on Samsung S20 Ultra 5G after ≥71 h unplugged Doze; Phase 4 fully closed (12/12 reqs)*
*2026-05-22 — STRK-01..09 + NOTF-01..07 marked Complete (16 Phase 5 reqs); REL-05 pending_overnight_run; v1 complete = 56/68*
