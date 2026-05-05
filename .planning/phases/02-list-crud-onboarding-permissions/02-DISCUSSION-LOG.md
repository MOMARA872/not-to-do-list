# Phase 2 Discussion Log

**Discussion held:** 2026-05-05
**Mode:** discuss (default; interactive 4-question rounds)
**Areas selected by user:** Onboarding shape, App picker UX, List + entry editor UX (Health-check banner UX deselected — left to Claude's discretion).

This document records the discussion for human reference only — it is NOT consumed by downstream agents (researcher, planner, executor). They read `02-CONTEXT.md`.

---

## Area 1 — Onboarding shape

### Round 1 — flow shape, skip behavior, asset strategy, resume

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| How does a fresh-install user reach the empty home? | Welcome → Quick-add → Permissions / Permissions first / Drip / Full carousel | **Welcome → Quick-add → Permissions** | "User tastes the product before granting perms"; POST_NOTIFICATIONS is excluded from the install-time funnel (locked earlier as earned-after-first-add). |
| If a user wants to skip a permission step, what happens? | 1-tap skip + footer / Soft-block re-ask / Hard-block on critical | **1-tap skip + footer note** | Respects autonomy; matches REL-02 health-check banner. |
| Permission rationale screen guidance source? | Static screenshots / Animated GIFs / Live arrow overlay / Text-only | **Static screenshots** | Cheap, version-stable enough; smaller APK than GIFs. |
| If onboarding is interrupted, what happens on next launch? | Resume / Restart / Skip to home + banner | **Resume where they left off** | Persisted progress; doesn't make user retread. |

User answered: "More questions" → moved to Round 2.

### Round 2 — welcome richness, quick-add defaults, skip UX detail, persistence mechanism

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| Welcome screen — how rich? | One headline + CTA / Headline + 2-3 lines / Skip welcome | **One headline + one CTA** | Single screen — fast to skim, hard to misread. |
| First-run quick-add of common offenders — default state? | All unchecked / Top 3 pre-checked / All pre-checked | **All unchecked** | Mindful avoidance frame; user opts in. |
| When user taps Skip on a permission step? | 1-tap + footer / Are-you-sure dialog / Inline expansion | **1-tap skip + footer note** | Same answer as Round 1 question 2 — confirmed. |
| Where is onboarding progress persisted? | shared_preferences / Drift table / Don't persist (recompute) | **shared_preferences** | Single key `onboarding_step` (int 0–3); shared_preferences already in pubspec. |

User answered: "More questions" → moved to Round 3.

### Round 3 — POST_NOTIFICATIONS timing, quick-add presentation, OEM timing, health-banner severity

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| When does POST_NOTIFICATIONS dialog actually fire? | After install-funnel / Right after quick-add / Lazy on reminder set | **After install-time funnel completes** | Cleanest — no mid-funnel system dialog interruption. |
| How is the quick-add picker presented? | Full-screen with icons / Bottom sheet / Inline on welcome | **Full-screen with app icons** | Dedicated screen, 5 cards with logos + checkboxes. Feels intentional. |
| When does OEM-specific guidance appear? | Reactive (on failure) / Proactive (Build.MANUFACTURER detect) / Hybrid | **Reactive — only if standard intent fails** | Keeps non-OEM users in fast path. |
| Health-check banner severity (post-onboarding revoke)? | Subdued amber / Loud red / Modal dialog | **Subdued informational + tap-to-fix** | Soft amber bar; non-modal; doesn't fight the mindful tone. |

User answered: "Next area" → moved to Area 2.

---

## Area 2 — App picker UX

### Round 1 — layout, system apps, already-blocked, reason note

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| When user taps Add app, what do they see? | Search-first + recent + alpha / Pure alpha / Categorized / System picker | **Search-first + recent + alphabetical** | Best discoverability; uses UsageStatsManager for "Recently used" section. |
| Hide system apps from the picker? | Hide non-launchable / Show everything / Hide + Show-all toggle | **Hide system + 'Show all' toggle** | Power-user escape hatch. |
| Already-blocked apps in picker? | Hide / Show disabled / Tap = jump to detail | **Show them disabled (greyed + 'already added')** | Visible but unselectable; user sees the full picture. |
| Reason note — required or optional? | Optional, no hard limit / Required 200-char / Required no limit | **Optional, no hard limit** | Char limit 500 (soft). Empty entries get a generic fallback on the pause screen. |

User answered: "More questions" → moved to Round 2.

### Round 2 — habit entry, search match, icon cost, after-save

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| How does the user add a Habit? | Two FABs / One FAB + type modal / Tab bar in picker | **Two FABs/buttons on home** | Each entry type has its own optimized flow. |
| Search bar matches what? | Display name only / Name + package / Fuzzy | **Display name only, case-insensitive** | Closest to user's mental model. |
| App icon caching strategy? | On-demand LRU / Cache to disk / No cache | **Fetch on demand, in-memory LRU cache (50)** | No persistent storage. |
| After save, where does user land? | Return to home / Stay in picker / Show new entry detail | **Return to home** | Clear feedback that the action completed. |

User answered: "Next area" → moved to Area 3.

---

## Area 3 — List + entry editor UX

### Round 1 — row layout, app vs habit distinction, edit gesture, delete UX

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| List item layout? | Compact row / Spacious card / Row with expand-on-tap | **Compact row (~64 dp)** | Density-first; ~8–10 items per screen. |
| App vs Habit visual distinction? | Icon source only / Subtle badge / Sectioned | **Icon source only** | Apps show app icon; Habits show generic icon. |
| Edit gesture? | Tap row → detail page / Tap → inline expand / Long-press menu | **Tap row → detail/edit page** | Standard. |
| Delete UX? | Swipe-left + confirm / Edit page button only / Long-press multi-select | **Delete button on edit page only** | User chose safety over speed. |

User answered: "More questions" → mid-question, **changed direction**: requested expanding v1 scope to include hard-block / website blocking / 18+ filter / kid mode / parent PIN / scheduled blocking / browsing data privacy — "the product goal changed."

### Mid-Area-3 — Project-level scope decision

Claude pushed back: most of what user proposed conflicts with locked PROJECT.md decisions (anti-features or M2-deferred). Surfaced four paths: (A) Pivot v1, (B) Keep v1 lean, (C) Hybrid (1–2 features), (D) Brainstorm — keep current course.

| Question | Selection | Notes |
|---|---|---|
| What do you actually want to do? | **Hybrid — add 1–2 things to v1, defer rest** | User clarified: "v1 should become a stronger adult self-control app blocker, not a full kid/parent-control app yet." |

Claude then offered a tradeoff-weighted shortlist (A: hard-block opt-in, B: schedules, C: Parent PIN, D-F: website/content filter / 18+).

**User selected: A + B. Explicitly NOT C (Parent PIN). Reason given:**

> "v1 should become a stronger adult self-control app blocker, not a full kid/parent-control app yet. Hard-block + schedules are core blocker features. Parent PIN belongs in M2/M3 with kid mode, content filtering, and stronger policy review."

This was saved as a project-level memory (`project_not_to_do_list_v1_position.md`) so future sessions carry the intent forward.

### Project doc updates (committed before resuming Phase 2 discussion)

User requested literal diffs before applying. Diffs presented for `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`. User verified against guard rails (adult-only, per-entry opt-ins, parental controls deferred, REQ-IDs clean) and approved.

Applied + committed as `7119f85`:
- PROJECT.md: 2 new Active reqs; 4 new Out-of-Scope items; 3 new Key Decisions; "What This Is" rewritten; Context paragraph updated.
- REQUIREMENTS.md: 5 new REQ-IDs (LIST-08, LIST-09, PAUS-09, PAUS-10, STRK-09); 4 new Out-of-Scope rows; traceability + coverage updated (63 → 68).
- ROADMAP.md: Phase 2/4/5 requirement lists extended; Phase 2/4/5 success criteria #1/#2/#1 extended.

### Round 2 of Area 3 — block_mode + schedule editor UX

| Question | Options presented | Selection | Notes |
|---|---|---|---|
| Block-mode toggle (LIST-08) — where in editor? | Segmented control / Hidden under Advanced / Long-press home row | **Segmented control: Soft / Hard** | Inline subtitle explains each. Visible by default. |
| Schedule editor (LIST-09) — how complex? | Time + weekday chips / Multiple windows / Presets + custom | **Time range + weekday chips** | User added explicit constraint: "For v1, each entry supports only ONE optional active window. Do not add multiple windows or presets in v1." Captured in `<deferred>` of CONTEXT. |
| Cross-midnight (e.g., 22:00–06:00)? | One continuous window / Forbid cross-midnight / Two separate ranges | **Treat as one continuous window** | Internally split; streak day boundary uses 04:00 local time. |
| Hard-block + schedule combinable? | Yes independent / Mutually exclusive / Hard implies always-on | **Yes, independent toggles** | Outside window = dormant; inside window = intercept (and if hard, no "Use anyway"). |

User answered: "Ready for context" with explicit instructions to carry forward the new v1 scope (adult self-control only; per-item opt-ins; no parent PIN/kid mode/website blocking/18+ filtering/anti-uninstall/parental controls in v1). Captured verbatim in CONTEXT `<v1_scope_carryforward>` section.

---

## Areas not selected by user

- **Health-check banner UX** — user did not select this. Claude's discretion captured in CONTEXT `<decisions>` "Health-check banner (REL-02 / REL-03)" subsection with default plan + checkpoint trigger if planning surfaces conflicts.

---

## Summary of decisions captured

- **Onboarding:** 9 decisions (shape, welcome, quick-add, skip, assets, OEM timing, POST_NOTIFICATIONS placement, persistence, banner severity)
- **App picker:** 8 decisions (layout, system filter, already-blocked, search match, icon cache, after-save, habit entry path, reason note)
- **List + editor:** 5 decisions (row layout, App vs Habit distinction, edit gesture, delete UX, sort order)
- **Block-mode + schedule (added mid-discussion):** 4 decisions (toggle placement, schedule UI shape, cross-midnight handling, hard+schedule combination)
- **v1 scope carry-forward:** explicit user statement reproduced verbatim in CONTEXT — "adult self-control only; no parental controls in v1"

**Total:** 26 implementation decisions + 1 project-level scope expansion (committed as `7119f85` before continuing).

---

*End of discussion log. Next step: `/gsd-plan-phase 2` in a fresh session.*
