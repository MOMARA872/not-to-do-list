# Phase 5: Streak Engine & Daily Reminder - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-21
**Phase:** 05-streak-engine-daily-reminder
**Areas discussed:** Daily check-in UX, Streak break + recovery copy, Reminder default + notification copy, Home streak surface

---

## Daily check-in UX

### Q1: When does user see the daily check-in prompt?

| Option | Description | Selected |
|--------|-------------|----------|
| On Home open next day (Recommended) | First Home open after midnight surfaces pending check-ins for yesterday. Pull-based, no notification needed. Reuses lazy-on-open pattern from Phase 3. | |
| Only at reminder tap | Reminder notification deep-links to /checkin (NOTF-03). Home doesn't surface prompts otherwise. Means user must engage with notification. | |
| Both — reminder tap AND Home open | Check-in visible from either entry point until answered. Maximum reach but possible double-prompt. | ✓ |

**User's choice:** Both — reminder tap AND Home open
**Notes:** Maximum reach; reconciled via idempotent `/checkin` (already-answered entries show as completed, not re-prompted).

### Q2: What surface hosts the check-in interaction?

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated /checkin screen (Recommended) | Full-screen route. Lists all pending entries with Yes/No per row + 'Submit'. Reminder deep-link target (NOTF-03). Calm, focused. | ✓ |
| Bottom-sheet on Home | Modal sheet on Home open. Faster but interrupts Home. Reminder deep-link still routes here via Home. | |
| Per-card inline toggle on Home | Each home entry card grows a 'Did you avoid yesterday? [Yes][No]' chip until answered. No separate screen. Mixes status with action. | |

**User's choice:** Dedicated /checkin screen
**Notes:** Single deep-link target shared by both Home and reminder triggers.

### Q3: Multiple pending entries — how does user mark them?

| Option | Description | Selected |
|--------|-------------|----------|
| Single screen with all entries listed (Recommended) | All pending entries on one screen, Yes/No per row, single Submit. Fastest. Matches dedicated /checkin if chosen above. | ✓ |
| One-by-one swipe-through | Sequential card flow, Yes/No per card, swipe-next. More deliberate but more taps. | |
| Per-card answer on Home (no batch) | Each card answered independently when user notices it. No 'submit all' action. | |

**User's choice:** Single screen with all entries listed
**Notes:** Single Drift transaction writes N rows on Submit.

### Q4: How long is yesterday's check-in answerable?

| Option | Description | Selected |
|--------|-------------|----------|
| All-day until user marks or next midnight (Recommended) | Yesterday's check-in available until tonight's midnight. After midnight, unanswered day defaults to 'self-reported-only = false' — streak source falls back to system-confirmed-only or 'incomplete data'. | ✓ |
| Until reminder time tomorrow | Check-in for day D answerable until day D+1's reminder fires. Tighter window aligned with reminder. | |
| 48-hour window | Two-day grace period — catches users who skip a day. Risks blurring streak honesty. | |

**User's choice:** All-day until user marks or next midnight
**Notes:** Honesty over grace. Home-tz `LocalDate` boundary per STRK-08.

---

## Streak break + recovery copy

### Q1: How is a broken streak shown on the entry's home card?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline strikethrough on counter (Recommended) | '🔥 3' becomes '🔥 ~~3~~ → 0' for the day the break happens, then resets to '🔥 0' next day. Subtle, no modal. Calm tone per Phase 4. | ✓ |
| Inline icon swap, no strikethrough | Counter shows '💤 0' (sleep icon) for broken day, resets to '🔥 0' day after. Even quieter. | |
| Modal on Home open the morning after break | One-time modal: 'Yesterday's streak ended — X days reached. Start fresh today?' [OK]. More visible — risks feeling punitive. | |
| Sticky banner above entries list | Banner: 'Streak ended for [entry] yesterday'. Dismissable. Less personal than per-card. | |

**User's choice:** Inline strikethrough on counter
**Notes:** Matches Phase 4 calm-UI lock.

### Q2: Recovery copy tone when streak resets?

| Option | Description | Selected |
|--------|-------------|----------|
| Calm fresh-start (Recommended) | 'Day 0 — fresh start' or '🔥 0 — new streak'. Neutral, forward-looking. No 'try again', no 'you broke it'. | ✓ |
| Pure neutral | Counter just shows '🔥 0'. No copy at all. Minimal. | |
| Encouraging callout | 'Day 0 — yesterday was rough. Today's a new try.' More words, risks feeling parental. | |

**User's choice:** Calm fresh-start
**Notes:** Literal in-UI form = `"🔥 0 · best {N}"`; the phrase `"Each day is a fresh start"` only appears in Settings → Streak help text.

### Q3: Distinguish broken vs incomplete-data day visually?

| Option | Description | Selected |
|--------|-------------|----------|
| Different icon + tooltip (Recommended) | Broken day = red × dot. Incomplete-data day = grey '—' dot with tooltip 'Tracking was off this day'. Distinct from system-confirmed (green ✓) and self-reported-only (blue ○). | ✓ |
| Same visual, different label | Both render as grey dot. Tap reveals reason. Less visual noise but loses at-a-glance trust signal. | |
| Show only system-confirmed; hide incomplete-data days | Don't render incomplete-data days in calendar/list view. Risks looking like missing-data gap. | |

**User's choice:** Different icon + tooltip
**Notes:** 4-dot vocabulary (green ✓, blue ○, red ×, grey —) is the calendar's full language.

### Q4: Streak break threshold display — surface the 5-min default?

| Option | Description | Selected |
|--------|-------------|----------|
| Settings-only, no per-entry override in v1 (Recommended) | Single global threshold (5 min) in Settings. Mentioned in entry-edit help text. No per-entry knob. Minimum code, matches v1 'single threshold default 5 min' per STRK-02. | ✓ |
| Per-entry override in entry edit | Each entry can override the 5-min default. More flexibility, more UI complexity, schema change to block_list table. | |
| No surface at all in v1 | Hard-coded 5 min. No Settings entry. Cannot tune without rebuild. | |

**User's choice:** Settings-only, no per-entry override in v1
**Notes:** `shared_preferences` key `streak_threshold_minutes`, default 5. Per-entry override deferred to v1.x.

---

## Reminder default + notification copy

### Q1: Default reminder time when user first lands in Settings?

| Option | Description | Selected |
|--------|-------------|----------|
| 9:00 PM (Recommended) | Late evening — user reflects on the full day before bed. Common for habit-app daily prompts. | ✓ |
| 8:00 PM | Earlier evening. Catches users who go to bed early. | |
| No default — onboarding forces pick | User must select reminder time in onboarding or first Settings open. Stronger commitment but onboarding step out of current Phase 2 funnel scope. | |
| Off by default | Reminder disabled until user opts in. Risks low adoption — daily reminder is core to NOTF-02. | |

**User's choice:** 9:00 PM
**Notes:** Stored as `hour * 60 + minute = 1260` under `reminder_hour_minute`.

### Q2: Notification title + body copy tone?

| Option | Description | Selected |
|--------|-------------|----------|
| Calm question (Recommended) | Title: 'Daily check-in'. Body: 'How did today go?'. Forward-looking, no judgment. | ✓ |
| Streak-aware | Title: 'Daily check-in'. Body: 'Keep your {N}-day streak going.' Personalized, but generic when streak=0. | |
| Minimal neutral | Title: 'Not To-Do List'. Body: 'Time for your check-in.' Functional, drier. | |

**User's choice:** Calm question
**Notes:** No entry names in copy (privacy — lock screen visibility).

### Q3: Single notification covering all entries, or one per entry?

| Option | Description | Selected |
|--------|-------------|----------|
| Single notification covering all (Recommended) | One notification at chosen time, deep-links to /checkin which lists all pending entries. | ✓ |
| One notification per entry | N notifications fire simultaneously. Noisy. Risks notification fatigue. | |
| Single notification only if pending check-ins exist | Suppress notification on days where user already checked in via Home. | |

**User's choice:** Single notification covering all
**Notes:** Channel `daily_checkin`, importance `IMPORTANCE_DEFAULT`.

### Q4: Reminder permission-denied banner (NOTF-07) location and copy?

| Option | Description | Selected |
|--------|-------------|----------|
| Sticky banner top of Home, reuse Phase 3 pattern (Recommended) | Banner: 'Reminder is off — tap to fix'. Sticky above entries list. Tap routes to system notification settings or in-app re-request. | ✓ |
| Banner only inside Settings | Settings reminder section shows the denial state. Home stays clean. Risks user never noticing. | |
| Banner first 7 days, then dismissable | Aggressive for one week, then dismiss permanently. Adds dismiss state to schema. | |

**User's choice:** Sticky banner top of Home, reuse Phase 3 pattern
**Notes:** Banner stack order: tracking-offline (Phase 3) > reminder-off (Phase 5). No dismiss button — disappears only on permission granted.

---

## Home streak surface

### Q1: Where does the streak counter live on Home?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline per-entry badge on each home card (Recommended) | Each home entry card shows '🔥 3 · best 12' as a small badge. Per-item streak per STRK-01. | ✓ |
| Aggregated card above entries list | Third card above entries: 'Best streak: 12 days (Instagram)'. Loses per-entry visibility. | |
| Both — inline badge + aggregated card | Per-entry badge AND a top-of-home aggregated 'longest active' card. Most visible but most visual real-estate. | |

**User's choice:** Inline per-entry badge on each home card
**Notes:** Sits next to block-mode chip and schedule chip from Phase 2 in entry-card metadata row.

### Q2: Format of current/longest counter in the badge?

| Option | Description | Selected |
|--------|-------------|----------|
| '🔥 3 · best 12' (Recommended) | Flame emoji + current day count + middot + 'best' + longest. Compact, scannable. | ✓ |
| '3-day streak · Best 12d' | Spelled out. Longer, more accessible to screen readers. Same info. | |
| Two stacked badges: '🔥 3d' / 'best 12d' | Two pill chips stacked or side-by-side. More visual weight. | |
| Current only on card, longest in entry detail | Home card shows '🔥 3'. Tap entry to see longest. Hides 'best' — STRK-07 says home shows BOTH. | |

**User's choice:** '🔥 3 · best 12'
**Notes:** Literal format string. Day-suffix omitted to stay narrow.

### Q3: What does the badge show on day-0 / never-tracked entries?

| Option | Description | Selected |
|--------|-------------|----------|
| '🔥 0 · best 0' (Recommended) | Render the zero state honestly. Forward-looking with 'best 0'. Matches calm fresh-start tone. | ✓ |
| 'Start your streak' | CTA copy on never-tracked entries. Switches to '🔥 X' after first system-confirmed day. Engagement-y. | |
| Hide badge until first system-confirmed day | No badge for never-tracked entries. Cleaner cards but inconsistent. | |

**User's choice:** '🔥 0 · best 0'
**Notes:** Honest zero state.

### Q4: Tap target on the streak badge — where does it go?

| Option | Description | Selected |
|--------|-------------|----------|
| Entry detail screen with streak history (Recommended) | Tap badge → entry detail gains a new 'Streak history' section: per-day calendar grid with green✓/blue○/red×/grey— dots. | ✓ |
| Dedicated /streak/:entryId route | New top-level route just for streak history. More navigation, more code. | |
| No tap action | Badge is display-only. Streak history not viewable in v1. | |

**User's choice:** Entry detail screen with streak history
**Notes:** Reuses existing Phase 2 `/list/edit/:entryId` route — adds a section, not a new screen.

---

## Claude's Discretion

- Schedule-window day-anchoring (STRK-09) implementation detail — Kotlin parity helper from Phase 4 is the source of truth; cross-midnight windows belong to start day's streak row.
- `AlarmManager` re-arm pattern — standard `BOOT_COMPLETED` receiver + alarm re-set on every successful fire. No foreground service.
- Clock-tamper detection cadence — evaluate on every lazy rollover open; persisted `(wallClockMs, bootMonotonicNs)` pair in `shared_preferences`; > 24 h `|wallDelta - bootMonoDelta|` divergence threshold.
- Drift schema additions — none. `DailyCheckins` + `DailyStreak` already scaffolded Phase 1.
- Notification channel registration — single `daily_checkin` channel, `IMPORTANCE_DEFAULT`.

## Deferred Ideas

- Per-entry streak threshold override → v1.x
- Streak-aware notification copy → rejected (calm-tone lock)
- One notification per entry → rejected (fatigue)
- Suppress notification when already checked-in via Home → rejected (dual paths by design)
- Onboarding step for reminder time → out of scope (3-step funnel locked Phase 2)
- Dedicated `/streak/:entryId` top-level route → rejected (section on entry detail instead)
- Engagement copy ("Start your streak", "Try again") → rejected (calm tone)
- Modal / snackbar / banner on streak break → rejected (inline strikethrough only)
- 48-hour check-in grace → rejected (honesty)
- Streak sharing / social / leaderboards → PROJECT.md anti-feature (never v1)
- Badges / points / levels → PROJECT.md anti-feature (never v1)
- Aggregated "best streak across entries" card → rejected (per-item is truth)
- Multi-window schedules per entry → already Phase 2 lock (deferred)
