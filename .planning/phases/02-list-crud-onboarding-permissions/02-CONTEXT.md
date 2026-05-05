# Phase 2: List CRUD + Onboarding & Permissions — Context

**Gathered:** 2026-05-05
**Status:** Ready for planning
**Source:** /gsd-discuss-phase 2 (interactive — 3 areas selected by user, plus a follow-up sub-area for the new block-mode + schedule fields after a v1 scope expansion was approved mid-discussion)

<domain>
## Phase Boundary

Phase 2 delivers the user's first interaction with the product after install:

1. **The not-to-do list itself** — a unified list of Apps + Habits the user wants to avoid, with full CRUD (add / edit / delete), per-item reason note, per-item block mode (soft / hard, Apps only), and per-item optional active-window schedule.
2. **The 4-step permission funnel** — installation-time onboarding that walks the user through Notifications, Usage Access, Accessibility, and battery-optimization exemption with custom rationale screens, return-detection auto-advance, and OEM-aware fallbacks.
3. **The persistent health check** — `Tracking offline — fix` banner on home + dontkillmyapp.com vendor links if any required permission is later revoked.

Phase 2 does NOT implement: launch interception (Phase 4), the dashboard (Phase 3), the streak engine (Phase 5), or daily reminder notifications (Phase 5). The Phase 2 data model carries `block_mode` and `schedule` columns so Phases 4 + 5 can read them without schema migration.

</domain>

<v1_scope_carryforward>
## v1 Product Scope — locked, must respect during planning and execution

Per the 2026-05-05 PROJECT.md update committed in `7119f85`, v1 is positioned as an **adult self-control blocker**, NOT a parental-control product. Downstream agents MUST respect:

**In scope (v1):**
- Adult self-control only (single-user model)
- App **soft-block by default** (cooldown + "Use anyway")
- App **hard-block as per-item opt-in** (LIST-08, PAUS-09 — Apps only; cooldown still applies, but no "Use anyway" path)
- **Per-item schedule opt-in** (LIST-09, PAUS-10, STRK-09 — single optional active window per entry)
- Habits remain **self-report only** (no system blocking; no hard-block; schedule is permitted on Habits but only affects daily-check-in prompts, not interception)

**Explicitly NOT in v1 — do not absorb during planning:**
- Parent PIN / Settings lock
- Kid mode / age profiles
- Website blocking (browser, VPN-DNS, per-browser hooks)
- 18+ / content-type filtering
- Anti-uninstall / device admin
- Parental dashboard / remote control
- Per-app daily quota limits (different from per-item schedules)
- Multiple schedule windows per entry (one optional window only in v1)
- Schedule presets (Work hours / Bedtime / etc.) (no presets in v1)

If gray areas surface during research or planning that would require any of the above, defer to Milestone 2 — DO NOT silently add them.
</v1_scope_carryforward>

<decisions>
## Implementation Decisions

### Onboarding flow (locked during discuss-phase)

- **Shape:** `Welcome → Quick-add → 3-permission funnel → Home`. POST_NOTIFICATIONS is requested AFTER the install-time funnel completes (when user lands on home), not inside the funnel — preserves the "earned prompt" decision from PROJECT.md.
- **Welcome screen:** ONE headline + ONE CTA. Headline frames the product as "Build your Not-To-Do list" with a one-line privacy claim ("We never see your data."). CTA: "Get Started." Single screen — no multi-screen value-prop carousel.
- **Quick-add picker (LIST-07):** full-screen, 5 cards (Instagram, TikTok, X, YouTube, Reddit) with logos + checkboxes, **all unchecked by default** (mindful avoidance frame — user opts in). Single CTA at bottom: "Continue" (works whether 0 or 5 are selected).
- **Permission funnel:** 3 steps in order — (1) Usage Access, (2) Accessibility, (3) battery-optimization exemption. Each step shows a custom rationale screen before the system Settings deep-link.
- **Skip behavior:** 1-tap skip on every step + footer note explaining the consequence ("Without this, X won't work; you can fix it later from home"). NO "Are you sure?" dialog. Respects autonomy, matches REL-02 health-check banner.
- **Settings guidance assets:** **Static screenshot PNGs** in `assets/onboarding/` — no animated GIFs (smaller APK, simpler integration). One screenshot per system-Settings screen we deep-link to. Captured on a Pixel running stock Android 16.
- **OEM guidance timing:** **Reactive** only — fire the standard Settings intent first; if it doesn't resolve OR the user returns from Settings without granting, then show OEM-specific instructions keyed off `Build.MANUFACTURER`. Non-OEM users stay in the fast path. Routes to dontkillmyapp.com per-vendor pages for the battery-opt step.
- **Resume state:** persisted in `shared_preferences` under key `onboarding_step` (int, 0–3). On cold launch, app reads the cursor, recomputes per-permission grant state, and reopens at the next pending step. Already-granted steps are skipped on resume.
- **Health-check banner severity (post-onboarding revoke):** subdued informational amber bar at top of home, non-modal, single-line copy ("Tracking is offline — tap to fix"). Tap routes back into the relevant funnel step. NOT a red warning, NOT a modal dialog.

### App picker (locked)

- **Picker layout:** Search-first + Suggested + Recent + Alphabetical. Top: search bar. Below: "Suggested" section showing the 5 common offenders (filtered to only those NOT already added). Below that: "Recently used" section showing apps from `UsageStatsManager` (top 5 by total foreground time over last 7 days; only shown if Usage Access is granted). Below that: alphabetical list of all installed launchable apps.
- **System apps filter:** Hide non-launchable system apps by default (filter `ApplicationInfo.FLAG_SYSTEM` AND no launch intent), with a **"Show all" toggle** in the picker for power users. Combined with the manifest's existing `<queries>` + LAUNCHER intent filter (already in place from Phase 1).
- **Already-blocked apps in picker:** Show them in the list but **disabled and greyed-out**, with an "already added" subtitle. NOT hidden, NOT linked to edit. User sees the full picture of their not-to-do list while picking new ones.
- **Search match:** Display name only, case-insensitive substring. NOT package name. NOT fuzzy. (User mental model = "I want TikTok"; package name `com.zhiliaoapp.musically` is irrelevant.)
- **Icon strategy:** Fetch on demand via `PackageManager.getApplicationIcon`, cache in **in-memory LRU (50 entries)**. NO disk persistence. Drops on app close; rebuilds on next picker open. Acceptable cost for v1 — no 5–10 MB cache directory bloat.
- **After save:** Return to home with the new entry visible at the top of the list. NOT stay-in-picker, NOT show-detail-page. Clear feedback that the action completed.
- **Habit entry path:** Two separate buttons on home — `+ Add app` and `+ Add habit`. NOT one button with a type-selector modal. NOT a tab bar inside the picker. Each entry type has its own optimized flow (picker for apps, free-text form for habits).

### Reason note (LIST-03) — locked

- **Required?** Optional. Empty entries get a generic fallback shown on the pause screen (e.g., "Pause and reflect"). The editor shows a soft suggestion: "Why are you avoiding this?" but Save works without input.
- **Char limit:** 500 (soft, on-input enforced — counter visible past 400 chars). No rich text. Plain text only.

### List + entry editor UX (locked)

- **Row layout:** **Compact row** (~64 dp). Layout: leading icon (app logo for Apps; generic icon for Habits) → name → reason snippet (one line, ellipsized) → trailing streak count. Density-first; ~8–10 items per screen on a typical phone. NOT spacious cards, NOT expand-on-tap.
- **App vs Habit visual distinction:** **Icon source only.** Apps show their `getApplicationIcon` Drawable; Habits show a generic icon (e.g., a plant/leaf glyph or a circled letter from the habit name). Same row layout otherwise. NO badges, NO tags, NO sectioned grouping. The unified list stays unified.
- **Edit gesture:** Tap row → full **detail/edit page**. NOT inline expand. NOT long-press for menu. Tap is reserved for editing; long-press has no behavior in v1.
- **Delete UX:** **Delete button on the edit page only.** NOT swipe-to-delete (user explicitly chose safety over speed). Cascade delete (streak history + pause-events) is silent — no confirm dialog, but the delete button itself is at the bottom of the edit page in destructive-red styling.
- **Sort order on home (LIST-06):** sorted by **last activity** desc, where "activity" = `MAX(last_edit_time, last_pause_event_time, last_check_in_time)`. New entries naturally appear at the top because their `last_edit_time` is most recent.

### Block-mode toggle (LIST-08) — locked

- **Editor placement:** **Segmented control** on the edit screen — `Soft (default)` | `Hard`. Inline subtitle below explains the difference: "Soft: cooldown + 'Use anyway'. Hard: cooldown only, no override." One tap to toggle. Visible by default, NOT hidden under Advanced.
- **Habits restriction:** The segmented control is hidden for Habit entries (Habits are self-report only — no system interception, so block-mode is meaningless). LIST-08 explicitly states `Apps only`.
- **Default value for new entries:** `soft` (matches PROJECT.md key decision: "Soft-block + cooldown is the DEFAULT pause UX").

### Schedule editor (LIST-09) — locked

- **UI shape:** Single optional active window per entry, with three controls: start time (time picker), end time (time picker), weekday mask (7 chips: M T W T F S S — all selected by default, tap to toggle). NO multiple windows. NO presets. NO "Quick add: Work hours / Bedtime" — out of scope for v1.
- **Default state:** "Always on" (no schedule). User must tap a "Set schedule" toggle to reveal the time + weekday inputs. Toggling off removes the schedule and returns the entry to always-on.
- **Cross-midnight handling:** Treat as **one continuous window**. Internally stored as `(start_time, end_time, weekday_mask)` where `end_time < start_time` means the window crosses midnight. Active-window evaluation: at lookup time, given the current `LocalDateTime`, the window covers `[today's start_time → tomorrow's end_time]` if `end_time < start_time`, else `[today's start_time → today's end_time]`. Streak day boundary uses **04:00 local time** to avoid "late-night = new day" confusion (e.g., usage at 02:00 counts toward the previous calendar day's window).
- **Storage shape (Drift schema for Phase 2):** add nullable columns to `block_list` table — `schedule_start_minutes` (int, 0–1439, nullable), `schedule_end_minutes` (int, 0–1439, nullable), `schedule_weekday_mask` (int, 7-bit, nullable). All three nullable together — entry has a schedule iff all three are non-null.

### Hard-block + schedule combination — locked

- **Independent toggles.** An entry CAN be both hard-block AND scheduled. Outside the active window: dormant (no interception). Inside the active window: intercept, and if hard-block, omit "Use anyway." Most flexible, no spurious mutual-exclusion logic.

### Health-check banner (REL-02 / REL-03)

Claude's discretion (user did not select this gray area). Default plan during planning:
- Subdued amber bar at the top of home, single line: "Tracking is offline — tap to fix"
- Tap → routes into onboarding at the relevant pending step (re-using the same screens as install-time)
- Includes a "What's wrong?" expandable that lists each missing permission + a per-OEM hint linking to dontkillmyapp.com when `Build.MANUFACTURER` matches a known aggressive vendor

If during planning this conflicts with anything, surface as a checkpoint.

### Folded Todos

None for Phase 2 (no pending todos matched on `gsd-sdk query todo.match-phase 2`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (locked decisions)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — v1 product scope as updated 2026-05-05 (adult self-control, hard-block opt-in, schedules opt-in, all parental-control features deferred)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 68 v1 REQ-IDs; Phase 2 owns LIST-01..09 + ONBD-01..07 + PLAY-06 + REL-02 + REL-03
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` — phase boundaries and per-phase success criteria

### Project-level research (do not duplicate; read directly)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/STACK.md` — Flutter 3.41 + Riverpod 3.3 + Drift 2.33 + Pigeon 26.3 stack pins
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` — Pigeon-typed channels, AccessibilityService-as-passive-trigger, single-writer SQLite, Activity-launch over `SYSTEM_ALERT_WINDOW`
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` — Play Store policy (a11y), OEM battery killers, permission funnel cliff (relevant for ONBD-01..07), notification permission earned-prompt (NOTF-06 in Phase 5)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` — cross-phase synthesis

### Phase 1 outputs (data layer + manifest already shipped)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/01-foundation-play-declaration/01-RESEARCH.md` — verbatim Drift schema (Phase 2 schema additions are deltas, not rewrites); also contains the existing `block_list` table shape that LIST-08/09 columns extend
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/app_database.dart` — current `@DriftDatabase` declaration; Phase 2 adds a v2 migration step
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/block_list_table.dart` — table to extend with three nullable columns + `block_mode` enum column
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/AndroidManifest.xml` — already has `<queries>` + LAUNCHER intent filter (used by LIST-01 picker)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/blocked_app_detector.dart` + `lib/domain/providers/blocked_app_detector_provider.dart` — hand-written Riverpod selector (no codegen); Phase 2 does NOT modify; Phase 4 lights it up
- `/Users/jintanakhomwong/projects/not-to-do-list/docs/play-declaration.md` — Accessibility prominent disclosure (PLAY-06) copy must mirror this verbatim

### External (Android docs)
- https://developer.android.com/reference/android/app/usage/UsageStatsManager — for the "Recently used" picker section
- https://developer.android.com/guide/topics/manifest/queries-element — `<queries>` semantics already wired in Phase 1
- https://dontkillmyapp.com/ — per-OEM links surfaced from health-check banner (REL-03)

### CLAUDE.md guardrails
- `/Users/jintanakhomwong/projects/not-to-do-list/CLAUDE.md` — Karpathy guidelines: simplicity first, surgical changes, no speculative scope. Particularly relevant for resisting the parental-control feature pull during planning.

</canonical_refs>

<code_context>
## Reusable assets and patterns from Phase 1

- **`flutter_riverpod` 3.3.1** is in pubspec; providers are hand-written (no `@riverpod` codegen — see Phase 1 deviation note in `.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md`)
- **`shared_preferences` 2.5.5** is already in pubspec — use for `onboarding_step` cursor (no new dep)
- **`go_router` 17.2.3** is already in pubspec; one route exists (`/` → `EmptyHomeScreen`); Phase 2 adds routes for `/onboarding/welcome`, `/onboarding/quick-add`, `/onboarding/permissions/<step>`, `/list/add-app`, `/list/add-habit`, `/list/edit/<id>`
- **Drift schema** has 5 tables (`block_list`, `daily_streak`, `pause_events`, `daily_checkins`, `daily_usage_summary`); Phase 2 needs a v2 migration adding `block_mode` (text/enum) and the three nullable schedule columns to `block_list`
- **`<queries>` + LAUNCHER** intent filter is already in `AndroidManifest.xml` from Phase 1 (PLAY-04 satisfied) — installed-app picker can use `PackageManager.queryIntentActivities` directly
- **No telemetry / no FCM / no analytics** in dep tree — verified by Phase 1 V10 dep audit; do NOT add any during Phase 2 (SETT-03 invariant)
- **Pigeon channel skeletons** for `usage_api`, `accessibility_api`, `notification_api` exist as `@HostApi` stubs in `pigeons/` and `lib/platform/*.g.dart` — Phase 2 lights up `usage_api.queryRange()` for the picker's "Recently used" section. Accessibility and notification APIs stay stubs until Phase 4/5.
- **`PauseActivity.kt`** stub already exists in the manifest (declared as `FlutterActivity`, `singleInstance` + `excludeFromRecents`) — Phase 2 does NOT touch it.
- **Lints** are enforced via `very_good_analysis 10.2.0`; Phase 2 code must analyze clean.

</code_context>

<specifics>
## Specific Ideas and Constraints

- Quick-add curated set is exactly: **Instagram, TikTok, X (formerly Twitter), YouTube, Reddit**. App display names should match each platform's current branding (e.g., "X" not "Twitter").
- Streak day boundary: **04:00 local time** (so "I avoided TikTok last night" rolls into yesterday's day). This affects schedule cross-midnight handling AND Phase 5 streak-rollover logic.
- The health-check banner copy is: `"Tracking is offline — tap to fix"`. Single line. No emoji. No exclamation.
- The dontkillmyapp.com vendor list to recognize via `Build.MANUFACTURER` (Phase 1 PITFALLS research): Xiaomi, Huawei, Samsung, Oppo, Vivo, OnePlus. If `Build.MANUFACTURER` matches one of these (case-insensitive), the OEM-specific reactive guidance shows the per-vendor link.

</specifics>

<deferred>
## Deferred Ideas (captured during discussion, NOT in v1)

- **Multiple schedule windows per entry** — out of scope for v1; one optional window only.
- **Schedule presets** ("Work hours", "Bedtime", etc.) — out of scope for v1; user enters time and weekday mask manually.
- **Long-press multi-select for batch delete** — out of scope; v1 deletes one at a time from the edit page.
- **Per-entry custom cooldown durations beyond 1/3/5/10** — already in REQUIREMENTS.md DIFF-03 as v1.x deferred.
- **Streak history calendar heatmap** — already in REQUIREMENTS.md DIFF-02 as v1.x deferred.
- **Time-of-day "danger zones" breakdown** — already in REQUIREMENTS.md DIFF-05 as v1.x deferred.
- **Disk-cached app icons** — out of scope for v1; in-memory LRU is sufficient.
- **Fuzzy search in app picker** — out of scope; substring match is sufficient.
- **Multiple languages / localization** — Phase 2 ships English-only; localization is a future milestone.

</deferred>

---

*Phase: 02-list-crud-onboarding-permissions*
*Context gathered: 2026-05-05 via /gsd-discuss-phase 2 (3 areas selected; mid-discussion v1 scope expansion approved)*
*Next step: /gsd-plan-phase 2 in a fresh session*
