# Not To-Do List

## What This Is

A mindfulness-based Android app that helps adults stick to user-defined avoidance goals — apps and habits they explicitly want to NOT do. Combines a "Not-To-Do List" with screen-time tracking and a soft-block-with-timer pause screen ("Do you really need it now?") that interrupts the impulse moment without forcing a hard block. v1 ships as a standalone, on-device, account-free Android app for self-disciplined adults.

## Core Value

When a user opens an app on their not-to-do list, the pause screen + cooldown timer creates a deliberate moment of reflection that helps them choose deliberately — and the streak counter rewards every day they succeed.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- v1 scope. All hypotheses until shipped and validated. -->

- [ ] User can build a not-to-do list of **apps** to avoid, each with a reason/motivation note
- [ ] User can build a not-to-do list of **habits** to avoid (self-report only — no system blocking)
- [ ] App intercepts launches of blocked apps with a "Do you really need it now?" pause screen
- [ ] User can pick a cooldown timer (1 / 3 / 5 / 10 min) on the pause screen; app auto-closes when the timer ends
- [ ] App tracks per-app screen time using Android `UsageStatsManager`
- [ ] User sees daily / weekly / monthly screen-time dashboard, with not-to-do app time highlighted
- [ ] Streak auto-breaks if usage on a blocked app exceeds a threshold; user also self-reports daily
- [ ] User does a daily check-in ("Did you avoid X today?") — combined with system detection for honest streaks
- [ ] User receives a daily reminder push notification at a user-chosen time
- [ ] All data stays on-device — no account, no backend, no telemetry

### Out of Scope

<!-- Explicit boundaries with reasoning to prevent re-adding. -->

- **Account / sign-up** — v1 is local-only; deferred to Milestone 2 with sync
- **Backend (Supabase)** — not needed without sync; deferred to Milestone 2
- **iOS port** — avoids Apple $99/yr Developer cost and Family Controls entitlement complexity; deferred to Milestone 2
- **Website blocking** — requires built-in browser, VPN-DNS filter, or fragile per-browser hooks; +2–4 weeks and invasive perms; deferred
- **Content-type filtering (18+, gambling, violence)** — needs paid categorization API (e.g., CleanBrowsing) or weak self-hosted blocklists; conflicts with free/OSS budget; deferred to Milestone 2
- **Kid Mode** — depends on content filter + parental PIN; deferred to Milestone 2
- **Parental dashboard / remote control / email reports** — needs multi-device + backend; deferred to Milestone 3
- **Premium / subscription / IAP** — v1 is free for validation; monetization deferred
- **Social features, leaderboards, streak sharing** — explicitly excluded as an anti-feature; solo focus is part of the wedge
- **Gamification (points, badges, coins, levels)** — explicitly excluded; the streak is the only reinforcement
- **AI / LLM coaching chatbot** — explicitly excluded; we are not building an accountability chatbot
- **Whitelisting / "allowed" lists / positive habit tracking** — explicitly excluded; product is purely about avoidance, not goal tracking

## Context

**The wedge.** The differentiator vs Apple Screen Time / Bark / Qustodio is that **the user defines their own avoidance goals** — not a generic block list. The "Not-To-Do" framing makes this an opt-in mindfulness tool, not a punitive parental control. v1 is positioned for self-disciplined adults; Kid Mode + parental dashboard are deliberate later milestones.

**Build context.** Solo developer, full-time, targeting v1 in 6–12 weeks. Habit-formation product — success means daily use and streak retention.

**Privacy stance.** Screen-time data is sensitive. v1 keeps everything on-device — no backend, no telemetry, no cloud sync. This is both a UX choice (zero sign-up friction) and a trust stance (we never see your data).

**Tech ecosystem (Android).** `UsageStatsManager` + `AccessibilityService` are the load-bearing APIs. `UsageStatsManager` requires the special `PACKAGE_USAGE_STATS` permission (granted by the user via Settings, not a runtime prompt). Accessibility Service is required to intercept app launches and show the pause overlay. Both are scrutinized by Google Play; permission-justification copy will matter at review time.

## Constraints

- **Tech stack**: Flutter (Dart) UI + native Android channels for `UsageStatsManager` and `AccessibilityService` — Flutter chosen so the eventual iOS port can reuse the UI layer.
- **Platform**: Android-only for v1 — iOS deferred to skip Apple Developer cost ($99/yr) and Family Controls entitlement complexity.
- **Backend**: None in v1 — fully local-first to ship lean and validate the wedge before adding sync.
- **Budget**: Free / OSS only — no paid APIs, no Apple costs, no managed services. Excludes content-categorization APIs entirely from v1.
- **Timeline**: 6–12 weeks to v1, solo full-time — forces ruthless scope discipline.
- **Privacy**: 100% on-device data residency in v1 — non-negotiable trust commitment.
- **Permissions**: `PACKAGE_USAGE_STATS` + Accessibility Service — justification copy must be transparent enough to pass Play Store review.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Android-only for v1 | Avoid Apple $99/yr + Family Controls entitlement; ship faster | — Pending |
| Flutter (over RN / native dual codebase) | Reusable UI layer for future iOS port; native channels for platform APIs | — Pending |
| No backend in v1 (local-only) | Privacy + zero sign-up friction; aligns with free/OSS budget | — Pending |
| Apps + Habits categories only | Sites need built-in browser / VPN; content filter needs paid API; defer | — Pending |
| Soft-block + cooldown timer (not hard block) | "Do you really need it now?" is the magic moment; hard block is anti-mindfulness | — Pending |
| System-detected + self-reported streak | Self-report alone isn't trustworthy; combined gives honest streaks | — Pending |
| Daily reminder push notification at user-chosen time | Habit formation needs gentle nudges; user picks time so it isn't intrusive | — Pending |
| Free v1 (no monetization) | Validate the wedge before building paywall infrastructure | — Pending |

## Success Metric (v1, 90 days post-launch)

**100+ active users with a sustained 7-day streak.** This proves both that the app retains daily usage AND that the Not-To-Do wedge actually works (people are succeeding at avoidance). If we can't hit this within 90 days, the wedge needs rethinking.

## Long-Term Roadmap

Captured for context — *not* v1 scope:

- **Milestone 2**: Kid Mode + 18+ content filter + parental PIN + iOS port + optional Supabase account/sync
- **Milestone 3**: Parent dashboard + remote control + weekly email reports
- **Milestone 4**: Premium subscription (advanced stats, family plan); reconsider gamification only if validation data demands it

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state (users, feedback, metrics)

---
*Last updated: 2026-04-27 after initialization*
