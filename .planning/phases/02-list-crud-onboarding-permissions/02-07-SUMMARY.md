---
phase: 2
plan: 07
plan_id: 02-07
subsystem: ui
tags: [flutter, riverpod, drift-stream, home-list, fab, m3, list-crud, phase-2-wave-4]
status: complete
completed: 2026-05-05
duration_minutes: 104
requires:
  - 02-04 (BlockListRepository.watchAll() — Stream<List<BlockListData>>, sorted by updatedAt desc)
  - 02-05 (PermissionStatusApi — only consumed transitively via AppIcon's appIconBytesProvider)
  - 02-06 (AppIcon ConsumerWidget — packageName-keyed icon with Icons.android fallback)
provides:
  - HomeScreen — Surface 4 unified Apps + Habits ListView; ConsumerWidget over a private autoDispose StreamProvider wrapping blockListRepoProvider.watchAll(). Empty list -> EmptyHomeState; non-empty -> ListView.builder of BlockListRow.
  - BlockListRow — 64dp ListTile; AppIcon for kind=0+packageName!=null, Icons.spa_outlined glyph for kind=1; tap routes to /list/edit/{id}; em-dash streak placeholder; no swipe, no long-press, no Dismissible.
  - EmptyHomeState — Surface 12 with locked verbatim copy ("Nothing on your list yet." + "Add an app or habit you want to avoid to get started.") and Icons.check_circle_outline glyph.
  - test/features/home/home_screen_unified_list_test.dart — 10 widget tests covering empty/single-app/single-habit/mixed-list/sort/FABs/FAB-nav/tap-row-nav/em-dash. All pass; full project test suite stays green at 110 passing, 2 sibling-stub skipped.
affects:
  - Plan 02-09 (Router + DynamicColorBuilder + HealthCheckBanner): owns the routing rewire to point `/` at HomeScreen; owns the banner integration. HomeScreen does NOT host the banner internally — 02-09 chooses the integration shape (shell route vs body rewrite). See "Wave 5 hand-off" below.
  - lib/features/home/pages/empty_home_screen.dart: Phase 1 stub stays in tree, byte-identical, unreferenced after 02-09.
tech-stack:
  added: []
  patterns:
    - "Private autoDispose StreamProvider wrapping a domain Stream — keeps the Drift subscription bound to the screen lifecycle and gives the test framework a clean disposal path. Pattern reusable for any future screen that consumes a Drift `Stream<List<T>>` (Phase 3 dashboard, Phase 5 streak history)."
    - "Widget-test cleanup helper `drainStreamTimers(tester)` — calls `tester.runAsync(() => tester.pumpWidget(SizedBox.shrink()))` to drain Drift's `markAsClosed` microtask before the test framework's pending-timer invariant check. Without this, every test using a stream-backed Riverpod provider hangs on a pending-timer assertion at teardown."
    - "Real in-memory AppDatabase + BlockListRepository in widget tests (matches Plan 02-06 fixture pattern) — faster + more truthful than mocking a 7-method repository surface. mocktail is reserved for the platform layer (PermissionStatusApi)."
    - "Stream-via-Riverpod over StreamBuilder — when the source is a Drift QueryStream, `ref.watch(streamProvider).when(...)` cancels the subscription via the autoDispose lifecycle; a bare `StreamBuilder` plus a `Provider<Repo>.watchAll()` does NOT — the subscription leaks to the test framework's invariant check."
key-files:
  created:
    - lib/features/home/widgets/block_list_row.dart
    - lib/features/home/widgets/empty_home_state.dart
    - lib/features/home/pages/home_screen.dart
  modified:
    - test/features/home/home_screen_unified_list_test.dart
key-decisions:
  - "Wrapped repo.watchAll() in a private autoDispose StreamProvider rather than calling StreamBuilder directly. The plan body suggests both shapes (`ref.watch(blockListRepoProvider).watchAll() OR FutureProvider over getAll()`); StreamProvider is the only one that survives widget-test teardown without a pending-timer leak. Karpathy §4 — `watch the stream` doesn't say `via StreamBuilder`; the type is what matters."
  - "Did NOT mount the HealthCheckBanner inside HomeScreen.body even though UI-SPEC Surface 4 shows it as a Column child. Plan 02-07 prompt scope-guard explicitly says the banner is Plan 02-09's surface; HomeScreen ships as the list+FABs only. Plan 02-09 will choose between (a) wrapping HomeScreen in a ShellRoute, or (b) editing HomeScreen.body to slot the banner above the list. See `Wave 5 hand-off` below."
  - "Used in-memory AppDatabase + real BlockListRepository in tests rather than mocktail-mocking the repo surface. Matches Plan 02-06 widget-test fixture; mocktail is reserved for PermissionStatusApi (the platform-channel boundary)."
  - "Re-used the `repo.watchAll()` literal verbatim inside the StreamProvider body so the acceptance grep `grep -q \"repo.watchAll()\"` passes without requiring the literal in the build method itself. The acceptance grep is a coverage proxy for `consumes the stream` — wrapping it in a provider is still consuming it."
patterns-established:
  - "Drift-stream-into-Riverpod-into-widget pattern: `final myStreamProvider = StreamProvider.autoDispose<T>((ref) => ref.watch(repoProvider).watchSomething());` consumed via `ref.watch(myStreamProvider).when(loading:, error:, data:)`. The `autoDispose` is what makes widget tests work — it ensures the Drift subscription cancels before the test framework's invariant check runs."
  - "drainStreamTimers test helper — bring this into a shared test util when Phase 3 lands a second screen consuming `repo.watchAll`-like sources. Today it's local to `home_screen_unified_list_test.dart`; promote to `test/_fixtures/` only when a second consumer needs it."
requirements-completed:
  - LIST-04
  - LIST-05
  - LIST-06
metrics:
  duration_minutes: 104
  completed_date: "2026-05-05"
  tasks_completed: 2
  files_created: 3
  files_modified: 1
  commits: 2
  flutter_test_result: "All tests passed (110 passing, 2 sibling-stub skipped — same as pre-plan baseline + 9 newly passing home tests minus 1 displaced Wave 0 stub)."
  dart_analyze_errors: 0
  dart_analyze_warnings: 0
  dart_analyze_info_pre_existing: 18 (test/_fixtures/permission_status_mock.dart — pre-existing from Plans 02-01 / 02-03; out of scope)
---

# Phase 2 Plan 07: HomeScreen Unified List + 2 FABs Summary

Home screen Surface 4 ships: a unified Apps + Habits `ListView` consuming `blockListRepoProvider.watchAll()` via a private autoDispose `StreamProvider`, the empty-state Surface 12 with locked verbatim copy, two FABs (`+ Add habit` and `+ Add app`), and a 64 dp `BlockListRow` that distinguishes apps from habits by icon source only (AppIcon vs `Icons.spa_outlined`). Tap-row navigates to `/list/edit/{id}`; long-press and swipe have no behaviour. 10 widget tests pass; full project suite stays green.

## Performance

- **Duration:** ~104 min
- **Tasks completed:** 2 / 2
- **Files created:** 3 (production widgets + screen)
- **Files modified:** 1 (Wave 0 test stub filled in)
- **Commits:** 2 (feat + feat)
- **Test result:** `flutter test` exits 0 — 110 passing, 2 skipped (sibling-plan stubs).

## Tasks Completed

| Task     | Name                                                        | Commit    | Files                                                                                                            |
| -------- | ----------------------------------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------- |
| 02-07-01 | `BlockListRow` widget + `EmptyHomeState` widget             | `63c3218` | `lib/features/home/widgets/block_list_row.dart`, `lib/features/home/widgets/empty_home_state.dart`               |
| 02-07-02 | `HomeScreen` (replaces `EmptyHomeScreen`) + 2 FABs + tests  | `6d93b65` | `lib/features/home/pages/home_screen.dart`, `test/features/home/home_screen_unified_list_test.dart`              |

## Files Created / Modified

### Created (3)

- **`lib/features/home/widgets/block_list_row.dart`** — `StatelessWidget`. Fixed `SizedBox(height: 64)` wrapping a `ListTile` whose leading is `AppIcon(packageName: …)` for apps (kind=0 + non-null packageName) or `Icon(Icons.spa_outlined, size: 32)` for habits / packageName-less rows. Title = `displayName` (titleMedium, ellipsised); subtitle = `reasonNote` (bodyMedium onSurfaceVariant, ellipsised, only when non-empty); trailing = `Text('—')` em-dash placeholder. `onTap` calls `context.go('/list/edit/${entry.id}')`. No `onLongPress`, no `Dismissible`.
- **`lib/features/home/widgets/empty_home_state.dart`** — `StatelessWidget`. Centred Column: `Icons.check_circle_outline` (size 64, outlineVariant) → SizedBox 16 → `Text('Nothing on your list yet.')` (headlineSmall) → SizedBox 8 → `Text('Add an app or habit you want to avoid to get started.')` (bodyLarge onSurfaceVariant). Both lines centred and the page padded 32 horizontal.
- **`lib/features/home/pages/home_screen.dart`** — `ConsumerWidget`. Hosts a private `StreamProvider<List<BlockListData>>.autoDispose` that `ref.watch(blockListRepoProvider).watchAll()`. The `Scaffold` has an `AppBar(title: 'Not To-Do List', centerTitle: false)`, body driven by `entriesAsync.when(loading:, error:, data:)` — empty list -> `EmptyHomeState`, non-empty -> `ListView.builder(itemBuilder: BlockListRow)`. Two `FloatingActionButton.extended` stacked in a Column at `endFloat`: `+ Add habit` (heroTag `add_habit`, `surface` fill, `primary` fg) on top, `+ Add app` (heroTag `add_app`, `primary` fill, `onPrimary` fg) below. Tapping each FAB calls `context.go('/list/add-habit')` / `context.go('/list/add-app')`.

### Modified (1)

- **`test/features/home/home_screen_unified_list_test.dart`** — Wave 0 stub replaced with 10 `testWidgets` cases inside `group('HomeScreen unified list (LIST-04, LIST-05, LIST-06)', …)`:
  1. `empty list shows EmptyHomeState message`
  2. `renders single app entry with displayName + reason`
  3. `renders single habit entry with spa_outlined icon`
  4. `renders mixed Apps + Habits in single unified ListView (no section headers)`
  5. `list is ordered by updatedAt desc (LIST-06)` — uses `tester.runAsync` for ≥1.1 s real-time gaps (Drift seconds-precision storage)
  6. `+ Add app and + Add habit FABs both render`
  7. `+ Add app FAB navigates to /list/add-app`
  8. `+ Add habit FAB navigates to /list/add-habit`
  9. `tap row navigates to /list/edit/{id}`
  10. `streak placeholder is em-dash for Phase 2`

  Each test ends with `await drainStreamTimers(tester)` — a local helper calling `tester.runAsync(() async { await tester.pumpWidget(SizedBox.shrink()); await Future.delayed(Duration.zero); })` that drains Drift's `markAsClosed` microtask before the test framework's pending-timer invariant check.

## REQ-ID Coverage

| REQ-ID  | Demonstrated by                                                                                                                                  |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| LIST-04 | Edit-screen route literal `/list/edit/{id}` is the row's tap handler — verified by `tap row navigates to /list/edit/{id}`. Editing itself ships in 02-06.   |
| LIST-05 | Cascade delete itself is asserted in Plan 02-04's repo round-trip test; HomeScreen reflects deletions via `repo.watchAll()`. No HomeScreen-side delete UI (per CONTEXT.md "no swipe-to-delete"). |
| LIST-06 | `list is ordered by updatedAt desc` test inserts app, sleeps ≥1.1 s, inserts habit, sleeps ≥1.1 s, calls `repo.updateEntry` on the app, then asserts the just-touched app sits at index 0 of the rendered rows. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Comment in `block_list_row.dart` collided with the acceptance grep `! grep -E "onLongPress|Dismissible"`.**

- **Found during:** Task 02-07-01 acceptance verification (grep matched the doc comment "// No onLongPress — CONTEXT.md …" lifted verbatim from the plan body).
- **Issue:** The plan example contains the comment `// No onLongPress — CONTEXT.md "Long-press has no behavior in v1."` AND the plan's automated check requires zero matches of the literal `onLongPress` in the file. The comment trips the grep.
- **Fix:** Replaced the comment with `// Tap is the only row gesture in v1 (per CONTEXT.md row UX rules).` — preserves intent, drops the colliding tokens.
- **Files modified:** `lib/features/home/widgets/block_list_row.dart`
- **Commit:** `63c3218`

**2. [Rule 1 — Bug] `Icon(Icons.check_circle_outline, size: 64, color: cs.outlineVariant)` exceeded the 80-char line lint.**

- **Found during:** Task 02-07-01 `dart analyze`.
- **Issue:** `very_good_analysis 10.2.0` enforces `lines_longer_than_80_chars`. The plan example put all four args on one line (length 81).
- **Fix:** Broke the call across multiple lines.
- **Files modified:** `lib/features/home/widgets/empty_home_state.dart`
- **Commit:** `63c3218`

**3. [Rule 1 — Bug] Plain `StreamBuilder<List<BlockListData>>(stream: repo.watchAll(), …)` (per the plan example) hung widget tests for ~60 minutes with `A Timer is still pending even after the widget tree was disposed`.**

- **Found during:** Task 02-07-02 first test run (timed out with stack ending in `StreamQueryStore.markAsClosed → ProviderElement.dispose → ProviderScopeState.dispose`).
- **Issue:** Drift's `QueryStream._onCancelOrPause` schedules a microtask via `Timer.run` to mark the stream as closed. When a `StreamBuilder` cancels its subscription during widget disposal, that microtask is still pending when the test framework runs `_verifyInvariants`, which asserts `!timersPending`. Result: every widget test using a Drift stream hangs in a 30-minute pending-timer retry loop.
- **Fix:** Replaced the bare `StreamBuilder` with a private autoDispose `StreamProvider<List<BlockListData>>` consumed via `ref.watch(_homeEntriesProvider).when(...)`, AND added a `drainStreamTimers(tester)` helper called at the end of each `testWidgets` body that runs `await tester.pumpWidget(SizedBox.shrink())` inside `tester.runAsync` to give the Drift cleanup microtask a chance to fire before the invariant check. Both changes together are what makes the suite green; either alone is insufficient.
- **Files modified:** `lib/features/home/pages/home_screen.dart`, `test/features/home/home_screen_unified_list_test.dart`
- **Commit:** `6d93b65`

**4. [Rule 1 — Bug] Sort test's `Future.delayed(1100ms)` outside `tester.runAsync` produced fake-async pending timers.**

- **Found during:** Task 02-07-02 first test run (same hang as #3, but reproducible even with the StreamProvider fix).
- **Issue:** Inside `testWidgets`, `Future.delayed` runs against the fake-async clock by default; real wall-clock waits leak as pending timers.
- **Fix:** Wrapped the three repository writes + the two 1100 ms gaps in `await tester.runAsync(() async { … })`, which switches to the real `Timer` clock for the duration of the closure.
- **Files modified:** `test/features/home/home_screen_unified_list_test.dart`
- **Commit:** `6d93b65`

**5. [Rule 3 — Blocking] `final _homeEntriesProvider = StreamProvider.autoDispose<…>(…)` failed `specify_nonobvious_property_types`.**

- **Found during:** Task 02-07-02 analyser pass.
- **Issue:** The lint requires explicit type annotations on top-level `final` declarations whose type is non-obvious from the RHS.
- **Fix:** Annotated the provider with `final StreamProvider<List<BlockListData>> _homeEntriesProvider = StreamProvider.autoDispose<List<BlockListData>>((ref) {...});`. (In Riverpod 3.x, `StreamProvider.autoDispose` returns a `StreamProvider` whose `isAutoDispose = true`; there is no separate `AutoDisposeStreamProvider` exported from the public barrel.)
- **Files modified:** `lib/features/home/pages/home_screen.dart`
- **Commit:** `6d93b65`

### Surgical Adjustments to Plan Text

**6. Test fixture uses real `AppDatabase(NativeDatabase.memory()) + BlockListRepository(BlockListDao(db))` instead of `mocktail.Mock implements BlockListRepository`.** The plan body's example sketches a `_FakeRepo extends Mock implements BlockListRepository` with `when(() => repo.watchAll()).thenAnswer(…)`. The established Plan 02-06 fixture pattern is real Drift in-memory + real repo (mocktail reserved for PermissionStatusApi). Karpathy §3 — match existing style. The real-DB approach is also more truthful: it actually exercises `repo.watchAll`'s `ORDER BY updatedAt DESC` clause, which a mock `thenAnswer(Stream.value(...))` does not.

**7. HomeScreen does NOT host the HealthCheckBanner inline.** UI-SPEC Surface 4 shows `body: Column(children: [HealthCheckBanner(), Expanded(ListView)])`. The plan-07 prompt scope-guard explicitly defers banner integration to Plan 02-09 ("the Phase 2 banner (Plan 02-09) will mount above this list later"). Honoured the plan over the UI-SPEC; documented the integration choice point for 02-09 below. Karpathy §3 — touch only what the plan asks for.

### Removed-from-scope (CLAUDE.md §2 simplicity-first)

None. The plan's two tasks were complete in scope.

### Auth gates

None. All work is local Dart UI code + in-memory Drift; no native APIs touched.

### Architectural changes (Rule 4)

None.

## Issues Encountered

- **Drift's pending-timer trap in widget tests** — see deviation #3. The combination autoDispose-StreamProvider + drainStreamTimers helper is the right pattern for any future screen that consumes `Drift.watchAll()`-style streams. Phase 3 (dashboard) will encounter this; promote `drainStreamTimers` to `test/_fixtures/` when a second consumer lands.
- **`flutter` not on PATH inside this agent's bash** — resolved by `export PATH="$HOME/flutter/bin:$PATH"` at the start of every `flutter test` and `dart analyze` command. Same workaround as Plan 02-06.

## TDD Gate Compliance

This plan is `type: execute` (not `type: tdd`); per-plan RED/GREEN/REFACTOR gate does not apply. Per-task commits use conventional types: `feat(02-07)` for both tasks. Test edits ship inside Task 02-07-02's `feat` commit because the Wave 0 stub was previously a single skipped test — the production-code commit and the test-replacement are atomic.

## Wave 5 Hand-off Notes (for Plan 02-09)

The Plan 02-09 executor needs to make ONE of two integration choices. Both are achievable; pick whichever matches the broader REL-02 / REL-03 architecture:

### Option A — ShellRoute that mounts banner + HomeScreen (recommended)

Add a `ShellRoute` to `app_router.dart`:
```dart
ShellRoute(
  builder: (context, state, child) => Column(children: [
    const HealthCheckBanner(),  // Surface 11 — conditional renders SizedBox.shrink when healthy
    Expanded(child: child),
  ]),
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    // …other home-tier routes if any
  ],
),
```

Pros: HomeScreen stays single-purpose; the banner is a router-level concern (it only renders on home-tier routes anyway). Matches the "no business logic in screen widgets" rule established in 02-06.

### Option B — Edit HomeScreen.body to slot the banner above the list

Change HomeScreen's body from `entriesAsync.when(...)` directly to:
```dart
body: Column(children: [
  const HealthCheckBanner(),   // SizedBox.shrink when healthy
  Expanded(child: entriesAsync.when(...)),
]),
```

Pros: Matches UI-SPEC Surface 4 component-tree literally. Cons: HomeScreen now imports the health feature; coupling grows.

### Other invariants that must hold after 02-09

1. **`/` route must point at `HomeScreen`, not `EmptyHomeScreen`.** Phase 1's `EmptyHomeScreen` stays in tree (no orphan deletes per CLAUDE.md §3) but becomes unreferenced.
2. **The three new GoRoute strings (`/list/add-app`, `/list/add-habit`, `/list/edit/:id`) must be registered.** `HomeScreen` already issues `context.go(...)` to all three; 02-06's `EditEntryScreen` issues `context.go('/')` after save/delete. Today the production router has only `/` registered (Phase 1) — 02-09 wires the rest.
3. **`appIconBytesProvider` is consumed by `AppIcon`, which `BlockListRow` uses for app rows.** Plan 02-09's DynamicColorBuilder change must NOT remove the existing `ProviderScope` mounting; the AppIcon LRU(50) and the recently-used apps cache live in the global container.

### Stable surfaces 02-09 can rely on

- `HomeScreen()` is a `ConsumerWidget`, no required ctor args.
- `BlockListRow(entry: …)` is a public `StatelessWidget` for direct use if 02-09 builds a richer test harness.
- `EmptyHomeState()` is a public `StatelessWidget`, no args.
- The private `_homeEntriesProvider` inside `home_screen.dart` is intentionally private; do not try to override it from a router test — override `blockListRepoProvider` instead and the StreamProvider will recompute.

## Self-Check: PASSED

**File existence:**
- ✓ FOUND: lib/features/home/pages/home_screen.dart
- ✓ FOUND: lib/features/home/widgets/block_list_row.dart
- ✓ FOUND: lib/features/home/widgets/empty_home_state.dart
- ✓ FOUND: test/features/home/home_screen_unified_list_test.dart (replaced Wave 0 stub)
- ✓ PRESERVED: lib/features/home/pages/empty_home_screen.dart (byte-identical, mtime untouched)

**Commit existence:**
- ✓ FOUND: 63c3218 (feat(02-07): add BlockListRow + EmptyHomeState widgets)
- ✓ FOUND: 6d93b65 (feat(02-07): add HomeScreen unified list + 2 FABs + widget tests)

**Acceptance grep coverage (verified post-commit):**
- ✓ `height: 64` in block_list_row.dart
- ✓ `Icons.spa_outlined` in block_list_row.dart
- ✓ `context.go('/list/edit/` in block_list_row.dart
- ✓ no `onLongPress` / `Dismissible` in block_list_row.dart
- ✓ `'Nothing on your list yet.'` in empty_home_state.dart
- ✓ `'Add an app or habit you want to avoid'` in empty_home_state.dart
- ✓ `Icons.check_circle_outline` in empty_home_state.dart
- ✓ `class HomeScreen extends ConsumerWidget` in home_screen.dart
- ✓ `'+ Add app'` and `'+ Add habit'` in home_screen.dart
- ✓ `'Not To-Do List'` in home_screen.dart
- ✓ `repo.watchAll()` in home_screen.dart
- ✓ no `Dismissible` / `onLongPress` / `showDialog(` in home_screen.dart

**Test status:** `flutter test` exits 0 — 110 passing, 2 skipped (sibling stubs in `test/features/health/` and `test/features/onboarding/` filled by 02-09/02-10). 10 newly passing tests in `test/features/home/home_screen_unified_list_test.dart`.

**Analyzer:** `dart analyze lib/features/home/ test/features/home/` — no issues. Project-wide: 18 pre-existing infos in `test/_fixtures/permission_status_mock.dart` (Plans 02-01 / 02-03 — out of 02-07 scope per CLAUDE.md §3).

**Threat-model deltas:** none. This plan ships only Dart UI code; no new platform surface, no new permission, no new disk surface, no new network call. The health-check banner (and any associated permission probes) is Plan 02-09's threat surface.

## Threat Flags

None — no new security-relevant surface introduced by this plan.

## Known Stubs

None. All UI elements wire to real provider state from Plan 02-04 (`blockListRepoProvider.watchAll()`) and real navigation routes registered by Plan 02-09. The em-dash trailing column on `BlockListRow` is a documented Phase 5 Streak slot (`STRK-01` / `STRK-07`); it is not a stub for missing data — it is a deliberate "tracking not yet live" placeholder per CONTEXT.md and UI-SPEC Surface 4.

---

*Phase: 02-list-crud-onboarding-permissions*
*Plan: 02-07*
*Completed: 2026-05-05*
