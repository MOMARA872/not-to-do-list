# Phase 3: Screen-Time Dashboard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 03-screen-time-dashboard
**Mode:** `--auto` (executed under runtime auto-mode directive — Claude auto-selected the recommended option for every gray area; no AskUserQuestion calls were made)
**Areas discussed:** Pigeon channel impl shape, Dashboard navigation, Highlight treatment, Avoided-today definition, Cumulative totals, Today-cache freshness, No-permission fallback, Aggregation worker, Chart vs list rendering, Home-card placement

---

## Pigeon channel + Kotlin impl shape

| Option | Description | Selected |
|--------|-------------|----------|
| Light up existing `usage_api.dart` Pigeon stub | Reuse Phase 1 scaffolding; add `UsageApiImpl.kt` mirroring `AppPickerHostImpl.kt`; background `Executor`; `INTERVAL_DAILY` | ✓ (recommended) |
| Hand-rolled MethodChannel | Bypass Pigeon; raw types | |
| `app_usage` plugin only (no native code) | Drop the Pigeon channel entirely | |

**Auto-selected:** Light up existing Pigeon stub.
**Rationale:** Phase 3's stated goal in ROADMAP.md (line 318) is "validates the Pigeon channel pattern on a low-risk surface before the blocker depends on it." Plugin-only would skip the validation; hand-rolled MethodChannel would skip Pigeon's compile-time type safety (research/ARCHITECTURE.md Pattern 2). The stub is already wired; lighting it up is the minimum-change path that satisfies the phase goal.

---

## Dashboard navigation shape (Day / Week / Month)

| Option | Description | Selected |
|--------|-------------|----------|
| Segmented control at top | Material 3 `SegmentedButton`, 3 segments; reuses Phase 2 BlockModeSegmented widget pattern | ✓ (recommended) |
| Scrollable cards (Today + This Week + This Month stacked) | One scrollable view, no nav | |
| Hamburger / dropdown picker | Single tap selector | |
| Bottom tab bar | New global navigation primitive | |

**Auto-selected:** Segmented control at top.
**Rationale:** 3-state nav is the canonical use-case for `SegmentedButton`. Reuses the exact pattern Phase 2 settled on for `block_mode_segmented.dart`. Avoids inventing a new navigation primitive (bottom tabs) for a single screen — out of proportion. Scrollable cards bury the M tab below the fold, which conflicts with DASH-03/04's first-class status.

---

## "Highlighted" treatment for not-to-do entries

| Option | Description | Selected |
|--------|-------------|----------|
| Visual: 4dp left accent border + 100% icon opacity for not-to-do; 60% opacity for others; primary color bar-fill | Single visual delta drives all surfaces | ✓ (recommended) |
| Pinned section: "Your not-to-do list" banded section above the rest | Banded header pattern | |
| Badge / dot indicator on rows | Tag-style indicator | |
| Color-coded chart only (no row-level differentiation) | Visual only in the chart, list is uniform | |

**Auto-selected:** Visual treatment (border + opacity + tinted bar).
**Rationale:** DASH-02 mandates "visually highlighted" — a single color/opacity delta hits the spec without inventing structural sections (which would conflict with the unified-list pattern Phase 2 locked: 02-CONTEXT.md "App vs Habit visual distinction: Icon source only. NO badges, NO tags, NO sectioned grouping. The unified list stays unified."). Carrying the same philosophy to the dashboard is the consistent call.

---

## "Avoided today" definition (DASH-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Threshold-based per-entry success: today's foreground_seconds ≤ streakBreakThresholdMinutes × 60 | Mirrors STRK-02's threshold model that Phase 5 will use; single source of truth | ✓ (recommended) |
| Pause-event-based: count entries where any pause event recorded "cooldown-completed" today | Requires Phase 4 data; 0 in Phase 3 | |
| Self-report only: count Habits with `avoided=true` check-in today | Excludes Apps entirely | |
| Composite: success = (threshold AND check-in) for hybrid honesty | Hybrid; complex — Phase 5 territory | |

**Auto-selected:** Threshold-based for Apps, check-in-based for Habits.
**Rationale:** Apps don't have check-ins in Phase 3; habits don't have system tracking. The split-by-kind rule is the only one that works for both today AND aligns with Phase 5's STRK-02 threshold model — same SQL constant, no double-source-of-truth. Hybrid composite is Phase 5's job (STRK-04 system-confirmed vs self-reported labelling).

---

## Cumulative totals (DASH-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Derived on read from `pause_events` aggregate (COUNT + SUM(cooldown_chosen_seconds)) | No schema change; phase 3 reads, phase 4 writes | ✓ (recommended) |
| Denormalized counter columns on `block_list` | Pre-computed, write-time bookkeeping | |
| Materialized view via Drift query | Cached aggregate | |
| Rolling 30-day window only | Bounded growth | |

**Auto-selected:** Derived on read.
**Rationale:** Phase 3 is read-only on `pause_events` — Phase 4 is the writer. Derived-on-read avoids any cross-phase write coordination and keeps Phase 3's footprint surgical. Single COUNT/SUM is sub-millisecond on the cardinality v1 will see (PITFALLS.md §6 explicitly notes the bottleneck is monthly-view aggregation, not pause_events). Rolling 30-day misleadingly under-reports the cumulative win the user is investing toward.

---

## Today's data freshness + refresh trigger

| Option | Description | Selected |
|--------|-------------|----------|
| 5-min soft-cache for today; immutable past; refresh on mount + on resumed + on pull-to-refresh | Research-locked staleness window | ✓ (recommended) |
| Live tail via foreground service polling every 60s | Continuous foreground service | |
| Refresh on every dashboard open, no caching | Always-live | |
| 1-min cache (more aggressive) | Tighter freshness | |
| 15-min cache (less aggressive) | Lower fetch frequency | |

**Auto-selected:** 5-min soft-cache + lifecycle triggers.
**Rationale:** Locked by research (ARCHITECTURE.md Pattern 3 lines 209–224, SUMMARY.md L88). `app_usage` lag is ~1–2 min so 5 min covers double-the-lag cleanly. Foreground service polling is research-anti-pattern #3 (push to Restricted bucket; battery drain). Refresh-on-every-open burns the queryUsageStats cost on rapid back/forth navigation. 1-min cache shaves 4 minutes off staleness for negligible perceived benefit; 15-min cache fails the "today is alive" test users will run.

---

## No-permission fallback (Usage Access revoked)

| Option | Description | Selected |
|--------|-------------|----------|
| Last-cached snapshot + sticky "Tracking is offline — tap to fix" banner; banner routes to `/onboarding/permissions/usage-access` | Reuses Phase 2 health-banner copy + routing | ✓ (recommended) |
| Empty error screen with re-grant CTA | Hides any data; harshest UX | |
| Hide dashboard tab entirely until granted | Silent removal | |
| Skeleton loader forever | Indefinite limbo | |

**Auto-selected:** Last-cached + sticky banner.
**Rationale:** Reuses the byte-for-byte literal copy `"Tracking is offline — tap to fix"` already locked by `play_invariants_test.dart`. Matches REL-02's "self-healing health check" framing — the dashboard is the most visible surface for that check. Hiding the tab erases the user's only path back to fixing the permission state. Forever-skeleton conflates "no permission" with "loading," which is a UX lie.

---

## Aggregation worker shape

| Option | Description | Selected |
|--------|-------------|----------|
| Lazy on dashboard open + on `AppLifecycleState.resumed`; idempotent upsert via Drift | No background worker; simulator-friendly | ✓ (recommended) |
| WorkManager periodic (every 15 min) | Fires even when app is closed | |
| Foreground service (continuous) | Real-time | |
| `BroadcastReceiver` on screen-on event | Event-driven | |

**Auto-selected:** Lazy on open + on resumed.
**Rationale:** WorkManager and FGS-based aggregation push Phase 3 from "simulator-friendly" (research/SUMMARY.md L108 "low-risk first integration") into Phase-4-territory complexity (real-device overnight gate, Doze testing, App Standby Bucket pressure). Lazy-on-open works because Phase 3 is purely a viewing surface — there's nothing to aggregate when the app is closed (the data is in `UsageStatsManager` server-side; we just haven't *queried* it yet). WorkManager is correctly deferred to Phase 5 where STRK-05 + NOTF-04/05 already need it.

---

## Chart vs list rendering

| Option | Description | Selected |
|--------|-------------|----------|
| Flat sortable list with horizontal bar-fill row (no chart lib dep) | Pure-widget; <300ms easy; accessible | ✓ (recommended) |
| `fl_chart` bar chart | Adds chart-lib dep | |
| `syncfusion_flutter_charts` | Adds heavyweight commercial-flavor lib | |
| Bare list with duration text only (no visualization) | No bar fill | |
| Stacked bar chart | Per-day breakdown stacked | |

**Auto-selected:** Bar-fill list rows.
**Rationale:** Free/OSS budget rules out paid chart libs; pure-widget `LinearProgressIndicator` does the job. Accessibility wins (screen readers read the duration; bar is decorative). Render budget (DASH-07: <300 ms) is trivially met without chart-lib widget construction overhead. Matches Digital Wellbeing's familiar pattern, which is the user's existing mental model. Bare list (no bar) loses the at-a-glance comparison the dashboard exists to provide.

---

## Home-card placement (DASH-05 + DASH-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Two cards stacked above the unified list, between HealthCheckBanner and entries ListView; tap → `/dashboard` | Above-the-fold home identity | ✓ (recommended) |
| Single combined card | One card, two sections | |
| In a separate "Stats" tab | Tab-bar navigation primitive | |
| Pinned at bottom of home | Below the entries list | |
| Sliver/parallax header | Animated collapse | |

**Auto-selected:** Two stacked cards above the list.
**Rationale:** DASH-05 + DASH-06 are spec'd as separate cards ("Avoided today" + "Cumulative totals"); combining them blurs the at-a-glance contract. Above the list is the natural visual hierarchy — banner > summary cards > the actual entries. Tabs add a navigation primitive Phase 2 didn't introduce; introducing one in Phase 3 is scope creep. Bottom-pinning makes them invisible on a list of 10+ entries.

---

## Claude's Discretion

The following decisions were left to Claude (or to downstream research/planner agents) per `--auto` mode + the `<decisions>` "Claude's Discretion" subsection in 03-CONTEXT.md:

- **Drift v3 migration?** No — `daily_usage_summary` table already exists (Phase 1). Phase 3 doesn't bump `schemaVersion`. Optional `CREATE INDEX` on `(packageName, day)` is delegated to the planner.
- **Test strategy:** mirror Phase 2's wave-pattern — Wave 0 stubs, Wave 1+ fills. Specific test files to scaffold are the planner's call.
- **Empty-state copy** (Day/Week/Month with no data, no apps used yet, etc.): refined during planning.
- **Exact perf-test harness shape** (`test/perf/dashboard_render_test.dart` API choice between `tester.pumpFrames`, `tester.binding.framePolicy`, or `LeakTesting.settings`): Claude's discretion during execution; assertion target is fixed at <300 ms first frame on the seeded 30-day × 20-app fixture.
- **`/dashboard` icon / FAB / app-bar action vs card-tap-only entry:** the home cards are spec'd as the entry path; whether to also add an app-bar `IconButton` (e.g., `Icons.bar_chart_outlined`) is a planner call.

## Deferred Ideas

(See `<deferred>` in 03-CONTEXT.md for the full list.) Highlights:

- Per-app drill-down screen — DIFF-05 v1.x deferred
- Time-of-day "danger zones" breakdown — DIFF-05 v1.x deferred
- Calendar heatmap — DIFF-02 v1.x deferred
- Home-screen widget for "avoided today" — DIFF-04 v1.x deferred
- Week-over-week / month-over-month comparison — out of v1
- Chart libraries (`fl_chart`, etc.) — out of v1; pure-widget bar-fill is the call
- WorkManager periodic aggregation — Phase 5
- Background isolate aggregation — research-anti-pattern #3
- Data export of usage rows — Phase 6 (SETT-01)
- Real-device overnight survival as Phase 3 exit gate — Phase 4 owns REL-04
- Localization (non-English copy) — future milestone
- Disk-cached app icons — Phase 2 already deferred; Phase 3 inherits in-memory LRU

---

*Generated 2026-05-07 by /gsd-discuss-phase 3 (--auto mode under runtime auto-mode directive)*
