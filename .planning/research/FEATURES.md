# Feature Research

**Domain:** Habit-avoidance / mindful-blocking / screen-time app (Android, adult self-discipline)
**Researched:** 2026-04-26
**Confidence:** MEDIUM-HIGH (competitor features verified across multiple sources; some implementation-cost estimates are LOW-confidence projections)

## Scope Reminders

This research is bounded by PROJECT.md:
- **Categories in v1:** Apps + Habits only (no sites, no content-types)
- **Locked anti-features:** social/leaderboards, gamification (points/badges/coins/levels), AI/LLM coaching, whitelisting/positive-habit tracking
- **Stack:** Flutter + Android-native channels (`UsageStatsManager`, `AccessibilityService`)
- **Privacy:** 100% on-device, no backend, no telemetry

Features below are categorized as Table Stakes / Differentiator / Anti-feature against this wedge — not a generic "habit app." A feature that's table-stakes for Habitica (gamification) is an anti-feature here, and that's intentional.

---

## Feature Landscape

### Table Stakes (Users Expect These)

If any of these is missing, users will write 1-star reviews and uninstall. They are the *price of admission* in the screen-time / app-blocker category on Android.

#### Avoidance List Management

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Add/remove apps from a not-to-do list (multi-select from installed apps) | Every blocker (ScreenZen, AppBlock, Stay Focused, Opal) has this; without it, the product literally can't be configured | S | Use Android `PackageManager` to enumerate launchable apps. Filter system apps by default; offer "show system apps" toggle. |
| Add/remove user-typed habits (free-text label) | Bad-habit trackers (HabitBull, Way of Life) all support arbitrary user-typed entries | S | Just a string + optional reason note. No system integration. |
| Per-item reason / motivation note | "Why am I avoiding this?" surfacing on the pause screen is a known intervention pattern (one sec, ScreenZen) | S | Plain text, optional. Stored on the not-to-do entry. Surfaced on pause screen. |
| Edit / delete entries | Basic CRUD expectation | S | Confirmation dialog on delete to prevent accidental loss of streak. |
| Search/filter when picking apps to add | Users typically have 100+ installed apps; without search, picking is painful | S | Simple substring filter on app label. |

#### Pause Screen UX (the wedge moment)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Intercept launch of a blocked app and show full-screen pause overlay | Core mechanic of every soft-blocker (one sec, ScreenZen, Opal) — without it, "soft block" doesn't exist | L | Requires Accessibility Service listening for `TYPE_WINDOW_STATE_CHANGED` events; needs `SYSTEM_ALERT_WINDOW` (overlay) permission. Latency between detection and overlay must be <500ms or the user gets into the app first. |
| "Do you really need it now?" prompt copy + reason note | The reflective question is the entire point; one sec built a $M product on this single mechanic | S | Static UI; reason note pulled from list entry. |
| Cooldown timer (1/3/5/10 min) before user can proceed | Every modern soft-blocker has timed gating; ScreenZen makes wait times configurable, one sec uses fixed delays | M | Foreground service or timer + locked overlay. Must survive app backgrounding (user will try). |
| Auto-close blocked app when timer ends | Implied by "cooldown timer" — without it, the timer is just decorative | M | Use `Activity.finishAffinity()` via Accessibility Service `performGlobalAction(GLOBAL_ACTION_BACK/HOME)`. |
| "Continue anyway" / "Cancel" choice after pause | Soft-block ≠ hard-block; user must retain agency or it's not a mindfulness tool | S | Two buttons. The choice itself is recorded for streak logic. |

#### Screen Time Tracking & Dashboard

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-app screen time, daily / weekly / monthly | Digital Wellbeing, ActionDash, ScreenZen all show this; without it the app is a glorified blocker | M | Query `UsageStatsManager.queryUsageStats()` with appropriate `INTERVAL_*` flag. Cache in local DB to avoid repeated expensive queries. |
| Highlighted "not-to-do" usage vs other usage | The whole product is about avoidance; users want to see *progress on their list*, not generic dashboards | M | Filter total usage by package names on the not-to-do list. Stacked bar chart works well. |
| Today's usage (live, current day) | Users want immediate feedback ("how am I doing right now?") | M | `UsageStatsManager` data lags 1–2 minutes; users will notice if "today" is stale. Refresh on app foreground. |
| Total time avoided / total launches blocked | Positive reinforcement metric — "you saved 47 minutes this week" — without slipping into gamification | S | Compute from logged pause events. |

#### Streaks

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Per-item streak counter (days in a row succeeded) | The defining feature of every habit/avoidance app; missing it is unthinkable | M | Daily evaluation at midnight (local time). Combine system detection threshold + self-report. |
| Streak break detection | Users will not trust streaks they suspect are wrong | M | Auto-break if usage exceeds per-item threshold; user-configurable threshold per app (default ≈ 5 min). |
| Streak history / longest streak | "What's my best?" is asked for in basically every habit-app review | S | Store streak history; compute longest from records. |
| Daily check-in prompt ("Did you avoid X today?") | Self-report is a behavior-change technique (self-monitoring); also mandatory for habits with no system signal | S | One question per habit per day; combine with system data for hybrid honest streak. |

#### Notifications

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Daily reminder push at user-chosen time | Habit formation literature: cue → routine → reward; user-chosen time avoids alert fatigue | S | `AlarmManager` setExactAndAllowWhileIdle (deal with Doze). Default 8pm; user-configurable. |
| Notification copy mentions specific not-to-do items | "Time to check in on your avoidance goals" is generic; "How did Instagram go today?" is sticky | S | Rotate items in copy; include reason note for personalization. |

#### Onboarding & Permissions

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Permission priming screens for `PACKAGE_USAGE_STATS` and Accessibility | Both perms require Settings deep-link (no runtime prompt). Users abandon if they don't understand why. one sec and ScreenZen both do extensive priming. | M | Show "why we need this" before deep-linking to Settings. Show "verify granted" after return. Handle rejection gracefully. |
| First-run setup flow (pick first 1–3 apps) | Empty-state apps die on day 1; guided setup converts | S | Curated common offenders (Instagram, TikTok, X, YouTube, Reddit) as quick-add. Don't require — let user free-add too. |
| In-app disclosure for accessibility use | Required by Google Play policy for non-accessibility apps using AccessibilityService | S | Static screen explaining what data is accessed, what stays on device. Required for Play review pass. |

#### Settings & Data

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Reset / clear all data | GDPR-adjacent expectation; also demoed in Play review | S | Wipe local DB; preserve permissions. |
| Export data (CSV/JSON) | "It's my data" sentiment is strong in privacy-positioned apps | S | Save to `Documents/` via `ACTION_CREATE_DOCUMENT`. Useful before reinstall. |
| Theme (light/dark/system) | Universal Android expectation in 2026 | S | Flutter `ThemeMode.system` default. |

---

### Differentiators (Competitive Advantage)

These are where the Not-To-Do List wins against ScreenZen, one sec, Opal, Forest, AppBlock, and the rest. **They directly express the wedge: user-defined avoidance goals, mindful soft-block, on-device privacy.**

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **User-defined avoidance list framing** ("My Not-To-Do List") | Differentiates from category-blockers (Bark, Qustodio) and from generic blocklists (Cold Turkey templates). The wedge per PROJECT.md. | S | Pure UX/copy. Implementation cost is in the *naming and IA*, not the code. Make the list a first-class object: `Home → My Not-To-Do List`. |
| **Apps + Habits in one list** (unified avoidance) | Bad-habit trackers (HabitBull, Way of Life) only do habits. Blockers (one sec, ScreenZen) only do apps. Combining the two — "no Instagram + no late-night snacking" — is rare and matches how users actually think about self-discipline. | M | Same data model, two `kind` enum values: `app` (system-tracked) and `habit` (self-report only). Pause screen only fires for `app`. |
| **"Do you really need it now?" reason-aware pause** | one sec uses generic interventions; ScreenZen requires a math problem. Surfacing the user's *own stated reason* ("You said: I want to be more present with my kids") is a stronger nudge than a math problem. | M | Just shows the reason note prominently. Cost is in the design polish, not the engine. |
| **Cooldown timer with explicit options (1/3/5/10)** | one sec is fixed; ScreenZen escalates by use count. Letting the user *pre-commit* to a wait length on the pause screen ("I'll wait 5 min before deciding") is a closer match to commitment-device theory. | S | Already in v1 scope per PROJECT.md. Four buttons; tap starts countdown. |
| **Hybrid streak (system-detected + self-reported)** | Habit trackers rely on self-report (lies easily). Pure system trackers can't track habits like "no smoking." Combining both gives credibility self-report alone can't deliver. Per PROJECT.md key decisions. | M | For app entries: streak survives only if usage < threshold AND user confirms in daily check-in. For habit entries: pure self-report. |
| **Per-app usage threshold (not just any usage breaks streak)** | Realistic. "1 minute on Instagram for 2FA" shouldn't break a streak. ScreenZen has limits but doesn't tie them to streak break. | S | Per-item config: "break streak if > N minutes" with sensible default (e.g., 5 min). |
| **100% on-device, no account, zero sign-up** | Bark/Qustodio require account. Opal claims local but has cloud features. Trust stance + zero-friction onboarding matter for screen-time data. | S | This is an architecture decision, not a feature, but it ships *as a feature* in marketing. |
| **Total launches blocked / total time saved (cumulative)** | Positive feedback without gamification. one sec shows this; ScreenZen does too. Frame as "intervention insights," not a points system. | S | Computed from pause-event log. |
| **"Avoided today" highlighted card on home** | Direct visual answer to "how am I doing on my list right now?" — most apps bury this in a dashboard. | M | Daily summary card at the top of home: items succeeded today, items at risk, items already broken. |
| **Cooldown auto-close (you don't have to press anything)** | Subtle but huge for the impulse-interruption use case. ScreenZen leaves you at a wait screen; one sec doesn't auto-close. | M | Per PROJECT.md scope. Send `GLOBAL_ACTION_HOME` when timer hits zero. |

---

### Anti-Features (Commonly Requested, Often Problematic)

These are things users / advisors will request, and we should explicitly say no. Four are *locked* by PROJECT.md (social, gamification, AI, whitelisting). The rest are anti-features for *this wedge* even though they aren't called out by name in PROJECT.md.

#### The Four Locked Exclusions (per PROJECT.md)

| Feature | Why Requested | Why Problematic for This Wedge | Alternative |
|---------|---------------|--------------------------------|-------------|
| **Social / leaderboards / streak sharing / accountability buddies** | "Social pressure works" is conventional habit-app wisdom; Habitica, Forest's "Plant Together" lean on it. | (1) Adds backend (we have none in v1). (2) Privacy violation for screen-time data. (3) Solo-focus *is the wedge* — this is a quiet self-discipline tool, not a community. (4) Comparison kills mindfulness. | Solo journaling: the reason note + per-item streak history *is* the social layer. The user is accountable to their own past stated reason. |
| **Gamification (points, badges, coins, levels, XP, achievements, virtual pets)** | Habitica, Forest, Finch all use it; users *will* ask. | (1) Forest's tree mechanic = mascot stress, not mindfulness. (2) Points reframe avoidance as a game to win, breaking the reflective frame. (3) Adds 2–4 weeks of art/animation work for solo dev. (4) Locked exclusion in PROJECT.md. | The streak counter is the only reinforcement. "Total time avoided" is informational, not point-scored. No mascot, no levels. |
| **AI / LLM coaching chatbot ("ask why you reach for your phone")** | Hot in 2026; Finch and a wave of new entrants ship LLM coaches. | (1) Requires backend + API costs (excluded by free/OSS budget). (2) Privacy contradicts on-device stance — sending screen-time context to an LLM is a non-starter. (3) The *user's own reason note* is already the reflection prompt. (4) Locked exclusion. | The reason note + pause screen is the reflection. No bot. |
| **Whitelisting / "allowed apps" / positive-habit tracking ("I want to read more")** | Forest's Allow List, Loop Habit Tracker, Habitify all do positive tracking; reviewers will ask "why not just be a normal habit tracker?" | (1) Positive habit tracking is a *crowded* market with no wedge. (2) Adding it triples the data model and IA. (3) Confuses the brand: "Not-To-Do" stops meaning anything if it's also "To-Do." (4) Locked exclusion. | Stay 100% avoidance-only. Brand integrity over feature coverage. |

#### Other Anti-Features for the Not-To-Do Wedge

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Hard block (cannot bypass)** | Cold Turkey, Freedom, AppBlock Strict Mode, ScreenZen Lock Mode — every blocker has it; users *will* ask. | Direct contradiction with the soft-block wedge per PROJECT.md key decision: "hard block is anti-mindfulness." Forces willpower replacement instead of cultivation. | Cooldown timer + auto-close is the strongest interruption we ship. The choice to continue must remain. |
| **Scheduled blocking (work hours, bedtime, weekday/weekend)** | Opal Recurring Schedules, AppBlock profiles, Stay Focused schedules — table stakes for productivity blockers. | Different mental model: scheduled blocking is *task-mode* (focus session), not *avoidance* (a thing I am trying to never do). Mixing them dilutes the wedge. Adds substantial UI complexity. | A not-to-do entry is *always on*. If a user wants Pomodoro, they can use a Pomodoro app. |
| **Per-app daily usage limit (block after N minutes)** | Digital Wellbeing's #1 feature; ScreenZen does it. | Different mental model: limits permit usage up to a threshold; not-to-do says *don't*. The streak threshold already serves this without changing the brand. | Per-item streak threshold (e.g., "more than 5 min breaks streak") gives the same protection without the "limit" framing. |
| **Uninstall protection / device admin / lock-mode** | ScreenZen Lock Mode, AppBlock Strict Mode — common in the category. | (1) Adds device admin permission, which Play Store scrutinizes heavily. (2) Adult self-discipline product — if the user wants to uninstall, they should be able to. Locking them in is anti-mindfulness. | Make uninstall easy. The streak loss is the friction. |
| **App categories / suggested blocklists** | Bark, Qustodio, even Apple Screen Time templates. | Removes the *user-defined* part of the wedge. Suggested lists make it generic again. | First-run flow can suggest individual apps, but the *category framing* should be the user's reason note ("this is a doomscroll thing"), not a system category. |
| **Cloud sync / multi-device** | Inevitable feature request once users have 2 devices. | Excluded by PROJECT.md (no backend in v1). Deferred to Milestone 2. | Local export (CSV/JSON) covers data-portability concern. Sync is M2. |
| **Sites / website blocking (browser, in-app browser, VPN-DNS)** | Bark, Qustodio, Opal, Cold Turkey, Freedom — all do sites. | Excluded by PROJECT.md (Out of Scope). Requires built-in browser or VPN/DNS — both 2–4 weeks and invasive. | Apps + Habits only in v1. Defer. |
| **Content-type filter (18+, gambling, violence)** | Parental-control category expectation. | Excluded by PROJECT.md. Needs paid categorization API; conflicts with free/OSS budget. | Defer to Milestone 2 with Kid Mode. |
| **Parental controls / kid mode / PIN** | Adjacent category — reviewers will compare to Bark. | Excluded by PROJECT.md. v1 is for *adult self-discipline*, not parents. | Different product / different milestone. |
| **In-app purchases / premium tier / subscription** | Industry standard monetization. | PROJECT.md: "Free v1 (no monetization) — validate the wedge before paywall." | Monetization deferred to M4. |
| **Telemetry / crash analytics / Firebase Analytics** | Standard engineering hygiene. | "100% on-device, no telemetry" is a marketing pillar per PROJECT.md. Sending crash data violates the trust stance. | Local crash logs only; user-initiated bug-report export. |
| **Math problems / typing tasks / phone-rotation gestures to bypass** | ScreenZen requires a task; one sec has phone-spin. | More gimmick than mindfulness. The *cooldown timer* is the friction; layering puzzles on top adds complexity for marginal benefit and feels punitive. | Cooldown timer + reason-note display. That's the friction. |
| **Streak freeze / skip days / "vacation mode"** | Habitify, Streaks, Loop allow this. Users will ask. | Erodes the credibility of the streak. One of the core promises is "honest streaks." | Be strict. Missing a day = streak ends. The honesty *is* the value. |
| **Mood tracking / journaling beyond reason note** | Habitify, Finch, mood-tracker apps. | Scope creep into adjacent category. Reason note is enough. | Defer. Reason note covers the "why" without becoming a journal app. |

---

## Feature Dependencies

```
[Permission priming UI]
     └──required-by──> [Accessibility Service]
                            └──required-by──> [App-launch interception]
                                                     └──required-by──> [Pause screen]
                                                                            └──required-by──> [Cooldown timer]
                                                                                                   └──required-by──> [Auto-close on timer end]

[Permission priming UI]
     └──required-by──> [UsageStatsManager access]
                            └──required-by──> [Per-app screen time]
                                                     ├──required-by──> [Daily/weekly/monthly dashboard]
                                                     ├──required-by──> [Hybrid streak (system half)]
                                                     └──required-by──> [Per-item usage threshold]

[Avoidance list CRUD]
     └──required-by──> [Reason note]
                            └──enhances──> [Pause screen]
     └──required-by──> [Per-item streak]
                            └──required-by──> [Daily check-in]
                                                  └──required-by──> [Hybrid streak (self-report half)]
                                                                            └──required-by──> [Streak history / longest]

[Daily reminder notification]
     ──independent──>  (only requires list + chosen time)

[Pause screen] ──conflicts──> [Hard block]   (mutually exclusive philosophies)
[Streak]       ──conflicts──> [Streak freeze / vacation mode]   (erodes honesty promise)
[On-device privacy] ──conflicts──> [Cloud sync, AI chatbot, telemetry, social features]
```

### Dependency Notes

- **Pause screen requires Accessibility Service:** `UsageStatsManager` alone has 1–2 minute lag — too slow to intercept a launch. The Accessibility Service is the only Play-policy-acceptable path for sub-second launch detection.
- **Hybrid streak depends on BOTH usage data AND self-report:** for app entries the system half + self-report half work together; for habit entries (no system signal), only self-report exists. This is why the data model needs a `kind` field early.
- **Reason note enhances pause screen:** the note exists at list-CRUD time but only *pays off* when shown on the pause screen. Build them together.
- **Notification is the simplest feature:** depends only on the list and a user-chosen time. Could ship before pause screen if shipping in slices, but pause screen *is* the wedge — so ship it first.
- **Hard block conflicts with pause screen:** philosophically incompatible. Don't ship a "strict mode" toggle that turns the pause screen into a hard block. That's a different product.

---

## MVP Definition

### Launch With (v1)

These map directly to the PROJECT.md Active Requirements. Nothing added, nothing dropped.

- [ ] **Avoidance list CRUD (apps + habits) with reason note** — the core data model; nothing works without it.
- [ ] **Permission priming + Settings deep-link for `PACKAGE_USAGE_STATS` + Accessibility** — onboarding gate; users can't proceed without these.
- [ ] **App-launch interception via Accessibility Service + full-screen overlay** — the wedge moment; the entire reason this product exists.
- [ ] **"Do you really need it now?" pause screen showing reason note** — the reflective intervention; without the reason, the pause is generic.
- [ ] **Cooldown timer (1/3/5/10) with auto-close** — the friction without hard-blocking; the deliberate pause.
- [ ] **Per-app screen time via `UsageStatsManager` + dashboard with not-to-do highlighted** — the visible feedback loop; users need to see progress.
- [ ] **Per-item streak with hybrid (system threshold + daily self-report check-in)** — the daily reinforcement; the credible streak.
- [ ] **Daily reminder notification at user-chosen time** — the cue; users will forget without it.
- [ ] **Local-only data + reset/export** — the trust stance; also defensible for Play review.
- [ ] **First-run flow with quick-add common offenders** — converts day-1 empty-state to a configured app.

### Add After Validation (v1.x)

Add when v1 has 100+ users with sustained 7-day streaks (per PROJECT.md success metric). Triggers in parens.

- [ ] **Per-item usage threshold UI (currently default-only)** — trigger: users complain about streak breaking on a 1-min 2FA visit. Default is fine; expose the dial when users ask.
- [ ] **Streak history visualization (calendar heatmap)** — trigger: power users want to see their longest streaks visually.
- [ ] **Multiple cooldown timer presets / custom duration** — trigger: 1/3/5/10 doesn't fit a meaningful slice of users; data from logs will tell us.
- [ ] **Notification copy with rotating personalized prompts** — trigger: open rate on default copy drops; A/B copy variants.
- [ ] **Today's avoidance summary widget (home-screen)** — trigger: high engagement on the "avoided today" card → users want it without opening the app.
- [ ] **Per-day breakdown beyond app/habit (time-of-day "danger zones")** — trigger: users ask "when do I fail?"

### Future Consideration (v2+ / later milestones)

Aligned with PROJECT.md long-term roadmap. Defer pre-validation to avoid scope creep.

- [ ] **iOS port** — Milestone 2; depends on Apple Developer account + Family Controls entitlement.
- [ ] **Optional Supabase account / cross-device sync** — Milestone 2; only after the wedge is validated and users explicitly ask.
- [ ] **Kid Mode + content filter + parental PIN** — Milestone 2; different product within same brand; depends on paid categorization API.
- [ ] **Parental dashboard / remote control / weekly email** — Milestone 3; needs backend.
- [ ] **Premium subscription (advanced stats, family plan)** — Milestone 4; only after monetization is needed.
- [ ] **Sites / website blocking** — deferred per PROJECT.md; needs in-app browser or VPN/DNS approach.
- [ ] **Reconsidering gamification** — only if M4 validation data demands it; per PROJECT.md.

---

## Feature Prioritization Matrix

Bounded to v1 scope.

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Avoidance list CRUD (apps + habits + reason) | HIGH | LOW | P1 |
| Permission priming + Settings deep-link | HIGH (gate) | MEDIUM | P1 |
| App-launch interception (Accessibility Service) | HIGH | HIGH | P1 |
| Pause screen with reason note | HIGH | LOW (UI), HIGH (integration) | P1 |
| Cooldown timer + auto-close | HIGH | MEDIUM | P1 |
| `UsageStatsManager` integration + dashboard | HIGH | MEDIUM | P1 |
| Hybrid streak (system + self-report) | HIGH | MEDIUM | P1 |
| Daily reminder notification | MEDIUM (essential for habit formation) | LOW | P1 |
| Daily check-in flow | MEDIUM | LOW | P1 |
| First-run quick-add | MEDIUM | LOW | P1 |
| Local export (CSV/JSON) | LOW (but trust signal) | LOW | P1 |
| Reset all data | LOW (Play review expectation) | LOW | P1 |
| Theme (light/dark) | LOW | LOW | P2 |
| Per-item usage threshold UI | LOW (v1 ships default) | LOW | P2 |
| Streak history visualization | MEDIUM | MEDIUM | P2 |
| Time-of-day usage breakdown | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for v1 launch (matches PROJECT.md Active list).
- P2: Should have, add post-launch when validated.
- P3: Nice to have, future consideration.

---

## Competitor Feature Analysis

Selected the closest competitors to the wedge. Apple Screen Time is iOS-only; included for feature framing.

| Feature | one sec | ScreenZen | Opal | AppBlock | Forest | Habitica | Bark / Qustodio | **Not-To-Do (us)** |
|---------|---------|-----------|------|----------|--------|----------|-----------------|---------------------|
| **Pause-before-open** | Yes (signature) | Yes | Partial (limit-based) | Yes (Cooldown) | No (focus-session model) | No | No (parental block) | **Yes** — soft block + reason-aware |
| **User-defined avoidance list** | Yes | Yes | Yes | Yes | Allow-list (inverse) | Yes (positive) | No (predefined categories) | **Yes — primary framing** |
| **Apps + Habits unified** | No (apps only) | No (apps + sites) | No (apps + sites) | No (apps + sites) | No | Yes (positive) | No | **Yes** |
| **Cooldown / wait timer** | Yes (fixed delay) | Yes (escalating) | Limited | Yes | No (focus session) | No | No | **Yes (1/3/5/10 user choice)** |
| **Hard-block option** | Yes (Strict Block) | Yes (Lock Mode) | Yes (Make it Harder) | Yes (Strict Mode) | No (kills tree) | No | Yes (default) | **No — deliberately** |
| **Streak (avoidance)** | Limited | Yes | Yes (streaks + focus hours) | No | Tree planted (per session) | XP/levels | No | **Yes — hybrid honest** |
| **System usage tracking** | Yes | Yes | Yes | Yes | Limited | No | Yes | **Yes** |
| **Self-report check-in** | No | No | No | No | No | Yes (positive) | No | **Yes (combined w/ system)** |
| **Daily reminder push** | Yes | Yes | Yes | Yes | Yes | Yes | Yes | **Yes — user-time** |
| **Sites / web filtering** | Yes (browser ext) | Yes | Yes | Yes | Limited | No | Yes | **No — out of scope v1** |
| **Content-type filter** | No | No | No | No | No | No | Yes (signature) | **No — out of scope v1** |
| **Local-only / no account** | Mostly | Yes (claims) | Mostly local | Mostly local | Account required | Account required | Account required | **Yes — pillar** |
| **Gamification** | No | No | Some (focus hours) | No | Yes (trees, achievements) | Yes (HP/XP/quests) | No | **No — locked exclusion** |
| **Social features** | No | No | Limited | Limited | Yes (Plant Together) | Yes (parties/quests) | Yes (parent dashboard) | **No — locked exclusion** |
| **AI coaching** | No | No | No | No | No | No | No (yet) | **No — locked exclusion** |
| **Whitelisting / positive habits** | No | No | No (inverse model partly) | No | Yes (Allow List) | Yes (positive) | No | **No — locked exclusion** |
| **Free / no IAP** | Freemium | Free | Freemium | Freemium | $1.99 OR free w/ ads | Freemium | Paid | **Free in v1** |
| **Pricing** | Freemium ~$2-3/mo | Free | $7-10/mo | Freemium | $1.99 once | Freemium | $5-15/mo | **Free** |

**Where the Not-To-Do List is unique:** the *combination* of (a) Apps + Habits unified, (b) reason-aware soft-block pause, (c) hybrid honest streak, (d) zero gamification, (e) zero account / 100% on-device. No single competitor combines all five.

**Where competitors win and we accept the loss:** sites/content-types (Bark, Qustodio, Cold Turkey are stronger), schedules/profiles (AppBlock, Opal), social/family (Habitica, Bark), ecosystem polish (Apple Screen Time).

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Competitor feature lists | HIGH | Verified across multiple sources per app (Play Store, official docs, third-party reviews). |
| Locked anti-features alignment | HIGH | Stated explicitly in PROJECT.md Out-of-Scope. |
| Table-stakes categorization | MEDIUM-HIGH | Cross-checked against 5+ apps in the category; risk that some Android-specific expectation was missed. |
| Implementation complexity (S/M/L) | MEDIUM | Educated estimates based on Android API surface area; no benchmarks run. |
| Notification effectiveness claims | MEDIUM | Backed by behavior-change literature in search results; specific timing optimization is LOW-confidence and should be A/B tested. |
| Accessibility Service latency claim (<500ms) | MEDIUM | General experience from competitor apps; not formally measured for this stack. Worth verifying during prototype. |

---

## Open Questions for Phase-Specific Research Later

- **Accessibility Service latency on `TYPE_WINDOW_STATE_CHANGED`** — what's actually achievable on mid-range Android devices? Affects pause-screen feel.
- **Doze Mode behavior of daily-reminder `AlarmManager`** — exact reliability on Android 14+; may need WorkManager fallback.
- **Play Store review for non-accessibility-purpose AccessibilityService** — empirical pass rate; what's the strongest justification copy?
- **Default streak-break threshold per app** — 5 min is a guess; should be data-driven post-launch.
- **Best timing for daily reminder default** — 8pm is a guess; should be A/B tested against 9am, 6pm, user-bedtime.
- **Quick-add common-offenders list** — should be regionalized? (TikTok in US ≠ KakaoTalk in KR). Defer until international rollout.

---

## Sources

Competitor analysis (verified):
- [ScreenZen Google Play listing](https://play.google.com/store/apps/details?id=com.screenzen) — pause + cooldown + streak features
- [ScreenZen official site](https://screenzen.co/) — feature list
- [Opal — Apps on Google Play](https://play.google.com/store/apps/details?id=com.withopal.opal) — focus sessions + streaks + protection levels
- [Opal Android FAQ](https://opalapp.com/help/introducing-opal-for-android) — Android-specific behavior
- [one sec — official site](https://one-sec.app/) — intentional pause framing, scientific studies
- [one sec — Google Play](https://play.google.com/store/apps/details?id=wtf.riedel.onesec) — interventions and timer
- [Forest — Google Play](https://play.google.com/store/apps/details?id=cc.forestapp) — gamified focus sessions, allow-list
- [Forest official site](https://www.forestapp.cc/) — Plant Together social
- [AppBlock official site](https://appblock.app/) — profiles, Strict Mode, cooldowns, third-party approval
- [Stay Focused official site](https://www.stayfocused.me/) — daily/hourly limits, schedules
- [Cold Turkey vs Freedom comparison](https://giodella.com/freedom-vs-cold-turkey-blocker/) — desktop-focused; Cold Turkey not on Android
- [Android Digital Wellbeing](https://www.android.com/digital-wellbeing/) — Dashboard, App Limits, Focus Mode, Bedtime
- [Digital Wellbeing user guide](https://support.google.com/android/answer/9346420) — feature details
- [Habit tracker comparison — Zapier](https://zapier.com/blog/best-habit-tracker-app/) — Loop, HabitBull, Way of Life, Streaks, Habitify
- [Bad-habit tracking — Daily Habits review](https://www.dailyhabits.xyz/habit-tracker-app/best-habit-tracking-apps-android) — HabitBull, Way of Life, red chains
- [Disciplined habit tracker](https://getdisciplined.app/) — honest streak / no vanity metrics positioning

Android platform / API:
- [UsageStatsManager — Android Developers](https://developer.android.com/reference/android/app/usage/UsageStatsManager) — query semantics, lag behavior
- [Create an accessibility service — Android Developers](https://developer.android.com/guide/topics/ui/accessibility/service) — event types, lifecycle
- [Tapjacking — Android Developers](https://developer.android.com/privacy-and-security/risks/tapjacking) — overlay restrictions on Android 12+
- [Track App Usage in Flutter — Medium](https://medium.com/@naeemahmedpnl/track-app-usage-in-flutter-how-i-fetched-screen-time-for-whatsapp-facebook-others-e237c7205a41) — Flutter + UsageStatsManager pattern

Behavior-change / habit-formation context:
- [Akiflow — daily reminders without notification fatigue](https://akiflow.com/blog/daily-reminder-habits-without-fatigue) — context-based vs time-based reminders
- [Cohorty — habit tracker reminder design 2025](https://www.cohorty.app/blog/best-habit-tracker-apps-with-reminders-smart-notifications-2025) — habit-stacking and natural cues

User-experience / pain points:
- [Roots Help — uninstalled apps still counted](https://intercom.help/roots/en/articles/11130320-why-are-uninstalled-or-excluded-apps-still-being-counted-under-screen-time-and-dopamine-hits) — common complaint pattern
- [Screen Time Labs reviews](https://www.reviews.io/company-reviews/store/screentimelabs.com) — uninstall-protection complaints

---
*Feature research for: Habit-avoidance / mindful-blocking / screen-time app (Android)*
*Researched: 2026-04-26*
