# Project Research Summary

**Project:** Not To-Do List
**Domain:** Android habit-avoidance / soft-block / screen-time app (Flutter, on-device only)
**Researched:** 2026-04-27
**Confidence:** MEDIUM-HIGH overall

## Executive Summary

The Not To-Do List is a Flutter Android app in the **mindful-blocking** category — adjacent to one sec, ScreenZen, and Opal — but distinguished by five things no single competitor combines: (1) user-defined avoidance list framing, (2) Apps + Habits unified in one list, (3) reason-aware soft-block pause, (4) hybrid honest streak (system-detected + self-reported), and (5) zero gamification, zero account, 100% on-device. Experts in this space build with `UsageStatsManager` for screen-time aggregates and `AccessibilityService` (`TYPE_WINDOW_STATE_CHANGED`) for sub-second launch detection — and they ship the pause moment as the wedge. Research strongly endorses Flutter 3.41 + Riverpod 3.x + Drift + Pigeon-typed channels; minSdk 29, targetSdk 36 (matching Google's Aug-2026 mandate); `flutter_local_notifications` with exact alarms via `SCHEDULE_EXACT_ALARM`; and a clean separation of `AlarmManager` (user-perceived precise time) from `WorkManager` (Doze-tolerant streak rollover).

The single biggest risk is **Google Play's January-2026 policy tightening on AccessibilityService for non-disability uses**. Our use is rule-based (read package name, show our own pause screen — never autonomous, never `performAction`/`dispatchGesture`), which is the lane the policy explicitly preserves, but the Play Console declaration must be written carefully and the architecture must keep AccessibilityService as a *swappable trigger* — not a foundation. The second-biggest risk is **OEM battery managers** (Xiaomi, Huawei, Samsung, Oppo, Vivo, OnePlus) silently killing background work; this must be treated as a first-class feature, not an afterthought, with OEM-aware fix-it flows and `dontkillmyapp.com`-grade self-healing health checks. The third is the **permission funnel** — four Settings hand-offs (notifications, UsageStats, Accessibility, battery-opt) will collapse onboarding completion below 50% if asked at once; they must be sequenced contextually with return-detection auto-advance.

The recommended approach is to front-load architecture and permissions before any feature work. The pause moment is the wedge, but the *pause infrastructure* (Pigeon channels, AccessibilityService, FlutterEngine cache, OEM survival) is what determines whether the wedge ever fires reliably. Once that foundation is solid, features layer on cleanly: list CRUD → dashboard → blocker → pause UX → streak → reminder → polish/launch.

## Key Findings

### Recommended Stack

Flutter 3.41 (stable Q1 2026) is required by PROJECT.md and is the right call; Riverpod 3.3 wins over Bloc on solo-dev velocity for a 6–12 week budget; Drift wins over Hive/Isar/sqflite because the schema is genuinely relational (entries → usage rows → check-ins → pause events) and we need reactive streams. The Android side runs `UsageStatsManager` (via `app_usage` plugin) for aggregates and `AccessibilityService` (via `flutter_accessibility_service`) for launch detection — but **both bridges are wrapped behind Pigeon-typed channels rather than hand-rolled MethodChannels** to catch type mismatches at build time. minSdk 29 covers >95% of devices; targetSdk 36 is mandatory for new Play submissions from Aug 31, 2026.

**Core technologies:**
- **Flutter 3.41 + Dart 3.x** — UI layer, future iOS-port-friendly (per PROJECT.md constraint)
- **Riverpod 3.3.1 (with code-gen)** — state management; Bloc is overkill for solo-dev consumer wellness app
- **Drift 2.32 (SQLite)** — typed relational DB with reactive streams; Isar is abandoned, Hive is flat-only
- **`app_usage` 4.1** — `UsageStatsManager` wrapper for daily/weekly screen-time aggregates
- **`flutter_accessibility_service` 1.0** — `TYPE_WINDOW_STATE_CHANGED` event stream for launch detection
- **`flutter_local_notifications` 21 + `timezone`** — daily reminder via `setExactAndAllowWhileIdle` (DST-safe)
- **`permission_handler` 12 + `app_settings`** — runtime perms + Settings deep-links for `PACKAGE_USAGE_STATS` and Accessibility
- **Pigeon** — typed Dart↔Kotlin code-gen for all platform calls (NOT hand-rolled MethodChannel)

**Locked stack-level decisions:**
- minSdk 29, targetSdk 36, compileSdk 36
- `SCHEDULE_EXACT_ALARM` (user-prompted) — NOT `USE_EXACT_ALARM` (alarm/calendar-class only)
- `isAccessibilityTool="false"` in service config — we are NOT assistive tech
- No `SYSTEM_ALERT_WINDOW`/overlay (despite original PROJECT.md framing) — pause UI is a FlutterActivity

### Expected Features

The wedge is "user-defined avoidance + reason-aware soft-block pause + honest hybrid streak." All four PROJECT.md anti-features (social, gamification, AI/LLM, whitelisting) are confirmed by competitive research as actively harmful to this wedge, not merely out-of-scope.

**Must have (table stakes — v1):**
- Avoidance list CRUD (Apps + Habits unified) with reason note per entry
- Sequenced permission priming + Settings deep-links (notifications, UsageStats, Accessibility)
- App-launch interception via AccessibilityService + full-screen Flutter pause Activity
- "Do you really need it now?" pause screen displaying the user's *own stated reason*
- Cooldown timer (1/3/5/10 min) with auto-close on expiry
- Per-app screen time + daily/weekly/monthly dashboard with not-to-do entries highlighted
- Per-item hybrid streak (system threshold + daily self-report check-in)
- Daily reminder notification at user-chosen time (exact alarm, survives reboot)
- First-run quick-add of common offenders (Instagram, TikTok, X, YouTube, Reddit)
- Local export (CSV/JSON) + reset all data (trust signals + Play review expectation)

**Should have (differentiators — keep in v1 if budget allows):**
- "Avoided today" highlighted card on home (direct visual answer to "how am I doing?")
- Total time-avoided / launches-blocked cumulative (positive feedback without gamification)
- Per-item usage threshold (5-min default in v1; expose UI in v1.x)
- Hybrid streak credibility markers ("system-confirmed" vs "self-reported only")

**Defer (v1.x / v2+):**
- Per-item usage threshold UI (default-only in v1)
- Streak history calendar heatmap
- Custom cooldown durations beyond 1/3/5/10
- Home-screen widget for "avoided today"
- Time-of-day "danger zones" breakdown
- iOS port, optional Supabase sync, Kid Mode, content filter — Milestones 2–4

**Locked anti-features (do NOT add; PROJECT.md + research both confirm):**
Social/leaderboards, gamification (points/badges/coins/levels/mascots), AI/LLM coaching, whitelisting/positive-habit tracking, hard-block mode, scheduled blocking, per-app daily limits, uninstall protection / device admin, streak freeze / vacation mode, telemetry, FCM, math-problem/typing-task bypasses.

### Architecture Approach

A Flutter (Dart) UI process runs the standard layered architecture (Presentation / Domain / Data) with the platform side bridged via Pigeon-typed channels. The native side (Kotlin) hosts (a) a thin `UsageStatsBridge` for `UsageStatsManager` queries, (b) a `NotToDoAccessibilityService` that owns its own in-memory `Set<String>` block-list snapshot and launches a separate `PauseActivity` (Flutter) when a blocked package foregrounds, and (c) a `NotificationScheduler` using `AlarmManager` for daily reminders + `WorkManager` for streak rollover. **The pause UI is a full-screen FlutterActivity launched by the AccessibilityService — NOT a `SYSTEM_ALERT_WINDOW` overlay** (this is an architecture-level decision that overrides PROJECT.md's original "pause overlay" framing and is well-justified by Play policy + Android 12+ overlay restrictions + flutter_overlay_window's hosting complexity).

The data flow is deliberately **one-way and async**: Dart broadcasts block-list updates to the service via LocalBroadcast; the service launches PauseActivity via Intent extras; PauseActivity (Dart) writes the pause-event row. **One writer (Dart), no two-process SQLite contention.**

**Major components:**
1. **Flutter UI process (Dart)** — feature-first vertical slices (`features/onboarding`, `features/block_list`, `features/dashboard`, `features/pause`, `features/checkin`, `features/settings`) on top of layered `data/domain/core`
2. **Pigeon-typed platform bridges** — `usage_api.dart`, `accessibility_api.dart`, `overlay_api.dart`, `notification_api.dart`; single source of truth for Dart↔Kotlin types
3. **NotToDoAccessibilityService (Kotlin)** — passive trigger: receives `TYPE_WINDOW_STATE_CHANGED`, debounces, matches in-memory block-list, launches PauseActivity. Never writes DB. Refreshes block-list on `ACTION_BLOCKLIST_UPDATED` broadcast.
4. **PauseActivity (FlutterActivity)** — second FlutterActivity declared `singleInstance` + `excludeFromRecents`; pre-warms via `FlutterEngineCache` to hit sub-300ms cold-start; reads Intent extras and shows pause UI
5. **NotificationScheduler (Kotlin)** — `AlarmManager.setExactAndAllowWhileIdle()` for daily reminder (re-armed by `BOOT_COMPLETED` receiver); `WorkManager` periodic for streak rollover (24h flex, Doze-tolerant)
6. **Drift SQLite (single writer = Dart)** — `block_list`, `daily_streak`, `pause_events`, `daily_checkins`, `daily_usage_summary` (pre-aggregated)

**Key architecture patterns (already locked by research):**
- Native-owned event source, Dart-owned UI state — sidesteps the flutter#76988 background-isolate-EventChannel footgun entirely
- Pigeon for Dart→Native sync calls; LocalBroadcast for the few Native→Dart pokes; **never** EventChannel from a background isolate
- Polling + caching for `UsageStatsManager` (5-min staleness for today, immutable for past days); never streaming
- AlarmManager for user-perceived precise time; WorkManager for Doze-tolerant rollover; **never both for the same job**
- AccessibilityService is a **passive trigger** — DB is the source of truth; service can die without losing state

### Critical Pitfalls

1. **Play Store rejection for AccessibilityService misuse** — The Jan-28-2026 policy explicitly prohibits "autonomously initiate, plan, and execute actions." Avoid by: setting `isAccessibilityTool="false"`, writing a literal mechanical declaration, shipping a closed-track build first, and architecting AccessibilityService as a swappable trigger so a kill-switch fallback (UsageStats polling) ships without rework.
2. **OEM battery managers silently kill the service** (Xiaomi, Huawei, Samsung, Oppo, Vivo, OnePlus). The Pixel-only test passes; real users on Xiaomi don't. Avoid by OEM-aware fix-it flows from `Build.MANUFACTURER`, battery-opt exemption prompts, self-healing health checks, and **overnight tests on real Xiaomi + Samsung hardware as a phase-exit gate**.
3. **Permission onboarding cliff (4 Settings hand-offs)** — sequence contextually, animated GIFs per OEM, `onResume` auto-advance, OEM-specific fallback paths.
4. **`SYSTEM_ALERT_WINDOW` overlay restrictions** — locked decision: pause UI is FlutterActivity launched from AccessibilityService (on the documented exemption list).
5. **Streak dishonesty** — boot-monotonic clock-jump detection, "incomplete data" markers rather than auto-break, "system-confirmed" vs "self-reported only" labels; uninstall-resets-streak is a feature.
6. **Doze + App Standby Buckets** — FGS + `setExactAndAllowWhileIdle` + lazy-evaluation streak rollover.
7. **Notification permission denied on Android 13+** — earned prompt (after first not-to-do app added), custom rationale, in-app fallback banner.

## Implications for Roadmap

**Phase 1: Foundation — data/domain skeleton + Play declaration.** Pure Dart, fast feedback. Drift schema + domain entities + `BlockListRepository` CRUD + manifest skeleton. **Play Store declaration copy committed in `docs/play-declaration.md` BEFORE any service code is written.**

**Phase 2: Onboarding + permissions plumbing.** Sequenced flow (notifications → UsageStats → Accessibility → battery-opt), `onResume` return-detection auto-advance, animated GIFs, `Build.MANUFACTURER`-aware fallbacks, post-OTA re-verification.

**Phase 3: UsageStatsManager bridge + dashboard.** Pigeon `usage_api.dart`, Drift cache, daily/weekly/monthly view, "Avoided today" home card. Validates the Pigeon channel pattern on a low-risk surface.

**Phase 4: AccessibilityService + Pause UX (the wedge).** Pigeon `accessibility_api.dart`, `NotToDoAccessibilityService` (Kotlin) with debounce + in-memory block-list, PauseActivity (FlutterActivity) with `FlutterEngineCache` pre-warm, cooldown timer, reason-note display, OEM survival, self-healing health check.

**Phase 5: Streak engine + daily check-in + reminder.** `StreakEngine` use case, daily check-in screen, `daily_streak` rows with status + source, clock-jump detection, lazy rollover, `flutter_local_notifications` daily reminder with `setExactAndAllowWhileIdle`, `BOOT_COMPLETED` re-arm, earned `POST_NOTIFICATIONS` prompt.

**Phase 6: Polish + Play Store submission.** Empty states, app-picker via `<queries>` element + LAUNCHER intent filter (NOT `QUERY_ALL_PACKAGES`), light/dark, settings, permission-revoked recovery, local export (CSV/JSON), reset-all-data, first-run quick-add curated set, Data Safety form, closed-track Play submission as A/B before public release.

### Phase Ordering Rationale

- **Architecture-and-permissions-first** is forced by pitfalls 1, 2, 3, 4, 7: getting Play declaration, OEM survival, permission funnel, and "service is passive trigger" decision wrong is cheap to fix in Phase 1–2 and very expensive later.
- **Pause UX is the wedge but not first** — Phase 3 (Dashboard) ships visible value AND validates the Pigeon channel pattern with a low-risk first integration before the blocker depends on it.
- **OEM-survival overnight testing is a per-phase gate** from Phase 4 onwards — not a single phase.

### Research Flags

Phases likely needing deeper research during planning (`/gsd-research-phase`):
- **Phase 4** (AccessibilityService + Pause UX): Highest research need — empirical Play pass rates, FlutterEngineCache cold-start measurements, OEM-specific fix-it flow steps, native-Kotlin AccessibilityService fallback prototype.
- **Phase 5** (Streak engine): MEDIUM — Doze-window behaviour of `setExactAndAllowWhileIdle` on Android 14/15/16; lazy-evaluation rollover edge cases (DST + timezone + offline + reboot combinations); empirical `POST_NOTIFICATIONS` accept rates.
- **Phase 6** (Polish + submission): MEDIUM — closed-track A/B strategy, Data Safety form ML cross-check failure modes.

Phases with standard patterns (skip `/gsd-research-phase`): Phase 1, 2, 3.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Framework/DB/notifications/state-management verified against pub.dev + official docs. AccessibilityService **package** confidence is HIGH; Play **acceptance** confidence is MEDIUM. |
| Features | MEDIUM-HIGH | Competitor features verified across 5+ apps; S/M/L estimates are educated. |
| Architecture | HIGH | Android platform mechanics verified. Pigeon + activity-launch-from-AccessibilityService well-documented. |
| Pitfalls | HIGH | Policy/OEM/battery pitfalls corroborated by Google docs + dontkillmyapp.com + multiple independent dev experiences. |

**Overall confidence:** MEDIUM-HIGH. Two MEDIUM-confidence load-bearing items (Play reviewer behaviour, real-world OEM survival) are addressed by Phase 1 declaration-first discipline and the per-phase real-device exit gate.

### Gaps to Address

- Empirical Play review pass rate for non-accessibility-tool a11y declarations in 2026 — closed-track build before public release; kill-switch fallback (UsageStats polling) ready.
- AccessibilityService latency on `TYPE_WINDOW_STATE_CHANGED` on real mid-range devices — stopwatch-test in Phase 4 on real low-end device. Target sub-500ms detect-to-pause; sub-300ms PauseActivity cold-start.
- `flutter_accessibility_service` and `flutter_overlay_window` package staleness (12 months) — hand-rolled Kotlin AccessibilityService fallback prototype during Phase 4; bridge swappable.
- Default streak-break threshold (5 min) — ship default-only in v1; expose dial in v1.x.
- Default daily reminder time (8pm) — user-configurable from day one; A/B in v1.x post-launch.
- OEM fix-it flow per-vendor steps — route to dontkillmyapp.com per-vendor pages rather than hardcoding.

## Sources

### Primary (HIGH confidence)
- pub.dev: flutter_local_notifications 21.0.0, flutter_riverpod 3.3.1, drift 2.32.1, app_usage 4.1.0, permission_handler 12.0.1, pigeon
- Google Play: Use of the AccessibilityService API; Permissions and APIs that Access Sensitive Information; Target API level requirements
- Android Developers: AccessibilityService; Create an accessibility service; UsageStatsManager; Foreground service types (Android 14); Behavior changes Android 15; Behavior changes Android 12; Optimize for Doze and App Standby; App Standby Buckets; Notification runtime permission; Schedule alarms; WorkManager
- Don't Kill My App (canonical OEM-killer reference)
- flutter#76988 — EventChannel not working in background; flutter#62738 — platform channel from background service

### Secondary (MEDIUM confidence)
- pub.dev: flutter_accessibility_service 1.0.0 (12 months stale), flutter_overlay_window 0.5.0 (12 months stale, not used in chosen architecture), usage_stats 1.3.1 (alternate)
- Hive vs Isar vs Drift comparisons (multiple sources confirm Isar abandonment)
- Riverpod vs Bloc 2026 analyses
- Competitor analysis: ScreenZen, Opal, one sec, AppBlock, Forest, Habitica, Bark, Qustodio
- 2026 Accessibility Services Policy Update analysis
- "What Android OEMs do to background apps" (DEV.to)
- "Beyond Doze" (ProAndroidDev)
- TimelessSky App Gatekeeper v1.1 technical writeup (UsageStatsManager polling latency ~2.5s)

### Tertiary (LOW confidence — needs validation in implementation)
- AccessibilityService latency on `TYPE_WINDOW_STATE_CHANGED` (sub-500ms claim) — verify in Phase 4 on real mid-range device
- Default streak-break threshold (5 min) — verify post-launch with beta-tester observation
- Default daily reminder time (8pm) — A/B in v1.x
- POST_NOTIFICATIONS accept rate with "earned prompt" pattern — popular-press citation; validate with own beta

---
*Research completed: 2026-04-27*
*Ready for roadmap: yes*
