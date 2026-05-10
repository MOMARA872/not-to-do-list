# Phase 4: Pause UX (the wedge) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `04-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 04-pause-ux-the-wedge
**Areas discussed:** Pause-screen feel & layout
**Areas deferred (Claude's discretion within scope):** REL-01 companion foreground service, "Use anyway" timing rule, REL-04 OEM-survival exit gate

---

## Area selection (multi-select from 4 surfaced gray areas)

| Option | Description | Selected |
|--------|-------------|----------|
| Pause-screen feel & layout | Visual identity of the wedge — reason placement, cooldown affordance, button hierarchy, auto-close transition. | ✓ |
| 'Use anyway' timing rule | Soft-block contract: instant-bypass vs after-cooldown-only vs hybrid. | |
| REL-01 companion foreground service | ROADMAP says yes (Active bucket); research says avoid (a11y self-managed). | |
| REL-04 OEM-survival exit gate | Which device, test script, pass criterion for the 500 ms detect-to-pause budget. | |

**User's choice:** `do 1  Pause-screen feel & layout` (free-text annotation)
**Notes:** User explicitly scoped the discussion to the wedge's visual identity. The other three areas remain Claude's discretion within the stated scope guardrails; CONTEXT.md records the discretion bounds (CD-01..03).

---

## Turn 1/4 — Visual mood

| Option | Description | Selected |
|--------|-------------|----------|
| Calm / mindful | Forest-green seed throughout, breathing animation, gentle copy ('Pause and reflect'). | |
| Neutral / utility | M3 default surfaces, dynamic color ON, factual copy, sober checkpoint feel. | |
| Confrontational / stop | Red accent, bold ⚠ WAIT iconography, direct copy. | |
| Show me a hybrid suggestion | Claude proposes a synthesis and the user steers from there. | ✓ |

**User's choice:** Hybrid suggestion.
**Claude's proposed hybrid:** Calm base (Phase-2 forest-green seed, M3 dynamic OFF) + user's reason as hero quote-card + utility-shaped M3 SegmentedButton cooldown chips + asymmetric Cancel-primary / Use-anyway-text-link buttons. No breathing animation (cooldown is the only animation). No app icon, no WAIT banner, no stop-sign iconography.

---

## Turn 1b/4 — Confirm the hybrid

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — lock it | Hybrid is right; move to cooldown countdown affordance. | ✓ |
| Yes, but flip button weight | Equal weight on Cancel and Use anyway (respect autonomy over nudge). | |
| Yes, but kill the reason-hero | Reason as secondary line, not hero (most users won't write one). | |
| No — different direction | Mood / placement / iconography is off. | |

**User's choice:** Lock the hybrid.
**Notes:** The reason-empty case (which Turn 4 addressed) handles the "most users won't write one" concern via a different mechanism (app-name-as-hero fallback) — keeping the reason-hero treatment for the with-reason state preserves the wedge's strength when the user HAS written one.

---

## Turn 2/4 — Cooldown countdown affordance

| Option | Description | Selected |
|--------|-------------|----------|
| Thin bar at top + small digits | LinearProgressIndicator pinned to top, "9:42 remaining" caption below selected chip. Peripheral but reassuring. | ✓ |
| Center progress ring with digits | Circular ring fills the chip area when running. Meditative; competes with reason for attention. | |
| Selected chip transforms in-place | Selected chip's background fills L→R with cooldown color. Most minimal; risks being too quiet. | |
| Big numeric digits, no progress visual | Big falling 9 : 42 digits center-screen. Sports-timer feel; clashes with calm mood. | |

**User's choice:** Thin bar at top + small digits.
**Notes:** Selection preserves the reason-hero hierarchy by keeping the countdown peripheral. Familiar pattern (upload / file-copy dialogs).

---

## Turn 3/4 — Auto-close UX

| Option | Description | Selected |
|--------|-------------|----------|
| Silent finish to launcher | Bar hits 0:00, finish() to launcher. No confirmation, no toast. | |
| Brief '✓ Done' card, then auto-finish | ~1.5 s confirmation card (no judgment, no streak callout), then finish(). | ✓ |
| Tap-to-confirm exit | Cancel button replaced by primary 'OK — I'm done' at 0:00; user must tap. | |
| Auto-finish with small snackbar | finish() called + system snackbar 'Cooldown complete — nice pause.' on launcher. | |

**User's choice:** Brief ✓ Done card, then auto-finish.
**Notes:** Gives micro-closure to the moment without holding the user. Card copy locked as literal `"✓ Cooldown complete"` (no streak / no praise — those slide into Phase 5's gamification-adjacent territory that's explicitly out of scope).

---

## Turn 4/4 — Empty-reason fallback

| Option | Description | Selected |
|--------|-------------|----------|
| 'Pause and reflect.' — same quote card | Phase 2's example placeholder; identical visual to a real reason. Reads as APP talking, not user. | |
| Plain centered caption, no quote card | Drop quote-card chrome; plain 'Take a moment.' in lighter weight. Honest about absent reason. | |
| Soft prompt to add a reason later | 'No reason set. / Add one later from the entry's edit screen.' Micro-nudge. | |
| App name as the hero instead | Blocked app's display name in big M3 Display ('Instagram.'), nothing else. | ✓ |

**User's choice:** App name as the hero instead.
**Notes:** This overrides Claude's Turn-1 hybrid claim ("no app icon / no WAIT banner — the screen's job is to slow down, not announce"). The user's interpretation is internally consistent: when the user has given the screen material (reason), it speaks back with their voice; when they haven't, it just names the blocked app without commentary. No app icon, no nag, no puppet-voice copy. Visual divergence from the with-reason state is intentional.

---

## Claude's Discretion (deferred areas — within stated scope bounds)

- **CD-01 — REL-01 companion foreground service.** Ship without FGS first. Escalate to discuss-phase only if REL-04 overnight survival fails. Manifest permissions stay declared (declared-but-unused is fine).
- **CD-02 — "Use anyway" timing rule.** Ship variant (a) — Use anyway text link enabled immediately on screen load. Hard-block already omits it (PAUS-09); soft-block respecting autonomy is the v1 contract.
- **CD-03 — REL-04 OEM-survival exit gate device + script.** Planner specifies the concrete pass criterion (< 500 ms detect-to-pause after 8 h idle on Xiaomi or Samsung). Planner adds a "device acquisition" sub-task if no real Xiaomi/Samsung is on-hand; emulator substitute requires discuss-phase escalation.

---

## Deferred Ideas (captured during discussion, NOT in v1 Phase 4)

- Custom cooldown durations beyond {1, 3, 5, 10} minutes — DIFF-03 v1.x.
- Streak callout on the auto-close ✓ card — Phase 5.
- "Why?" reason input modal on Use anyway — explicit PROJECT.md anti-feature.
- WorkManager periodic schedule-window evaluator — out of scope for v1.
- Calendar heatmap of pause-event outcomes — DIFF-02 v1.x.
- Home-screen widget — DIFF-04 v1.x.
- Per-app distinct cooldown themes — out of scope.
- Resume cooldown across activity death — acceptable v1 trade-off; restart the wedge.
- Persisted "last picked cooldown" per-entry — fresh-on-each-pause; reconsider M2.
- Use-anyway rate-limit / per-day cap — out of scope; streak engine (Phase 5) is the consequence.
- Localization (non-English) — future milestone.
- REL-04 OEM emulator substitute (Pixel + MIUI image) — escalate to discuss-phase if real device unavailable.
- REL-01 FGS as default — see CD-01; ship without, add only if REL-04 fails.
