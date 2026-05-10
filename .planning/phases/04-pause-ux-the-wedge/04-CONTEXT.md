# Phase 4: Pause UX (the wedge) — Context

**Gathered:** 2026-05-10
**Status:** Ready for planning
**Source:** /gsd-discuss-phase 4 (interactive — 1 of 4 gray areas selected; 4 sub-turns on the pause-screen feel & layout; remaining 3 areas deferred to research / planner discretion within scope)

<domain>
## Phase Boundary

Phase 4 delivers **the wedge** — the magic moment that the product exists to create.

Four concrete deliverables (PAUS-01..10, REL-01, REL-04):

1. **The `NotToDoAccessibilityService` body.** Fill the Phase-1 Kotlin stub at `android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt`. Observes `TYPE_WINDOW_STATE_CHANGED`, 800 ms debounce, matches the foregrounded `packageName` against an in-memory `Set<String>` block-list. Block-list is refreshed via an `ACTION_BLOCKLIST_UPDATED` `LocalBroadcast` from Dart whenever the user mutates `block_list` — the service **never** writes to SQLite (research Pattern 1). On a positive match, the service evaluates the per-entry schedule (PAUS-10) and per-entry block-mode (PAUS-09), then launches `PauseActivity` via `Intent` with `FLAG_ACTIVITY_NEW_TASK`, passing the blocked package + entry ID + block-mode as extras.

2. **The Flutter `PauseActivity`.** Fill the Phase-1 stub at `android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt`. `FlutterActivity` with `singleInstance` + `excludeFromRecents` + `showOnLockScreen` (already in `AndroidManifest.xml`). On creation: `setShowWhenLocked(true)` + `setTurnScreenOn(true)` for PAUS-08; reads intent extras; routes the Flutter engine to a `/pause/:entryId` route. Cold-start budget < 300 ms (PAUS-07) via a pre-warmed `FlutterEngine` in `FlutterEngineCache`.

3. **The pause-screen Flutter UI.** Calm/mindful identity (Phase-2 forest-green seed, M3 dynamic color OFF). User's reason as hero quote-card (or blocked-app display name when reason is empty). M3 `SegmentedButton` cooldown chips `[1m] [3m] [5m] [10m]`. Thin `LinearProgressIndicator` countdown at top + "X:XX remaining" caption. Asymmetric buttons — `Cancel` primary, `Use anyway` as small text link beside it for soft entries (omitted entirely for hard per PAUS-09). Auto-close = brief ✓ Done card (~1.5 s) → `finish()` to launcher.

4. **REL-01 + REL-04 strategic calls.** REL-01 companion foreground-service decision is left as a planner / research call **within the bounds defined in `<deferred>` below**. REL-04 OEM-survival overnight exit gate is the first such gate in v1 — Phase 4 must pass overnight on a real non-Pixel device (Xiaomi or Samsung) before exit.

**Phase 4 does NOT implement:** streak engine (Phase 5 — `STRK-01..09`), daily reminder / `POST_NOTIFICATIONS` earned prompt / `BOOT_COMPLETED` re-arm (Phase 5 — `NOTF-01..07`), settings / export / theme switching (Phase 6 — `SETT-01,02,04,05`), Play closed-track submission (Phase 6 — `PLAY-08`). Phase 4 **does** write `pause_events` rows (Dart, single writer); Phase 5 reads them for streak threshold checks.

</domain>

<v1_scope_carryforward>
## v1 Product Scope — locked, carried forward from PROJECT.md (2026-05-05) + 02-CONTEXT.md + 03-CONTEXT.md

Per the v1 positioning locked 2026-05-05 in `7119f85`, downstream agents MUST respect:

**In scope (v1, Phase 4):**
- Adult self-control only — single-user model
- Soft-block + cooldown as the default; hard-block per-item opt-in (Apps only — `LIST-08` / `PAUS-09`)
- Per-item schedule opt-in (single optional active window via `LIST-09` / `PAUS-10`)
- 100% on-device — Dart is the single writer to `pause_events`; service never writes to SQLite
- Pigeon-typed channels only — no hand-rolled `MethodChannel`, no `SYSTEM_ALERT_WINDOW`, no `flutter_overlay_window`, no `QUERY_ALL_PACKAGES`
- `PauseActivity` is a `FlutterActivity` (Phase-1 architecture lock)
- `AccessibilityService` is policy-correct: `TYPE_WINDOW_STATE_CHANGED` only, `isAccessibilityTool="false"`, no `performAction` / `performGlobalAction` / `dispatchGesture` calls (`PLAY-02`)
- All Riverpod providers hand-written (no `@riverpod` codegen — analyzer-pin incompatibility per `01-01-SUMMARY.md`)
- Existing 8-invariant `test/policy/play_invariants_test.dart` must remain green at phase exit

**Explicitly NOT in v1 (Phase 4) — do not absorb during planning:**
- Streak counter / streak break threshold / streak labels — that's Phase 5 (`STRK-01..09`)
- Daily reminder notifications / earned `POST_NOTIFICATIONS` prompt / `BOOT_COMPLETED` re-arm — that's Phase 5 (`NOTF-*`)
- Settings / export / theme / privacy-policy link — that's Phase 6 (`SETT-*`)
- Custom cooldown durations outside `{1, 3, 5, 10}` minutes — that's `DIFF-03` v1.x
- "Use anyway" reason / "Why?" input modal — would re-add the anti-feature "Math problems / typing tasks as bypass"
- Multiple schedule windows per entry / schedule presets ("Work hours" / "Bedtime") — explicit Phase 2 lock; per-entry schedule is one optional window in v1
- Parent PIN / kid mode / content filter / anti-uninstall / device admin — Milestone 2 territory
- Calendar heatmap of pause-event history — `DIFF-02` v1.x
- Home-screen widget for "avoided today" — `DIFF-04` v1.x
- Telemetry / FCM / analytics — non-negotiable `SETT-03` privacy stance

If gray areas surface during research or planning that would require any of the above, defer — DO NOT silently add.
</v1_scope_carryforward>

<decisions>
## Implementation Decisions

### Pause-screen feel & layout (D-01..08, locked across 4 discussion turns)

- **D-01 — Visual mood: calm / mindful, hybrid base.** Phase-2 forest-green seed kept (`0xFF2D6A4F`), Material 3 `dynamicColor: false` (consistent identity with Phase 2 + 3). NO breathing-style animation — the cooldown progress IS the screen's only animation. NO red / stop-sign / WAIT iconography. NO app icon at top.
- **D-02 — Reason placement (reason present): hero quote-card.** User's reason rendered in an italic / serif accent quote-card in the upper-middle of the screen — visually the heaviest element on the screen. The whole reason the wedge works is the user's own voice talking back to them. Card uses `Material 3 Headline Small` (or comparable scale) with quote glyphs around the text.
- **D-03 — Reason placement (reason empty): blocked app's display name as hero.** When `block_list.reason` is null or empty, replace the quote-card entirely with the blocked app's display name in big `Material 3 Display Medium` (e.g., `"Instagram."`). NO quote-card chrome, NO app icon, NO puppet-voice copy (we do NOT show "Pause and reflect" in quote-card styling — that reads as the APP talking, not the user). Visual divergence from the with-reason state is intentional: when the user has given the screen material, it speaks back; when they haven't, it names the app and lets the cooldown do the work.
- **D-04 — Cooldown selector: M3 `SegmentedButton` reusing the Phase-2 `block_mode_segmented.dart` shape.** Chips `[1m] [3m] [5m] [10m]`. NO default pre-selection — user must tap a chip to start the cooldown (one mindful tap is the minimum activation cost). Tapping a chip starts the countdown immediately. Tapping a different chip while running re-starts at the new duration (decision: replace, not add; supports "I want a longer pause now that I'm here"). NO `[ +Custom ]` chip — custom durations are `DIFF-03` v1.x.
- **D-05 — Countdown affordance: thin `LinearProgressIndicator` pinned to top edge + small caption.** `LinearProgressIndicator` drains left → right over the chosen cooldown, pinned to the top edge of the screen. Below the selected chip, a small caption reads `"X:XX remaining"` (Material 3 `BodySmall`). Reason stays the visual hero; the countdown is peripheral but reassuring. NO center progress ring (would compete with reason hero). NO big falling digits (clashes with calm mood).
- **D-06 — Button hierarchy: asymmetric Cancel-primary / Use-anyway-text-link.** `Cancel` is M3 `FilledButton` (primary action — the path the wedge wants). `Use anyway` is a small text link rendered beside `Cancel` (Material `TextButton` with default body color, slightly smaller scale). For **hard-block entries (`PAUS-09`)** the `Use anyway` text link is omitted entirely (not just hidden — never rendered in the widget tree). Asymmetry expresses the wedge's preference without removing the soft-block escape hatch.
- **D-07 — Auto-close: brief ✓ Done card (~1.5 s) → `finish()` to launcher.** When the `LinearProgressIndicator` drains to zero, the screen morphs for ~1.5 seconds into a calm `"✓ Cooldown complete"` confirmation card (no judgment copy, NO streak callout, NO "nice job" — those slide into Phase 5's gamification-adjacent territory and are explicitly out of scope). Then `PauseActivity.finish()` returns Android to the launcher. The `pause_events` row is written with `outcome = 0` (cooldown-completed) before the confirmation card renders. Mid-cooldown `Cancel` writes `outcome = 1`; mid-cooldown `Use anyway` writes `outcome = 2`.
- **D-08 — No copy that puts words in the user's mouth.** The screen does NOT render any copy like "I want to focus on deep work" or "Pause and reflect" in the reason hero unless the user typed it themselves. Default empty-reason state shows the blocked app's display name only (D-03). The only fixed copy on the screen is "Cooldown:" label, the cooldown chip labels (`1m / 3m / 5m / 10m`), the small countdown caption (`"X:XX remaining"`), `Cancel`, `Use anyway`, and the auto-close `"✓ Cooldown complete"`.

### Carrying forward — architecture & wiring (D-09..16, NOT re-discussed — locked by ROADMAP + research + Phase 1/2/3 surfaces)

- **D-09 — AccessibilityService event filter + debounce.** Observe `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` only (`PLAY-03` / `not_todo_a11y_config.xml`). Debounce 800 ms per `ARCHITECTURE.md` Pattern 1. Match against an in-memory `Set<String>` of blocked package names loaded on service start.
- **D-10 — Block-list refresh path: `ACTION_BLOCKLIST_UPDATED` LocalBroadcast.** Dart sends a `LocalBroadcast` whenever the `BlockListRepository` mutates (`insert`, `update`, `delete`). Service updates its in-memory `Set<String>`. Service NEVER reads from SQLite directly (research Pattern 1 — one writer, no contention). Initial set on service start is requested via the same broadcast (Dart re-sends on `MainActivity.onResume`).
- **D-11 — `PauseActivity` launch path.** Service launches `Intent(this, PauseActivity::class.java)` with `FLAG_ACTIVITY_NEW_TASK` (already required by manifest entry's `singleInstance` launch mode) and extras: `EXTRA_BLOCKED_PACKAGE` (String), `EXTRA_ENTRY_ID` (Long), `EXTRA_BLOCK_MODE` (String — `"soft"` / `"hard"`), `EXTRA_TRIGGERED_AT_MS` (Long — `System.currentTimeMillis()`).
- **D-12 — Schedule gate (PAUS-10).** Before launching `PauseActivity`, the service evaluates the per-entry schedule using the existing pure-Dart `isInScheduleWindow()` helper... **but the service can't call Dart.** Resolution: the service receives the per-entry schedule fields (`startMinutes`, `endMinutes`, `weekdayMask`) inline with the block-list refresh broadcast (so the matching `Set<String>` is actually a `Map<String, ScheduleSlice>`). Inside the service, a small Kotlin port of `isInScheduleWindow` (~30 lines, mirrors `lib/domain/schedule/schedule_window.dart` byte-for-byte) decides whether to fire. Outside the window: launch passes through. Inside the window: launch `PauseActivity`. The Kotlin port has a Dart-parity unit test (`schedule_window_parity_test.dart`) to keep the two implementations in lockstep.
- **D-13 — `pause_events` writer single seam.** Dart writes the `pause_events` row. The service never writes. `PauseActivity` (Flutter) writes one row per session — at first chip tap (with `outcome = null`, temporary), updated on session resolution (`outcome ∈ {0, 1, 2}`); OR a single insert at session-end with the final outcome. Planner's call between insert-at-start vs insert-at-end; either way the schema in Phase 1 already supports it.
- **D-14 — `FlutterEngineCache` pre-warm.** Pre-warm a `FlutterEngine` in `MainActivity.onCreate()` (or `Application.onCreate()`) registered under cache key `"pause_engine"`. `PauseActivity` reuses it via `FlutterActivity.withCachedEngine("pause_engine")`. Pre-warm cost is paid on app cold-start, NOT on the first pause trigger. Achievable cold-start ≤ 300 ms (`PAUS-07`).
- **D-15 — Lock-screen render (`PAUS-08`).** `PauseActivity.onCreate()` calls `setShowWhenLocked(true)` + `setTurnScreenOn(true)`. Manifest already has `android:showOnLockScreen="true"` and `android:taskAffinity=""` so the activity does NOT join the blocked app's task.
- **D-16 — REL-05 swap pattern stays live.** The Phase 1 `blockedAppDetectorProvider` keeps the `useAccessibilityServiceProvider` toggle. Phase 4 fills `AccessibilityBlockedAppDetector` (was `UnimplementedError`) — Phase 4 does NOT change the toggle's default (`true`). The fallback `UsageStatsPollingBlockedAppDetector` remains a `UnimplementedError` stub until kill-switch activation post-`PLAY-08`.

### Claude's Discretion — areas the user explicitly did NOT select (downstream — research/planner makes the call within scope)

These were presented as gray areas in `present_gray_areas` and deliberately deferred. Planner and researcher decide WITHIN the stated bounds. Escalate back to discuss if any new evidence contradicts the bound.

- **CD-01 — REL-01 companion foreground service.** ROADMAP success criterion #4 says the service keeps the AccessibilityService in the Active App Standby Bucket via a companion FGS; research (`ARCHITECTURE.md` L488–489) says explicitly to avoid foreground services — a11y has its own lifecycle and is not subject to Doze restrictions. Manifest already declares `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` permissions. **Discretion bound:** ship without an FGS first. If the REL-04 overnight survival test on Xiaomi or Samsung fails to detect the morning launch within the 500 ms detect-to-pause budget, escalate to discuss-phase before adding the FGS. Removing the two permissions from the manifest is a one-way door for the Play Console declaration; planner can keep them declared even if FGS is not shipped (declared-but-unused is fine and reduces churn risk later).
- **CD-02 — "Use anyway" timing rule.** Two viable readings: (a) available immediately on screen load (instant bypass — minimal friction, respects autonomy), (b) only after the cooldown completes (forced reflection — maximum friction). **Discretion bound:** ship variant (a) — `Use anyway` text link is enabled immediately. Reason: the wedge's strength is the user's own reason text + the visible cooldown, not a forced-reflection gate. Hard-block entries already omit `Use anyway` entirely (`PAUS-09`); soft-block respecting autonomy is the v1 contract. If user testing reveals that instant bypass collapses the wedge, escalate.
- **CD-03 — REL-04 OEM-survival overnight exit gate device + script.** Phase 4 must pass overnight on a real Xiaomi or Samsung. **Discretion bound:** planner specifies a concrete pass criterion: phone idle ≥ 8 h, blocked-app launch the next morning triggers `PauseActivity` within 500 ms (per ROADMAP SC #5). Solo developer's actual device inventory is unknown to Claude — planner should add a "REL-04 device acquisition" sub-task if no Xiaomi or Samsung is on-hand; alternatives: borrow a device for the test window, OR escalate to discuss-phase for a one-time gate relaxation (e.g., "Pixel + emulator running Xiaomi MIUI image" — not strictly equivalent, but cheaper than borrowing real hardware). Test script: manual touch-and-time with `adb shell dumpsys deviceidle force-idle` to simulate the Doze step; record the detect-to-pause ms in `04-VERIFICATION.md`.

### Folded Todos
None — `gsd-sdk query todo.match-phase 4` not run (STATE.md shows no Active Todos as of 2026-05-07).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level (locked decisions, hard guardrails)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/PROJECT.md` — v1 product scope (adult self-control; on-device only; no telemetry; no FCM; soft-block default + hard-block opt-in; per-item schedules opt-in)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/REQUIREMENTS.md` — 68 v1 REQ-IDs; Phase 4 owns `PAUS-01..10`, `REL-01`, `REL-04` (lines 198–207 + 245, 248)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/ROADMAP.md` §"Phase 4: Pause UX (the wedge)" (lines 76–87) — 5 success criteria locked
- `/Users/jintanakhomwong/projects/not-to-do-list/CLAUDE.md` — Karpathy guidelines (simplicity first, surgical changes, no speculative scope) — particularly relevant for resisting the FGS-by-default pull from ROADMAP SC #4 when research recommends otherwise

### Project-level research (do not duplicate; read directly)
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` §"Pattern 1: AccessibilityService is the source of truth" (lines 182–197) — service does NOT write to SQLite; one writer (Dart); LocalBroadcast `BLOCK_LIST_UPDATED` is the refresh path. **Load-bearing for D-10, D-13.**
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` §"FlutterEngineCache pre-warm" (lines 193, 251, 277, 484) — pre-warm at app start; `singleInstance` + warm engine for sub-300ms cold-start. **Load-bearing for D-14.**
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/ARCHITECTURE.md` §"AccessibilityService does NOT need to be a foreground service" (lines 488–489) — explicit research recommendation against FGS in v1. **Tension with ROADMAP SC #4 — see CD-01.**
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/PITFALLS.md` Pitfall #3 (lines 312–315), Pitfall #6 (lines 152–187 — Doze + App Standby Buckets), and L334 "Pause-screen Activity creating fresh Flutter engine" — three anti-patterns Phase 4 must avoid.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/SUMMARY.md` — Phase 4 framing as the wedge; OEM-survival as exit gate.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/research/STACK.md` §"Play Store Permission Justification Strategy" + §"What NOT to use" (no `isAccessibilityTool="true"`, no `performAction`/`performGlobalAction`/`dispatchGesture`).

### Phase 1 outputs (architecture lock + stubs Phase 4 fills)
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/NotToDoAccessibilityService.kt` — Phase-1 stub (no-op). Phase 4 fills the body; PLAY-02 forbidden-call invariants must stay greppable.
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/PauseActivity.kt` — Phase-1 stub. Phase 4 implements `onCreate` with `setShowWhenLocked(true)` + `setTurnScreenOn(true)` and routes the Flutter engine to `/pause/:entryId`.
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/AndroidManifest.xml` — manifest entries for `PauseActivity` (`singleInstance` + `excludeFromRecents` + `showOnLockScreen` + `taskAffinity=""`) and the a11y service. **Frozen Phase-1 surface — Phase 4 must not regress.**
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/res/xml/not_todo_a11y_config.xml` — `accessibilityEventTypes="typeWindowStateChanged"`, `isAccessibilityTool="false"`, `accessibilityFlags="flagDefault"`. **Frozen — do NOT add capabilities here.**
- `/Users/jintanakhomwong/projects/not-to-do-list/pigeons/accessibility_api.dart` + `lib/platform/accessibility_api.g.dart` + `android/.../platform/AccessibilityApi.g.kt` — Pigeon `@HostApi` already declares `isServiceEnabled()` + `openAccessibilitySettings()`. Phase 4 implements `isServiceEnabled()` for real (currently returns hardcoded `false` in `MainActivity.kt:55-58`).
- `/Users/jintanakhomwong/projects/not-to-do-list/android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` — registers Pigeon HostApi impls. Phase 4 (a) replaces the inline `AccessibilityApi` anonymous-object stub with the real impl, (b) pre-warms `FlutterEngine` for `PauseActivity` here.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/database/tables/pause_events_table.dart` — `PauseEvents` schema is locked: `id`, `entryId` (cascade FK to `block_list`), `packageName`, `triggeredAt`, `cooldownChosenSeconds` (nullable when Cancel), `outcome` (`0=cooldown-completed`, `1=cancel`, `2=use-anyway`). **Phase 4 is the writer; no schema change.**
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/blocked_app_detector.dart` — `BlockedAppDetector` interface (REL-05 seam). Phase 4 fills `AccessibilityBlockedAppDetector`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/detectors/accessibility_blocked_app_detector.dart` — Phase-1 `UnimplementedError` stub. Phase 4 fills `initialize`, `updateBlockList`, `detections`, `isHealthy`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/detectors/usage_stats_polling_blocked_app_detector.dart` — Phase-1 kill-switch fallback. **Stays stubbed in Phase 4** — only lights up post-`PLAY-08` rejection.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/providers/blocked_app_detector_provider.dart` — `useAccessibilityServiceProvider` flag (`true` in v1). Phase 4 does NOT flip the default.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/01-foundation-play-declaration/01-01-SUMMARY.md` — explains the `riverpod_generator` drop (analyzer-pin / `meta 1.17` / Pigeon 26.3 incompatibility). Phase 4 also writes hand-rolled Riverpod providers.

### Phase 2 outputs (UI patterns + schedule domain Phase 4 reuses)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/domain/schedule/schedule_window.dart` — `isInScheduleWindow({ now, startMinutes, endMinutes, weekdayMask })`. **Pure Dart.** Phase 4's Kotlin schedule port must match byte-for-byte; add `test/domain/schedule/schedule_window_parity_test.dart` to keep them in lockstep (D-12).
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/list/widgets/block_mode_segmented.dart` — exemplar Material 3 `SegmentedButton` pattern. Phase 4's cooldown chip row uses the same shape (D-04).
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/widgets/health_check_banner.dart` — banner pattern + literal copy `"Accessibility Service is off — app blocking is paused."` (already shipped in Phase 2). Phase 4 plugs the real `isServiceEnabled` value into `permissionHealthProvider` so this banner becomes truth-bearing.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/health/permission_health_provider.dart` — `permissionHealthProvider` exposes the a11y state. Phase 4 makes `accessibilityServiceGranted` live via `AccessibilityApi.isServiceEnabled()`.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/data/repositories/block_list_repository.dart` — Phase 2 repo. Phase 4 adds a `LocalBroadcast` emit on mutation (or routes through a new bridge — planner's call) to feed the service's in-memory set.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/core/router/app_router.dart` — GoRouter spec. Phase 4 adds the `/pause/:entryId` route used by `PauseActivity`'s Flutter engine.
- `/Users/jintanakhomwong/projects/not-to-do-list/test/policy/play_invariants_test.dart` — 8 absence-grep invariants (PLAY-02..06 + v1-scope BIND_DEVICE_ADMIN + forbidden-token sweep). **Must remain green at Phase 4 exit.** No `performAction`, `performGlobalAction`, `dispatchGesture`, or DB-import strings allowed in `NotToDoAccessibilityService.kt`.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/02-list-crud-onboarding-permissions/02-CONTEXT.md` — block-mode + schedule columns Phase 4 reads. Reason note locked as optional (LIST-03) with a placeholder fallback example — Phase 4 finalizes that copy contract (see D-03).
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/onboarding/pages/accessibility_step.dart` — already wires the user through enabling the a11y service. Phase 4 inherits this surface; no changes needed unless the cold-start pre-warm needs onboarding to defer (planner's call).

### Phase 3 outputs (read-side invariants Phase 4 must not break)
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/dashboard/providers/cumulative_totals_provider.dart` — aggregates `pause_events WHERE outcome IN (0, 1)`. **`outcome = 2` (use-anyway) does NOT count as avoided.** Phase 4 honors this contract when writing `pause_events` rows.
- `/Users/jintanakhomwong/projects/not-to-do-list/lib/features/home/widgets/cumulative_totals_card.dart` — currently shows `0 launches blocked · 0 m saved` because `pause_events` is empty. Phase 4 will populate it for the first time — verify the card animates / updates correctly when the first row lands.
- `/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/03-screen-time-dashboard/03-CONTEXT.md` — Phase-3 carry-forward — particularly the no-WorkManager-in-v1 stance (Phase 3 deferred WorkManager to Phase 5; Phase 4 does NOT introduce WorkManager either).

### External (Android docs — Play policy + AccessibilityService)
- https://developer.android.com/guide/topics/ui/accessibility/service — `AccessibilityService` API surface
- https://developer.android.com/reference/android/view/accessibility/AccessibilityEvent#TYPE_WINDOW_STATE_CHANGED — the only event type we observe
- https://support.google.com/googleplay/android-developer/answer/10964491 — Play accessibility-service policy (Jan 28, 2026 update); justification text must be transparent
- https://developer.android.com/develop/ui/views/touch-and-input/accessibility/service#decl — `<accessibility-service>` config XML reference
- https://api.flutter.dev/flutter/services/FlutterEngineCache-class.html — `FlutterEngineCache` for pre-warmed engines

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`NotToDoAccessibilityService.kt`** (`android/app/src/main/kotlin/com/nottodo/not_to_do_list/service/`) — Phase-1 stub already extends `AccessibilityService`, manifest entry already correct (`BIND_ACCESSIBILITY_SERVICE` permission, `intent-filter` for `AccessibilityService` action, `<meta-data>` pointing at `not_todo_a11y_config.xml`). Phase 4 fills `onAccessibilityEvent` body — keeps the file's PLAY-02 / no-DB-imports invariants intact.
- **`PauseActivity.kt`** — empty `FlutterActivity` subclass. Phase 4 adds `onCreate` overrides (`setShowWhenLocked`, `setTurnScreenOn`, intent-extras read, route handoff to Flutter via `FlutterEngineCache`).
- **`AndroidManifest.xml`** — `PauseActivity` already declared with `singleInstance` + `excludeFromRecents` + `showOnLockScreen="true"` + `taskAffinity=""`. `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_SPECIAL_USE` permissions already declared (whether actually used = CD-01).
- **`not_todo_a11y_config.xml`** — `accessibilityEventTypes="typeWindowStateChanged"`, `isAccessibilityTool="false"`, `accessibilityFlags="flagDefault"` — frozen and Play-policy-correct.
- **`AccessibilityApi` Pigeon channel** (`pigeons/accessibility_api.dart` + `lib/platform/accessibility_api.g.dart` + `android/.../AccessibilityApi.g.kt`) — `isServiceEnabled()` + `openAccessibilitySettings()` already exposed. Phase 4 replaces the `MainActivity.kt` inline anonymous-object stub (currently returns `false`) with a real impl.
- **`isInScheduleWindow()`** (`lib/domain/schedule/schedule_window.dart`) — pure-Dart helper consumed by Phase 2 editor preview. Phase 4 ports byte-for-byte to Kotlin for the service-side gate (D-12) and ships a parity test.
- **`SegmentedButton` pattern** (`lib/features/list/widgets/block_mode_segmented.dart`) — exemplar for the cooldown-chip row (D-04).
- **`HealthCheckBanner`** (`lib/features/health/widgets/health_check_banner.dart`) — already includes the `"Accessibility Service is off — app blocking is paused."` line; Phase 4 makes the underlying `accessibilityServiceGranted` signal live.
- **`AccessibilityBlockedAppDetector`** (`lib/data/detectors/accessibility_blocked_app_detector.dart`) — Phase-1 stub. Phase 4 fills the four methods (`initialize`, `updateBlockList`, `detections` Stream, `isHealthy`).
- **`BlockListRepository`** (`lib/data/repositories/block_list_repository.dart`) — mutating ops Phase 4 hooks into to fire the `ACTION_BLOCKLIST_UPDATED` broadcast on every insert/update/delete (D-10).
- **`pause_events` Drift table** (`lib/data/database/tables/pause_events_table.dart`) — schema locked Phase 1; cascade-delete on `entryId` already enforced (Phase 2 fix). Phase 4 is the first writer.

### Established Patterns
- **All Riverpod providers hand-written** — no `@riverpod` codegen (Phase 1 deviation per `01-01-SUMMARY.md`). Phase 4 follows.
- **All Pigeon HostApi impls follow the `*Impl.kt` sibling pattern** — `AppPickerHostImpl.kt`, `PermissionStatusApiImpl.kt`, `UsageApiImpl.kt`. Phase 4 adds `AccessibilityApiImpl.kt` (and extracts the inline anonymous-object stub from `MainActivity.kt`).
- **`MainActivity` registers HostApi impls in `configureFlutterEngine()`** — Phase 4 replaces the inline `AccessibilityApi` anonymous-object with a real `AccessibilityApiImpl(context)` and appends one line.
- **Drift writes via `into(...).insertOnConflictUpdate(...)` or simple `insert(...)`** — Phase 4 inserts `pause_events` rows; no conflict policy needed (autoincrement id).
- **Tests use `mocktail`, not `mockito`** — Phase 2 + 3 settled. Phase 4 mocks `AccessibilityApi`, `BlockedAppDetector`, etc. via `MockX extends Mock implements X`.
- **Lints: `very_good_analysis 10.2.0`** — Phase 4 code must analyze clean (0 errors / 0 warnings; existing 18 pigeons/* infos grandfathered per `deferred-items.md`).
- **GoRouter routes append-only** — Phase 4 adds `/pause/:entryId`; existing 10 routes untouched.
- **PRAGMA `foreign_keys = ON`** is set globally in `app_database.dart`'s `beforeOpen`. Phase 4 `pause_events` writes inherit the cascade-on-delete from `block_list.id`.

### Integration Points
- **`PauseActivity` is reached only via the service's `Intent` launch** — not from the home route, not from any deep link. The `/pause/:entryId` Flutter route is internal to the `PauseActivity` engine only; `appRouterProvider` may need a separate engine-aware variant (planner's call) or `PauseActivity` may bypass the main router entirely.
- **`AccessibilityBlockedAppDetector.detections` Stream** — Phase 4 fills this. Consumed by ... nothing in v1 (the service launches `PauseActivity` directly via Intent, not via Dart stream). REL-05 swap still works because the kill-switch fallback also routes through `PauseActivity`; the Stream is reserved for future analytics/health UIs that we explicitly DO NOT ship in v1.
- **`permissionHealthProvider.accessibilityServiceGranted`** — currently hardcoded to `false` because `AccessibilityApi.isServiceEnabled()` is stubbed in `MainActivity.kt:55-58`. Phase 4 wires the real check; the entire Phase-2 health banner / re-walk path becomes truth-bearing for the first time.
- **Frozen Phase-1/2/3 surface** — Phase 4 does NOT modify: `AndroidManifest.xml` permission set (FGS perms stay declared even if unused per CD-01), `docs/play-declaration.md`, `docs/data-safety.md`, the GoRouter `redirect` gate, `BlockListRepository` schema (only adds a broadcast emit), `OnboardingComplete*`, the 8-invariant `play_invariants_test.dart`, `daily_usage_summary` table, `cumulative_totals_provider.dart`'s SQL aggregate.

</code_context>

<specifics>
## Specific Ideas and Constraints

- **PauseActivity Flutter route:** `/pause/:entryId` (path param) + optional query string `?package={pkg}&mode={soft|hard}&triggeredAt={ms}`. The Flutter engine bound to `PauseActivity` initializes on this route directly (not `/`).
- **Cooldown chip values:** exactly `{1, 3, 5, 10}` minutes — no custom values in v1. Stored on `pause_events.cooldownChosenSeconds` as `60 / 180 / 300 / 600` seconds.
- **`pause_events.outcome` mapping:** `0` = cooldown auto-completed (timer ran to 0), `1` = Cancel pressed (either before or during cooldown), `2` = Use anyway pressed (only valid for soft entries). Hard entries can only produce `0` or `1`.
- **`pause_events.cooldownChosenSeconds`:** non-null when a chip was tapped (even if Cancel pressed mid-cooldown); null only when the user hit Cancel without ever picking a chip.
- **Confirmation card duration:** 1.5 seconds. Hardcoded `Duration(milliseconds: 1500)`.
- **Confirmation card copy:** literal string `"✓ Cooldown complete"`. No additional copy. No streak callout (Phase-5 territory).
- **Pause-screen fixed copy strings (English-only, v1):** `"Cooldown:"`, `"1m"`, `"3m"`, `"5m"`, `"10m"`, `"X:XX remaining"` (format template), `"Cancel"`, `"Use anyway"`, `"✓ Cooldown complete"`. Empty-reason hero copy = the blocked app's `PackageManager.getApplicationLabel(...)` value (no decoration).
- **AccessibilityService debounce:** 800 ms — anything faster floods on rapid `TYPE_WINDOW_STATE_CHANGED` re-fires; anything slower drops legit launches. Matches `ARCHITECTURE.md` Pattern 1 / Phase-2 carry-forward.
- **Broadcast intent action:** `com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED` (qualified, internal-only — no exported manifest entry).
- **Intent extras keys:** `extra_blocked_package`, `extra_entry_id`, `extra_block_mode`, `extra_triggered_at_ms`. Lowercase + snake_case for Kotlin / Dart parity.
- **`FlutterEngineCache` key:** `"pause_engine"`. Pre-warmed in `MainActivity.onCreate()` (NOT `Application.onCreate()` — that conflicts with Flutter 3.41's engine initialization on Android 14+, per Flutter 3.41 release notes).
- **REL-04 pass criterion:** detect-to-pause < 500 ms after 8 h idle on a real Xiaomi or Samsung. Measured manually via `adb shell dumpsys deviceidle force-idle` + stopwatch. Recorded in `04-VERIFICATION.md`.
- **PLAY-02 absence-grep invariants** must remain green: no string `performAction(`, `performGlobalAction(`, `dispatchGesture(` anywhere in `NotToDoAccessibilityService.kt` source.
- **Performance budget:** PauseActivity cold-start < 300 ms with pre-warmed engine on a mid-range device (PAUS-07). Validated via a hand-timed APK install on the same device used for Phase 2 + 3 UAT (Pixel emulator stock Android 16) + recorded baseline.

</specifics>

<deferred>
## Deferred Ideas (captured during discussion, NOT in v1 Phase 4)

- **Custom cooldown durations beyond `{1, 3, 5, 10}` minutes** — `DIFF-03` v1.x.
- **Streak callout on the auto-close ✓ card** ("3-day streak!") — Phase 5 (`STRK-*`). Phase 4 deliberately keeps the auto-close card free of streak / gamification copy.
- **"Why?" reason input modal on Use anyway** — explicit anti-feature per PROJECT.md ("Math problems / typing tasks as bypass").
- **WorkManager periodic schedule-window evaluator** — out of scope for v1; lazy on `TYPE_WINDOW_STATE_CHANGED` is sufficient. Phase 5 introduces WorkManager only for streak rollover + reminder re-arm.
- **Calendar heatmap of pause-event outcomes** — `DIFF-02` v1.x.
- **Home-screen widget for "avoided today" / cooldown counter** — `DIFF-04` v1.x.
- **Per-app distinct cooldown screen themes / branded reasons** — out of scope; one universal pause screen.
- **Resume cooldown across activity death** — if Android kills `PauseActivity` mid-cooldown (extremely rare with `singleInstance` + warm engine), the session is lost and the next launch attempt restarts the wedge. No persisted cooldown state across kills. Acceptable v1 trade-off.
- **Persisted "last picked cooldown" per-entry** — opt for fresh-on-each-pause to keep the chip choice deliberate. Reconsider in M2 if user testing shows that 5 of 6 sessions land on the same chip.
- **`Use anyway` rate-limit / per-day cap** — out of scope. Soft-block respects autonomy; the streak engine in Phase 5 is what punishes overuse.
- **Localization (non-English copy)** — deferred to a future milestone; Phase 4 ships English-only like Phase 2 + 3.
- **REL-04 OEM emulator substitute** (Pixel + MIUI image) — escalate to discuss-phase if real device is unavailable; do not silently substitute.
- **REL-01 companion foreground service as default** — see CD-01. Ship without; add only if REL-04 fails.

### Reviewed Todos (not folded)
None — no active todos in STATE.md as of 2026-05-07.

</deferred>

---

*Phase: 04-pause-ux-the-wedge*
*Context gathered: 2026-05-10 via /gsd-discuss-phase 4 (interactive — pause-screen feel & layout deep-dive across 4 turns)*
*Next step: /gsd-plan-phase 4 in a fresh session*
