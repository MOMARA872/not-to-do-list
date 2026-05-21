# Phase 5: Streak Engine & Daily Reminder - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Source:** /gsd-discuss-phase 5 (interactive — 4 of 4 gray areas discussed; 16 sub-questions)

<domain>
## Phase Boundary

Phase 5 delivers the **trust layer**: an honest per-item streak engine (system threshold + daily self-report) and a single daily reminder at a user-chosen time. The streak is the only reinforcement loop in v1 — gamification, badges, social features, and aggregated "score" UIs remain explicitly out of scope (anti-feature lock in PROJECT.md and Phase 4 carry-forward).

Concrete deliverables (STRK-01..09, NOTF-01..07):

1. **Streak rollover engine.** Lazy-evaluated on every app open (STRK-05) — no `WorkManager` periodic job for streak rollover (Phase 4 carry-forward, "Phase 5 introduces WorkManager only for streak rollover + reminder re-arm" was Phase 4's hint but the **engine itself stays lazy-on-open** per STRK-05; WorkManager appears only for reminder re-arm via `BOOT_COMPLETED`). For each entry, compute yesterday's `DailyStreak` row from `daily_usage_summary` + `daily_checkins` joined against `block_list.schedule_*` (STRK-09 schedule window).

2. **Daily self-report check-in.** One prompt per entry per day (STRK-03). Surface = dedicated `/checkin` route listing all pending entries on one screen with Yes/No per row and a single submit. Triggers = reminder tap (NOTF-03 deep-link) AND first Home open after midnight. Answer window = all-day until next midnight (STRK-03 + STRK-04 source label).

3. **Streak honesty labeling.** Each `DailyStreak.source` tagged 0 = system-confirmed (a11y was tracking) or 1 = self-reported-only (a11y was off) per STRK-04. Each `DailyStreak.status` tagged 0 = success, 1 = broken, 2 = incomplete-data (clock tamper detected, STRK-06), 3 = pending (today, not yet rolled over).

4. **Clock-tamper guard (STRK-06).** Compare `System.currentTimeMillis()` walk against `SystemClock.elapsedRealtimeNanos()` boot-monotonic walk. On >24 h divergence vs last evaluation, flag that day as `status=2` (incomplete-data) — never silently break the streak.

5. **Schedule-aware streak (STRK-09).** For scheduled entries (`block_list.schedule_*` non-null), only usage **inside the active window** counts toward the threshold. Out-of-window usage recorded in `daily_usage_summary` but ignored by the streak engine. Day boundary = the **calendar day the window starts** (windows that cross midnight, e.g. 22:00–06:00, belong to the start day's streak row). Kotlin `isInScheduleWindow` Dart-parity helper from Phase 4 stays the source of truth.

6. **Daily reminder.** `AlarmManager.setExactAndAllowWhileIdle()` (NOTF-04) at user-chosen time (NOTF-01) — default 21:00. Single notification covering all entries (not one per entry) with deep-link to `/checkin` (NOTF-02 + NOTF-03). `BOOT_COMPLETED` receiver re-arms after reboot (NOTF-05).

7. **Earned POST_NOTIFICATIONS prompt (NOTF-06).** Permission requested only after the user adds their first not-to-do entry. Custom rationale screen precedes the system dialog.

8. **Permission-denied fallback (NOTF-07).** Sticky banner top of Home: `"Reminder is off — tap to fix"`. Reuses Phase 3 `HealthCheckBanner` pattern exactly.

9. **Home streak surface (STRK-07).** Inline per-entry badge `🔥 3 · best 12` in each home entry card's metadata row. Tap routes to entry detail's new **Streak history** section (calendar grid with 4 day-status dots: green ✓ system-confirmed, blue ○ self-reported-only, red × broken, grey — incomplete-data).

**Exit gate (success criterion 6):** REL-05 overnight survival — streak rollover, alarm-fired reminder, and `BOOT_COMPLETED` re-arm all PASS on a real Xiaomi or Samsung device (not Pixel-only). Reminder fires within 5 minutes of scheduled time after overnight idle; streak rolls over correctly the next morning. Mirrors Phase 4 REL-04 protocol on Samsung Galaxy S20 Ultra 5G (PASSED 2026-05-21).

</domain>

<decisions>
## Implementation Decisions

### Daily check-in UX (D-01..04)

- **D-01 — Trigger: BOTH reminder tap AND Home open.** On day D+1 cold-start of Home, if any entry has `daily_checkins WHERE day=D AND entryId=X` missing, surface the pending state. Reminder notification fires at user's chosen time on day D (NOTF-02) and deep-links to `/checkin` (NOTF-03) — same destination as the Home-triggered path. Both code paths route to the same `/checkin` screen. No double-prompt: `/checkin` is idempotent — already-answered entries just show as completed in the list.

- **D-02 — Surface: dedicated `/checkin` GoRoute.** Full-screen, calm, focused. Lists all pending entries with `Yes` / `No` toggle per row plus a single `Submit` button. NOT a bottom-sheet on Home, NOT per-card inline toggle. Reminder deep-link target. New `GoRoute(path: '/checkin', builder: …)` added to `lib/core/router/app_router.dart` (same pattern Phase 3 used for `/dashboard`).

- **D-03 — Multi-entry: single screen, all entries listed, single submit.** Yes/No per row, one `Submit` action writes N rows to `daily_checkins` in a single Drift transaction. NOT one-by-one swipe-through. Fastest, lowest friction.

- **D-04 — Answer window: all-day until next midnight.** Yesterday's check-in is answerable until tonight's midnight (home-tz `LocalDate` boundary per STRK-08). At next-midnight rollover, unanswered entries are written with `source=1` (self-reported-only = false implied) — streak source falls back to system-confirmed-only IF a11y was tracking, else `status=2` (incomplete-data). 48-hour grace was rejected — would blur streak honesty.

### Streak break + recovery copy (D-05..08)

- **D-05 — Break visual: inline strikethrough on counter.** On the entry's home card, the day the break is detected, render `🔥 ~~3~~ → 0`. From day after onward, render `🔥 0 · best 12` (longest preserved). NO modal, NO sticky banner, NO snackbar. Calm per Phase 4 lock ("calm UI, no judgment copy" carry-forward from D-07 of Phase 4 — `pause_events` confirmation card has no streak callout because Phase 5 owns this and stays equally calm).

- **D-06 — Recovery copy: calm fresh-start.** Reset state literal copy = `"🔥 0 · best {N}"`. No `"streak ended"`, no `"try again"`, no `"yesterday was rough"`. The badge tells the story; copy stays minimal. Settings → Streak help text uses the phrase `"Each day is a fresh start"` for explanation only.

- **D-07 — Day labels (4 distinct dot styles in Streak history calendar):**
  - **green ✓** = `status=0 success` AND `source=0 system-confirmed`
  - **blue ○** = `status=0 success` AND `source=1 self-reported-only`
  - **red ×** = `status=1 broken`
  - **grey —** = `status=2 incomplete-data` (with tap-tooltip `"Tracking was off this day"`)
  Today's pending day = no dot (just date number). Tooltip is mandatory on grey to distinguish from "no data" gaps.

- **D-08 — Threshold UI: Settings-only global, no per-entry override in v1.** Single `streak_threshold_minutes` setting (default 5 per STRK-02), surfaced in Settings under `Streak`. No per-entry override field on `block_list` — schema stays exactly as-is. Entry-edit help text mentions: `"Streak breaks if you use this app over 5 min/day (change in Settings)"`. Per-entry override deferred to v1.x.

### Reminder default + notification copy (D-09..12)

- **D-09 — Default time: 21:00 (9:00 PM) local.** User can change in Settings reminder time picker (24-hour selector per NOTF-01). 9pm chosen over 8pm — late-evening reflection on full day. Stored in `shared_preferences` key `reminder_hour_minute` (single int = `hour * 60 + minute`).

- **D-10 — Notification copy: calm question.**
  - Title: `"Daily check-in"`
  - Body: `"How did today go?"`
  - Tap action: `PendingIntent` launching the app with deep-link to `/checkin` (NOTF-03).
  - NO streak-aware personalization (`"Keep your 3-day streak going"` rejected — generic when streak=0 and breaks personality between entries).
  - NO entry names in copy (privacy — notification banner could be seen by others).

- **D-11 — Notification scope: ONE notification covering all entries.** Single `Notification` with channel `daily_checkin` fires at user's time. Deep-links to `/checkin` which lists all pending entries (matches D-02/D-03). NOT one notification per entry (rejected — fatigue). NOT suppress-if-already-checked-in (rejected — Home + reminder are dual paths by design; reminder fires regardless, `/checkin` shows nothing pending if user already cleared via Home).

- **D-12 — NOTF-07 permission-denied banner: sticky top of Home, reuse Phase 3 `HealthCheckBanner`.**
  - Copy: `"Reminder is off — tap to fix"`
  - Position: above entries list, above the Phase 3 cards (`Avoided today` / `Total avoided`). Banner stack order: tracking-offline (Phase 3) > reminder-off (Phase 5).
  - Tap routes to system notification settings via `intent_open_settings` (`ACTION_APP_NOTIFICATION_SETTINGS`) IF `shouldShowRequestPermissionRationale` is false (user picked "Don't ask again"); otherwise routes to the in-app rationale + `requestPermissions` re-prompt screen.
  - No dismiss button — banner only disappears when permission state flips to granted (matches Phase 3 tracking-offline banner exactly).

### Home streak surface (D-13..16)

- **D-13 — Placement: inline per-entry badge on each home entry card.** Each entry card gets a small badge in its metadata row (next to block-mode chip and schedule chip from Phase 2). Per-item streak per STRK-01. NOT an aggregated "best streak" card above the list — that would compete with Phase 3 cards for visual weight and lose per-entry detail.

- **D-14 — Badge format: `🔥 3 · best 12`** (literal string, flame emoji + current day count + middot + literal `"best"` + longest count). Compact, scannable. Day-suffix omitted from the badge itself to stay narrow; expanded form lives in Streak history detail.

- **D-15 — Day-0 / never-tracked state: render honestly as `🔥 0 · best 0`.** No `"Start your streak"` CTA copy (rejected — engagement-y, breaks calm tone). No hidden badge (rejected — inconsistent card layout). Forward-looking with `best 0` matches D-06 fresh-start tone.

- **D-16 — Badge tap target: entry detail screen `/list/edit/:entryId` gains a new "Streak history" section.** Calendar grid (`GridView`, 7 columns) of last 30 days with the 4 day-status dots from D-07. Below the calendar: a small text block `"{current} days · best {longest}"` and `"Threshold: 5 min/day (change in Settings)"`. NOT a new `/streak/:entryId` top-level route (rejected — more code, more navigation). NOT no-tap (rejected — STRK-07 spirit is "user can drill in"). Reuses Phase 2's entry-edit route — adds a new section, not a new screen.

### Claude's Discretion (research / planner)

- **Schedule-window day-anchoring (STRK-09) implementation detail:** Kotlin `isInScheduleWindow` parity helper from Phase 4 is the source of truth. Cross-midnight windows belong to the start day's streak row per D-08-domain rule above. Pure-Dart + Kotlin parity test (`schedule_window_streak_anchoring_test.dart`) keeps both implementations in lockstep.
- **`AlarmManager` re-arm pattern:** standard `BOOT_COMPLETED` receiver + alarm re-set on every successful fire. Foreground service NOT needed (NOTF-04 says `setExactAndAllowWhileIdle` is the contract; Doze-survival is the alarm-API guarantee, not an FGS guarantee).
- **Clock-tamper detection cadence:** evaluate on every lazy rollover open. Persisted state = last `(wallClockMs, bootMonotonicNs)` pair in `shared_preferences`. Divergence threshold: > 24 h `|wallDelta - bootMonoDelta|`.
- **Drift schema additions:** none — `DailyCheckins` and `DailyStreak` tables already exist (Phase 1 scaffold). Add Riverpod providers + DAOs only.
- **Notification channel registration:** single channel `daily_checkin` registered at app start, importance = `IMPORTANCE_DEFAULT` (audible but non-intrusive). No high-priority channel.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project & roadmap

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — v1 product scope (adult self-control, on-device only, no telemetry, no FCM, calm tone, no gamification, streak is the only reinforcement loop)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` § Phase 5 — goal + 6 success criteria + REL-05 OEM-survival exit gate
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` § STRK-01..09 + NOTF-01..07 — 16 requirements scoped to this phase

### Phase 4 carry-forward (calm tone + schedule helper + service contracts)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/04-pause-ux-the-wedge/04-CONTEXT.md` — pause_events outcome enum (0=cooldown-completed, 1=cancel, 2=use-anyway), cooldownChosenSeconds, calm-UI lock, "no streak callout on pause screen" carry-forward
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/schedule/schedule_window.dart` — pure-Dart `isInScheduleWindow({ now, startMinutes, endMinutes, weekdayMask })` consumed by STRK-09
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/` — Phase 4 Kotlin port of `isInScheduleWindow` (parity-tested) reusable by streak engine if it ever runs Kotlin-side (it won't — streak runs Dart-side, but the pure-Dart helper is the source of truth)
- `/Users/jintanakhomwong/projects/not-to-do-list/test/domain/schedule/schedule_window_parity_test.dart` — parity test pattern to mirror for streak schedule anchoring

### Phase 3 carry-forward (lazy-on-open + health banner)

- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/03-screen-time-dashboard/03-CONTEXT.md` — D-12 5-minute soft-cache + D-13 `HealthCheckBanner` pattern (literal copy `"Tracking is offline — tap to fix"`) Phase 5 reuses for `"Reminder is off — tap to fix"` (NOTF-07)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/` — `HealthCheckBanner` widget Phase 5 banner copies pattern from
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_usage_summary_table.dart` — Phase 3 writer; Phase 5 reads `foregroundSeconds` per (entry, day) to compare against `streak_threshold_minutes`

### Existing scaffold (Phase 1 — tables and onboarding storage)

- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_checkins_table.dart` — `DailyCheckins(id, entryId, day, avoided, answeredAt)` with `(entryId, day)` unique key — schema is locked, only needs DAO + Riverpod provider
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/daily_streak_table.dart` — `DailyStreak(id, entryId, day, status, source, usageMinutesObserved, evaluatedAt)` with `(entryId, day)` unique key — schema is locked, only needs DAO + rollover service
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/storage_keys.dart` — `shared_preferences` key pattern Phase 5 follows for `reminder_hour_minute` and `streak_threshold_minutes`

### Routing + GoRouter

- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart` — Phase 3 added `/dashboard` non-onboarding route; Phase 5 adds `/checkin` the same way. Entry detail `/list/edit/:entryId` gets a new section, not a new route.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`DailyCheckins` / `DailyStreak` tables** (`lib/data/database/tables/`) — schema already defined Phase 1. Phase 5 only adds DAOs + Riverpod providers, no migration.
- **`HealthCheckBanner`** (`lib/features/health/`) — Phase 3 pattern for sticky top-of-Home banner with permission-denial copy. Phase 5 wraps a second instance for `"Reminder is off — tap to fix"`.
- **`isInScheduleWindow`** (`lib/domain/schedule/schedule_window.dart`) — pure-Dart helper. Streak engine reuses verbatim to gate per-day per-entry usage minutes by schedule (STRK-09).
- **`block_list_dao.dart` + `pause_event_dao.dart` + `daily_usage_summary_dao.dart`** — DAO patterns Phase 5 mirrors for `daily_checkins_dao.dart` and `daily_streak_dao.dart`.
- **Phase 3 dashboard `SegmentedButton`** (`lib/features/dashboard/`) — pattern reusable if Streak history calendar grid needs a Day/Week/Month switcher (not required by STRK spec but available).
- **`shared_preferences` storage_keys** (`lib/features/onboarding/storage_keys.dart`) — pattern Phase 5 extends with `reminder_hour_minute` and `streak_threshold_minutes`.

### Established Patterns

- **Lazy on app open (Phase 3 D-14):** streak rollover evaluation runs on app `resumed` AND on Home cold-open. NO `WorkManager` periodic job for rollover (STRK-05). WorkManager appears ONLY for `BOOT_COMPLETED` alarm re-arm + the alarm itself (`AlarmManager`).
- **Material 3 + Drift + Riverpod 3.3 + Pigeon + GoRouter** stack across all phases.
- **Calm tone + no gamification** (Phase 4 D-07 carry-forward) — no `"Nice job!"`, no badges, no points, no streak callouts on pause screen. The streak badge IS the entire reinforcement loop.
- **Per-phase REL-XX OEM-survival exit gate** — Phase 4 REL-04 (Samsung S20 Ultra ≥71 h Doze, PASSED 2026-05-21) sets the template. Phase 5's REL-05 mirrors the protocol for alarm + rollover.
- **Pigeon-typed Kotlin channels** — Phase 5 needs ONE new Pigeon API: `ReminderApi` for setting/canceling the `AlarmManager` alarm + reading boot-monotonic clock. No hand-rolled MethodChannels.
- **`test/policy/play_invariants_test.dart`** — 8 absence-grep policy tests Phase 5 must extend with new invariants (e.g., absence of `FCM`, absence of `Firebase`, absence of `WorkManager` periodic for streak).

### Integration Points

- **Home screen** (`lib/features/home/`) — gains: streak badge on each entry card (D-13..15) + reminder-off `HealthCheckBanner` (D-12). Banner stack order: tracking-offline (Phase 3) above reminder-off (Phase 5).
- **Entry detail** (`lib/features/list/` edit page) — gains a "Streak history" section (D-16): calendar grid + summary text. Tap target from home-card streak badge.
- **GoRouter** (`lib/core/router/app_router.dart`) — gains one new route: `GoRoute(path: '/checkin', builder: …)`.
- **Android manifest** (`android/app/src/main/AndroidManifest.xml`) — adds `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` (Android 13+), `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />` (Android 12+; uses USE_EXACT_ALARM if targeting 14+), `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />`, `<receiver android:name=".BootReceiver" />`, `<receiver android:name=".ReminderAlarmReceiver" />`. Must NOT trigger Play-invariant absence-grep failures — extend `play_invariants_test.dart` to whitelist these three perms.
- **MainActivity** (`MainActivity.kt`) — Phase 5 registers a Pigeon `ReminderApi` host alongside the existing `UsageApi`, `AccessibilityApi`, `BlocklistBroadcastApi` from Phases 1/3/4.
- **Onboarding** (`lib/features/onboarding/`) — Phase 5 does NOT add a step to the install-time funnel (per CONTEXT carry-forward from Phase 2 — only 3 install-time perms: Usage Access, Accessibility, battery exemption). NOTF-06 fires as an **earned prompt** after the first `block_list` insert (i.e., from the list-add flow), NOT during onboarding.

</code_context>

<specifics>
## Specific Ideas

- **Notification copy:** literal title `"Daily check-in"`, literal body `"How did today go?"`. No streak number in copy. No entry names in copy (privacy).
- **Banner copy:** literal `"Reminder is off — tap to fix"`. Direct copy of Phase 3's `"Tracking is offline — tap to fix"` pattern.
- **Streak badge:** literal format `"🔥 {current} · best {longest}"`. Day-0 = `"🔥 0 · best 0"`. Compact, scannable.
- **Default reminder time:** 21:00 local — `hour=21, minute=0` stored as int `21 * 60 + 0 = 1260` under `shared_preferences` key `reminder_hour_minute`.
- **Default streak threshold:** 5 minutes/day per STRK-02. Stored under `shared_preferences` key `streak_threshold_minutes` = 5.
- **Calendar day-status dots in Streak history:** 4 styles — green ✓ system-confirmed, blue ○ self-reported-only, red × broken, grey — incomplete-data. Tap on grey shows tooltip `"Tracking was off this day"`.
- **Clock-tamper threshold:** > 24 h `|wallDelta - bootMonoDelta|` since last evaluation flags the affected day as `status=2 incomplete-data`.
- **Schedule-window day-anchoring:** windows that cross midnight (e.g., 22:00–06:00) belong to the **start day's** streak row.
- **Notification channel:** `daily_checkin`, `IMPORTANCE_DEFAULT` (audible but non-intrusive). No high-priority channel.
- **REL-05 exit gate (mirrors REL-04):** real Xiaomi or Samsung device (not Pixel-only), overnight idle ≥ 8 h unplugged, alarm fires within 5 min of scheduled time, streak rolls over correctly on next morning open, `BOOT_COMPLETED` re-arms after device reboot.

</specifics>

<deferred>
## Deferred Ideas

- **Per-entry streak threshold override** — v1 ships a single global 5-min threshold in Settings. Per-entry override (`block_list.streak_threshold_minutes` column) deferred to v1.x.
- **Streak-aware notification copy** (`"Keep your 3-day streak going"`) — rejected for v1 calm-tone consistency.
- **One notification per entry** — rejected for v1 to avoid fatigue. Single rollup notification only.
- **Suppress notification when already checked-in via Home** — rejected; reminder + Home are dual paths by design.
- **Onboarding step for reminder time** — out of scope for v1 install-time funnel (Phase 2 locked 3-step funnel + earned POST_NOTIFICATIONS for Phase 5). Reminder time uses 21:00 default; user can change in Settings any time.
- **Dedicated `/streak/:entryId` top-level route** — rejected; Streak history is a section on entry detail, not a new route.
- **Engagement copy** ("Start your streak", "Yesterday was rough", "Try again") — rejected for calm tone.
- **Modal/snackbar/banner on streak break** — rejected; inline strikethrough on counter is the entire signal.
- **48-hour check-in grace window** — rejected; blurs streak honesty.
- **Streak sharing / social features / leaderboards** — explicit PROJECT.md anti-feature, never v1.
- **Badges / points / levels** — explicit PROJECT.md anti-feature, never v1.
- **Aggregated "best streak across all entries" card** — rejected; per-item is the truth signal.
- **Streak threshold per-entry tuning UI** — deferred to v1.x.
- **Multi-window schedules per entry** — already a Phase 2 lock; remains deferred.

</deferred>

---

*Phase: 05-streak-engine-daily-reminder*
*Context gathered: 2026-05-21 via /gsd-discuss-phase 5*
