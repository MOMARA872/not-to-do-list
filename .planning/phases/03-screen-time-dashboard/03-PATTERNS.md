# Phase 3 — Screen-Time Dashboard — Pattern Map

**Mapped:** 2026-05-07
**Inputs:** `03-CONTEXT.md`, `03-RESEARCH.md`, Phase 1 + Phase 2 source tree
**Phase 1+2 codebase scanned:** `lib/`, `android/app/src/main/kotlin/`, `test/`

This document is the gsd-planner's pattern lookup for Phase 3. Every Phase 3 file maps to a Phase 1 / Phase 2 analog with **verbatim excerpts the executor must imitate**. Phase 3 introduces **zero new framework patterns** (per RESEARCH §Don't Hand-Roll: "every line of code Phase 3 ships should be traceable to a Phase 1 or Phase 2 exemplar"). The only files in this phase without an in-tree analog are (a) the perf-test (`test/perf/dashboard_render_test.dart` — `Stopwatch` + `pumpWidget`), (b) the period-total ribbon, and (c) the letter-avatar fallback widget — all three have RESEARCH.md snippet anchors instead.

---

## File Inventory

Legend:
- **W** = Wave (0 = test stubs + fixtures, 1 = schema/channels, 2 = repos/providers, 3 = UI surfaces, 4 = perf gate).
- **N/M** = New file or Modified.
- **GAP** in *Closest analog*: no Phase 1/2 file plays this role; planner falls back to the snippet in `03-RESEARCH.md`.

### Wave 0 — Test stubs + fixtures (mirror Phase 2 Wave 0)

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `test/_fixtures/usage_summary_fixture.dart` | N | test fixture (Drift seed) | 0 | `test/_fixtures/permission_status_mock.dart` | Same `_fixtures/` location, same convenience-builder shape (Phase 2 already established the pattern). For Drift-row helpers (insert N companions), follow `test/data/database/app_database_test.dart` (line 38-48) `db.into(db.x).insert(XCompanion.insert(...))` form |
| `test/platform/usage_api_kotlin_contract_test.dart` | N | test (Pigeon channel smoke) | 0 | `test/platform/app_picker_api_test.dart` | Same minimal smoke-test pattern (`AppPickerApi()` instantiable); Phase 3 mirrors verbatim with `UsageApi()`. Round-trip `queryRange` coverage lives in repo + screen widget tests via `appPickerApiProvider`-style override |
| `test/data/database/daos/daily_usage_summary_dao_test.dart` | N | test (Drift in-memory DAO) | 0 | `test/data/database/app_database_test.dart` | Same `AppDatabase(NativeDatabase.memory())` + `setUp/tearDown` shell, same `db.into(db.x).insert(XCompanion.insert(...))` round-trip idiom |
| `test/data/repositories/usage_repository_test.dart` | N | test (repo unit) | 0 | `test/data/repositories/block_list_repo_test.dart` | Same `setUp { db = AppDatabase(NativeDatabase.memory()); repo = UsageRepository(...); }` shell; same `mocktail` for Pigeon `UsageApi` mock; same `tearDown(() => db.close())` shape |
| `test/domain/dashboard/dashboard_range_test.dart` | N | test (pure-Dart truth table) | 0 | `test/domain/schedule/is_in_window_test.dart` | Same `group(...) { test(...) }` layout for a pure-Dart helper (no Riverpod / no Drift / no Flutter binding); `is_in_window_test.dart` is the closest sibling testing `isInScheduleWindow` |
| `test/features/dashboard/dashboard_screen_test.dart` | N | test (widget) | 0 | `test/features/home/home_screen_unified_list_test.dart` | Same `_wrap({required repo})` ProviderScope harness; same `drainStreamTimers` helper (line 69-73) for stream-disposal cleanup; same GoRouter stub-routes pattern |
| `test/features/dashboard/widgets/dashboard_row_test.dart` | N | test (widget — bar fill) | 0 | `test/features/list/edit_entry_screen_test.dart` (lines 60-95) | Same `pumpWidget(MaterialApp(home: Scaffold(body: ...)))` style for testing a leaf widget in isolation |
| `test/features/dashboard/widgets/letter_avatar_test.dart` | N | test (widget) | 0 | GAP — no leaf-widget-only tests in Phase 1+2 | Use `tester.pumpWidget(MaterialApp(home: LetterAvatar(label: 'I')))` then `find.text('I')` — Material `CircleAvatar` test idiom |
| `test/features/home/widgets/avoided_today_card_test.dart` | N | test (widget + `StreamProvider` override) | 0 | `test/features/home/health_banner_test.dart` (lines 27-66) | Same `_pumpBanner` ProviderScope-with-router pattern; override `avoidedTodayProvider` with a static `Stream.value(...)` |
| `test/features/home/widgets/cumulative_totals_card_test.dart` | N | test (widget + `StreamProvider` override) | 0 | `test/features/home/health_banner_test.dart` | Same |
| `test/perf/dashboard_render_test.dart` | N | test (perf gate, D-20) | 4 | GAP — no perf tests in Phase 1+2 | RESEARCH §Render-budget perf-test harness (lines 28-30, 142): `Stopwatch` around `tester.pumpWidget(...)` against the 30×20 fixture; `tester.binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps` |

### Wave 1 — Schema (light) + Pigeon Kotlin impl + MainActivity wiring

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/data/database/app_database.dart` | M | Drift DB declaration | 1 | self (Phase 2 file) | Phase 3 appends `DailyUsageSummaryDao` to `daos: [BlockListDao]` (line 20). **NO `schemaVersion` bump** (CONTEXT.md D-12 + RESEARCH §user_constraints: `daily_usage_summary` table already exists Phase 1). Migration block stays unchanged |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApiImpl.kt` | N | Pigeon HostApi Kotlin impl | 1 | `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` (lines 31-58, 60-89) | Identical class shape: `class XImpl(private val context: Context) : XApi { private val executor = Executors.newSingleThreadExecutor(); ... executor.execute { try { ... } catch (e) { callback(Result.failure(e)) } } }`. AppOps gate at line 65-74 of `AppPickerHostImpl.kt` is the **same idiom** Phase 3 reuses (also seen in `PermissionStatusApiImpl.kt` lines 32-36) |
| `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` | M | Flutter engine wiring | 1 | self (Phase 2 file) | Replace the inline stub `object : UsageApi { ... NotImplementedError("Phase 3") }` (lines 23-31) with `UsageApi.setUp(flutterEngine.dartExecutor.binaryMessenger, UsageApiImpl(applicationContext))` — same shape as Phase 2's `AppPickerApi.setUp` block (lines 33-36). Imports must drop `com.nottodo.not_to_do_list.platform.UsagePackageStat` (no longer referenced inline) and add `com.nottodo.not_to_do_list.platform.UsageApiImpl` |

### Wave 2 — DAO, repository, providers, domain helper

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/data/database/daos/daily_usage_summary_dao.dart` | N | Drift DAO | 2 | `lib/data/database/daos/block_list_dao.dart` | Same `@DriftAccessor(tables: [...]) class XDao extends DatabaseAccessor<AppDatabase> with _$XDaoMixin` shape; same `(select(table)..orderBy([...])).watch()` reactive-stream pattern; Phase 3 swaps `getAll/insertEntry` for `upsertDay/getTodayFor/watchRange` per RESEARCH §Pattern 2 |
| `lib/data/repositories/usage_repository.dart` | N | repository (refresh + watch) | 2 | `lib/data/repositories/block_list_repository.dart` | Same domain-language wrapper: `class XRepository { XRepository(this._dao); final XDao _dao; ... }`. Phase 3's surface = `Future<void> refreshIfStale()` + `Stream<List<DailyUsageSummaryData>> watchRange(DateTime start, DateTime end)` per RESEARCH §Architectural Responsibility Map. Mirrors `BlockListRepository`'s thin wrapper style — no business logic in the repo, just shape coercion + DAO calls |
| `lib/domain/dashboard/dashboard_range.dart` | N | enum + boundary helper (pure-Dart) | 2 | `lib/domain/schedule/schedule_window.dart` | Same `library;` directive at top, same single-responsibility pure-Dart helper (no Flutter / no Riverpod imports). RESEARCH lines 758-777 has the verbatim `localMidnight()` and `resolveRange()` shape Phase 3 should copy |
| `lib/domain/providers/usage_api_provider.dart` | N | Riverpod provider (Pigeon singleton) | 2 | `lib/domain/providers/app_picker_api_provider.dart` | Verbatim shape: `final Provider<XApi> xApiProvider = Provider<XApi>((ref) => XApi());` plus the test-override comment (lines 6-9). Drop `app_picker_api.g.dart` import; substitute `usage_api.g.dart` |
| `lib/domain/providers/usage_dao_provider.dart` | N | Riverpod provider (DAO) | 2 | `lib/domain/providers/block_list_dao_provider.dart` | Verbatim: `final Provider<XDao> xDaoProvider = Provider<XDao>((ref) => XDao(ref.watch(databaseProvider)));` |
| `lib/domain/providers/usage_repo_provider.dart` | N | Riverpod provider (repository) | 2 | `lib/domain/providers/block_list_repo_provider.dart` | Verbatim: `final Provider<XRepository> xRepoProvider = Provider<XRepository>((ref) => XRepository(ref.watch(xDaoProvider)));`. Per CONTEXT.md D-19 the canonical name is `usageRepositoryProvider` (NOT `usageRepoProvider`) — the file path uses the shorter form to match Phase 2's `block_list_repo_provider.dart` filename, but the exported symbol is `usageRepositoryProvider` |

### Wave 3 — UI: route, screen, widgets, providers

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `lib/core/router/app_router.dart` | M | GoRouter declaration | 3 | self (Phase 2 file) | Append-only: add `GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen())` after the existing `/list/edit/:id` route (line 41). Existing `redirect:` callback (lines 21-31) already gates `/dashboard` correctly because `'/dashboard'.startsWith('/onboarding')` is false → post-onboarding route. NO redirect changes |
| `lib/features/dashboard/providers/dashboard_range_provider.dart` | N | StateProvider | 3 | GAP — Phase 1+2 have no `StateProvider` use; closest is `lib/features/onboarding/providers/onboarding_cursor_provider.dart` (a `NotifierProvider<int>`) | A 3-state enum with no persistence is a strict `StateProvider` use case (CONTEXT.md D-05: "session only — no `shared_preferences` write"). Verbatim shape: `final StateProvider<DashboardRange> dashboardRangeProvider = StateProvider<DashboardRange>((_) => DashboardRange.day);` |
| `lib/features/dashboard/providers/dashboard_rows_provider.dart` | N | StreamProvider.autoDispose.family | 3 | `lib/features/home/pages/home_screen.dart` lines 14-18 (`_homeEntriesProvider`) + `lib/features/list/providers/app_icon_cache_provider.dart` lines 47-62 (`appIconBytesProvider`) | The first analog is the exact `StreamProvider.autoDispose<>` shape (no family); the second is the `.family<>` parameterization mechanic. RESEARCH §Pattern 3 (lines 584-619) prescribes the **two-StreamProvider + derived Provider** pattern (avoids `rxdart` dep). **Use the "Better alternative" snippet** at RESEARCH lines 587-619 verbatim, NOT the `async*` double-loop |
| `lib/features/dashboard/providers/avoided_today_provider.dart` | N | StreamProvider.autoDispose | 3 | `lib/features/home/pages/home_screen.dart` lines 14-18 | Verbatim shape: private `StreamProvider.autoDispose<AvoidedTodaySummary>` reading `repo.watchAll()` + `usageRepo.watchRange(today, now)` + `dailyCheckinsDao.watchToday()` and computing the X-of-Y count locally |
| `lib/features/dashboard/providers/cumulative_totals_provider.dart` | N | StreamProvider.autoDispose | 3 | `lib/features/home/pages/home_screen.dart` lines 14-18 | Same `StreamProvider.autoDispose<CumulativeTotalsSummary>` shape; backing query is a Drift `customSelect("SELECT COUNT(*) AS n, COALESCE(SUM(cooldown_chosen_seconds), 0) AS s FROM pause_events WHERE outcome IN (0, 1)").watch()` (CONTEXT.md "Cumulative card SQL") |
| `lib/features/dashboard/pages/dashboard_screen.dart` | N | screen (`ConsumerStatefulWidget` + `WidgetsBindingObserver`) | 3 | `lib/features/onboarding/pages/usage_access_step.dart` (lines 12-65) for the lifecycle pattern; `lib/features/home/pages/home_screen.dart` for the consumer + `Scaffold` + `AnimatedSwitcher(banner)` shell | The Phase 2 `UsageAccessStep` is the **canonical `WidgetsBindingObserver` mixin** in Phase 1+2 (also see `_health_lifecycle_observer.dart` lines 25-48 for the **paired addObserver/removeObserver** discipline). For the body (top → segmented → ribbon → list), follow `home_screen.dart` lines 30-64 layout: `Scaffold(appBar, body: Column([banner-when-unhealthy, Expanded(content)]))` |
| `lib/features/dashboard/widgets/dashboard_segmented.dart` | N | widget (SegmentedButton) | 3 | `lib/features/list/widgets/block_mode_segmented.dart` | Verbatim shape: `class XSegmented extends StatelessWidget { ... value/onChanged ... SegmentedButton<T>(segments: [...], selected: <T>{value}, onSelectionChanged: (sel) => onChanged(sel.first)) }`. Phase 3 widens `<T>` from `String` to `DashboardRange` (enum) — same Material 3 widget |
| `lib/features/dashboard/widgets/dashboard_row.dart` | N | widget (icon + name + bar-fill + duration) | 3 | `lib/features/home/widgets/block_list_row.dart` | Same `class XRow extends StatelessWidget { ... ListTile/Container leading/title/trailing layout ... }`. RESEARCH §Pattern 5 (lines 670-717) has the **verbatim** `LinearProgressIndicator` + `Border(left: BorderSide(color: cs.primary, width: 4))` + `Opacity(0.6 vs 1.0)` shape Phase 3 must copy. Material 3 stock widgets only — no chart library |
| `lib/features/dashboard/widgets/letter_avatar.dart` | N | widget (icon-cache-miss fallback) | 3 | `lib/features/list/widgets/app_icon.dart` (lines 21-39) | Same `Icon(Icons.android, size: size, color: Theme.of(context).colorScheme.onSurfaceVariant)` fallback idiom — but instead of an icon, render `CircleAvatar(child: Text(label.characters.first.toUpperCase()))`. RESEARCH §App Icon Strategy (lines 781-799) describes the seam |
| `lib/features/dashboard/widgets/period_total_ribbon.dart` | N | widget (top-of-list summary card) | 3 | GAP — no `Card.outlined` ribbon in Phase 1+2 | Use Material 3 `Card.outlined(child: Padding(child: Row([Text("Day total"), Spacer(), Text("4h 23m across 12 apps")])))`. Tap-to-collapse handled with `StatefulWidget` + `onTap` (no Riverpod state) |
| `lib/features/home/widgets/avoided_today_card.dart` | N | widget (Material 3 `Card.outlined`) | 3 | `lib/features/health/widgets/health_check_banner.dart` (lines 39-101) **structurally** | Same `Material(child: InkWell(onTap: ..., child: Padding(child: Column([headline, subtitle]))))` layered widget pattern (substitute `Card.outlined` for `Material(color: bg)`). Tap → `context.go('/dashboard')` mirrors banner's `_tapToFix` (line 112-130) |
| `lib/features/home/widgets/cumulative_totals_card.dart` | N | widget (Material 3 `Card.outlined`) | 3 | `lib/features/health/widgets/health_check_banner.dart` (lines 39-101) | Same as above |
| `lib/features/home/pages/home_screen.dart` | M | screen (insert two cards) | 3 | self (Phase 2 file) | Append-only insertion: between the existing `AnimatedSwitcher(banner)` (lines 41-49) and the `Expanded(child: entriesAsync.when(...))` (lines 50-62), insert `const AvoidedTodayCard(), const CumulativeTotalsCard()` (or wrap them in a `Padding` for spacing). The cards belong to the home identity — do **NOT** wrap them in `AnimatedSwitcher` (CONTEXT.md D-17) |

### Wave 4 — Perf gate

| File | N/M | Role | W | Closest analog | Why this analog |
|------|-----|------|---|----------------|-----------------|
| `test/perf/dashboard_render_test.dart` | N | test (perf gate, D-20) | 4 | GAP | RESEARCH lines 28-30, 142: `Stopwatch sw = Stopwatch()..start(); await tester.pumpWidget(harness); sw.stop(); expect(sw.elapsedMilliseconds, lessThan(300));` against the 30×20 seeded fixture. Optionally `tester.binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;` to disable buildDuringFlush throttling |

---

## Per-File Pattern Excerpts

### `lib/data/database/app_database.dart` (MODIFY)

- **Wave:** 1
- **Role:** Drift DB declaration
- **Analog:** self

**Pattern excerpt — current state** (verbatim, lines 12-21 of `lib/data/database/app_database.dart`):
```dart
@DriftDatabase(
  tables: [
    BlockList,
    DailyStreak,
    PauseEvents,
    DailyCheckins,
    DailyUsageSummary,
  ],
  daos: [BlockListDao],
)
class AppDatabase extends _$AppDatabase {
```

**Required divergence in Phase 3** — append one DAO entry; do **NOT** bump `schemaVersion` (table already exists from Phase 1):
```dart
@DriftDatabase(
  tables: [
    BlockList,
    DailyStreak,
    PauseEvents,
    DailyCheckins,
    DailyUsageSummary,
  ],
  daos: [BlockListDao, DailyUsageSummaryDao], // Phase 3 addition
)
```

Style notes the executor MUST preserve:
- Keep `_openConnection()` static factory and the optional `QueryExecutor?` ctor argument (line 23-24) — required by tests (`AppDatabase(NativeDatabase.memory())`).
- Keep `schemaVersion => 2` (line 29) UNCHANGED — Phase 1 already shipped `daily_usage_summary`.
- Keep the `beforeOpen: customStatement('PRAGMA foreign_keys = ON;')` hook (lines 46-48) UNCHANGED.
- Re-run `dart run build_runner build` after adding the DAO so `app_database.g.dart` regenerates the `dailyUsageSummary` accessor on `AppDatabase`.

---

### `lib/data/database/daos/daily_usage_summary_dao.dart` (NEW)

- **Wave:** 2
- **Role:** Drift DAO
- **Analog:** `lib/data/database/daos/block_list_dao.dart`

**Pattern excerpt** (verbatim from `lib/data/database/daos/block_list_dao.dart`, lines 1-28):
```dart
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/tables/block_list_table.dart';

part 'block_list_dao.g.dart';

/// Drift DAO for the [BlockList] table — typed CRUD over the v2 schema
/// landed by Plan 02-02. Phase 2 sort key is `updatedAt` desc; Phase 4/5
/// will join `pause_events.last_pause_event_time` and
/// `daily_checkins.last_check_in_time` (CONTEXT.md "last activity desc").
@DriftAccessor(tables: [BlockList])
class BlockListDao extends DatabaseAccessor<AppDatabase>
    with _$BlockListDaoMixin {
  BlockListDao(super.attachedDatabase);

  /// All entries sorted by `updatedAt` desc.
  Future<List<BlockListData>> getAll() {
    return (select(blockList)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Stream variant for reactive home-screen rebinding.
  Stream<List<BlockListData>> watchAll() {
    return (select(blockList)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }
```

**Generated mixin** (verbatim from `lib/data/database/daos/block_list_dao.g.dart` lines 1-9 — proves the codegen output shape Phase 3 must produce via `build_runner`):
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_list_dao.dart';

// ignore_for_file: type=lint
mixin _$BlockListDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockListTable get blockList => attachedDatabase.blockList;
  BlockListDaoManager get managers => BlockListDaoManager(this);
}
```

**Phase 3 divergence** — surface = `upsertDay` + `getTodayFor` + `watchRange` (RESEARCH §Pattern 2 lines 478-525, verbatim):
```dart
@DriftAccessor(tables: [DailyUsageSummary])
class DailyUsageSummaryDao extends DatabaseAccessor<AppDatabase>
    with _$DailyUsageSummaryDaoMixin {
  DailyUsageSummaryDao(super.attachedDatabase);

  /// Upsert one day's row for one package. Idempotent (D-14).
  Future<void> upsertDay({
    required String packageName,
    required DateTime day,
    required int foregroundSeconds,
    required int launchCount,
    required DateTime aggregatedAt,
  }) {
    return into(dailyUsageSummary).insertOnConflictUpdate(
      DailyUsageSummaryCompanion.insert(
        packageName: packageName,
        day: day,
        foregroundSeconds: foregroundSeconds,
        launchCount: Value(launchCount),
        aggregatedAt: aggregatedAt,
      ),
    );
  }

  Future<DailyUsageSummaryData?> getTodayFor(
    String packageName,
    DateTime localMidnight,
  ) =>
      (select(dailyUsageSummary)
            ..where((t) =>
                t.packageName.equals(packageName) &
                t.day.equals(localMidnight)))
          .getSingleOrNull();

  Stream<List<DailyUsageSummaryData>> watchRange(
    DateTime startDay,
    DateTime endDay,
  ) =>
      (select(dailyUsageSummary)
            ..where((t) => t.day.isBetweenValues(startDay, endDay))
            ..orderBy([(t) => OrderingTerm.desc(t.day)]))
          .watch();
}
```

Style notes:
- `part 'daily_usage_summary_dao.g.dart';` directive must match the file name pattern (`block_list_dao.g.dart` precedent).
- `insertOnConflictUpdate(...)` is the canonical idempotent-upsert idiom — relies on the unique key `{packageName, day}` declared in `lib/data/database/tables/daily_usage_summary_table.dart` lines 14-17.
- DO NOT add a CRUD-style `getAll/insertEntry/updateEntry/deleteEntryById` surface — Phase 3 only needs the three above.

---

### `lib/data/repositories/usage_repository.dart` (NEW)

- **Wave:** 2
- **Role:** Repository (refresh + watch)
- **Analog:** `lib/data/repositories/block_list_repository.dart`

**Pattern excerpt** (verbatim from `lib/data/repositories/block_list_repository.dart`, lines 1-18):
```dart
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';

/// Quick-add seed entry shape — kept on the repository surface so callers
/// don't have to know about Drift companions.
typedef BlockListSeed = ({int kind, String? packageName, String displayName});

/// Domain-language wrapper around [BlockListDao]. UI + onboarding code
/// depends on this seam, NOT directly on the DAO.
class BlockListRepository {
  BlockListRepository(this._dao);

  final BlockListDao _dao;

  Future<List<BlockListData>> getAll() => _dao.getAll();

  Stream<List<BlockListData>> watchAll() => _dao.watchAll();
```

**Phase 3 surface** (NEW — sketched per RESEARCH §Architectural Responsibility Map and CONTEXT.md D-12 + D-14):
```dart
class UsageRepository {
  UsageRepository(this._dao, this._api);

  final DailyUsageSummaryDao _dao;
  final UsageApi _api; // Pigeon-generated

  static const Duration _todayCacheTtl = Duration(minutes: 5);

  /// Trigger an aggregator pass IFF today's row is older than 5 minutes
  /// (or missing). Idempotent — safe to call on every initState/resume/pull.
  /// CONTEXT.md D-12 / D-14.
  Future<void> refreshIfStale({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    // ... query api → upsert via _dao.upsertDay(...)
  }

  /// Reactive stream over [start, end] — drives the dashboard list.
  Stream<List<DailyUsageSummaryData>> watchRange(DateTime start, DateTime end) =>
      _dao.watchRange(start, end);
}
```

Style notes:
- Constructor is positional `(this._dao, this._api)` — same shape as `BlockListRepository(this._dao)`.
- `Future<void>` and `Stream<...>` return types — same shape as Phase 2.
- Repository owns NO business logic beyond shape coercion + Pigeon→Drift bridging — keep the join/highlight/sort logic in `dashboardRowsProvider` (RESEARCH §Pattern 3).
- `refreshIfStale` is the SINGLE seam every dashboard surface calls — never bypass it (RESEARCH §Architectural Responsibility Map line 162).

---

### `lib/domain/dashboard/dashboard_range.dart` (NEW)

- **Wave:** 2
- **Role:** Pure-Dart enum + boundary helper
- **Analog:** `lib/domain/schedule/schedule_window.dart`

**Pattern excerpt** (verbatim from `lib/domain/schedule/schedule_window.dart`, lines 1-12):
```dart
/// Pure-Dart helper that decides whether a given moment is inside a
/// schedule's active window. Consumed by:
/// - Phase 2 editor preview (LIST-09 visual indicator on the entry row)
/// - Phase 4 PAUS-10 (interception is gated on this returning true)
/// - Phase 5 STRK-09 (streak counting only when the entry is "active")
///
/// Pure Dart — no Flutter, no Riverpod imports.
library;

/// True iff [now] falls within the schedule defined by start/end
/// minutes-of-day and a weekday bitmask.
```

**Phase 3 divergence** — RESEARCH lines 753-777 has the verbatim shape:
```dart
/// Pure-Dart helper for the dashboard range selector (CONTEXT.md D-05).
/// Pure Dart — no Flutter, no Riverpod imports.
library;

enum DashboardRange { day, week, month }

/// Local-timezone midnight floor of [t]. DST-safe enough for Phase 3.
DateTime localMidnight(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Range resolution for D-12 / DASH-03 / DASH-04.
({DateTime start, DateTime end}) resolveRange(DashboardRange r, DateTime now) {
  final today = localMidnight(now);
  switch (r) {
    case DashboardRange.day:
      return (start: today, end: now);
    case DashboardRange.week:
      return (start: today.subtract(const Duration(days: 6)), end: now);
    case DashboardRange.month:
      return (start: today.subtract(const Duration(days: 29)), end: now);
  }
}
```

Style notes:
- `library;` directive on a leading comment block — same shape as `schedule_window.dart` line 8.
- NO Flutter / NO Riverpod / NO Drift imports — `dart:core` only.
- Record type `({DateTime start, DateTime end})` — modern Dart 3.x idiom (already used in test/data tests).

---

### `lib/domain/providers/usage_api_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod provider (Pigeon singleton)
- **Analog:** `lib/domain/providers/app_picker_api_provider.dart`

**Pattern excerpt** (verbatim from `lib/domain/providers/app_picker_api_provider.dart`, lines 1-11):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

/// Pigeon channel singleton for the app picker (installed apps, recently used,
/// per-package PNG icon bytes). Hand-written (no `@riverpod` codegen).
///
/// Tests override via:
/// `appPickerApiProvider.overrideWith((ref) => MockAppPickerApi())`.
final Provider<AppPickerApi> appPickerApiProvider =
    Provider<AppPickerApi>((ref) => AppPickerApi());
```

**Phase 3 divergence** — substitute `UsageApi` for `AppPickerApi`; update doc-string to reference Phase 3 / CONTEXT.md D-19. Verbatim shape preservation.

---

### `lib/domain/providers/usage_dao_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod provider (DAO)
- **Analog:** `lib/domain/providers/block_list_dao_provider.dart`

**Pattern excerpt** (verbatim from `lib/domain/providers/block_list_dao_provider.dart`, lines 1-10):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';

/// Hand-written [Provider] for [BlockListDao] — Phase 2 follows the Phase 1
/// hand-written pattern per Plan 01-01's analyzer-conflict deviation.
/// See `lib/domain/providers/database_provider.dart`.
final Provider<BlockListDao> blockListDaoProvider = Provider<BlockListDao>(
  (ref) => BlockListDao(ref.watch(databaseProvider)),
);
```

**Phase 3 divergence** — substitute `DailyUsageSummaryDao` for `BlockListDao`. Comment block stays identical (the rationale applies to all hand-written providers).

---

### `lib/domain/providers/usage_repo_provider.dart` (NEW)

- **Wave:** 2
- **Role:** Riverpod provider (repository)
- **Analog:** `lib/domain/providers/block_list_repo_provider.dart`

**Pattern excerpt** (verbatim from `lib/domain/providers/block_list_repo_provider.dart`, lines 1-10):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_dao_provider.dart';

/// Hand-written [Provider] for [BlockListRepository] — the single seam UI +
/// onboarding code consumes for not-to-do list CRUD.
final Provider<BlockListRepository> blockListRepoProvider =
    Provider<BlockListRepository>(
  (ref) => BlockListRepository(ref.watch(blockListDaoProvider)),
);
```

**Phase 3 divergence** — repository ctor takes TWO deps, not one. Per CONTEXT.md D-19, the canonical exported symbol name is `usageRepositoryProvider`:
```dart
final Provider<UsageRepository> usageRepositoryProvider =
    Provider<UsageRepository>(
  (ref) => UsageRepository(
    ref.watch(usageDaoProvider),
    ref.watch(usageApiProvider),
  ),
);
```

⚠ **Naming mismatch alert:** the file path is `usage_repo_provider.dart` (mirrors `block_list_repo_provider.dart`) but the **exported symbol** is `usageRepositoryProvider` (matches CONTEXT.md D-19). This is deliberate — file name follows Phase 2's filename convention; symbol name follows D-19's canonical name. Planner should NOT rename either.

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApiImpl.kt` (NEW)

- **Wave:** 1
- **Role:** Pigeon HostApi Kotlin implementation
- **Analog:** `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt`

**Pattern excerpt — class shell + Executor + try/catch envelope** (verbatim from `AppPickerHostImpl.kt` lines 1-58, 60-89):
```kotlin
package com.nottodo.not_to_do_list.platform

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
// ...
import java.util.concurrent.Executors

/**
 * Phase 2 Plan 02-03 implementation of AppPickerApi.
 *
 * All work runs on a private background Executor — never the UI thread
 * (T-2-06 mitigation: PackageManager + UsageStatsManager calls are I/O-bound
 * and would ANR if invoked on the main thread).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API
 * (performAction / performGlobalAction / dispatchGesture). The forbidden
 * tokens are deliberately kept out of this file so absence-greps stay exact.
 */
class AppPickerHostImpl(private val context: Context) : AppPickerApi {
    private val executor = Executors.newSingleThreadExecutor()

    override fun listInstalledApps(callback: (Result<List<InstalledApp>>) -> Unit) {
        executor.execute {
            try {
                // ...
                callback(Result.success(all))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }
    // ...
    override fun recentlyUsedApps(daysBack: Long, callback: (Result<List<RecentApp>>) -> Unit) {
        executor.execute {
            try {
                // Gate on Usage Access — return emptyList() (NOT throw) when not granted
                // (RESEARCH §App Picker, Pitfall A). Caller's UI inline-prompts to grant.
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
                if (mode != AppOpsManager.MODE_ALLOWED) {
                    callback(Result.success(emptyList()))
                    return@execute
                }
                val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                val start = now - (daysBack * 24L * 3600L * 1000L)
                val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, start, now) ?: emptyList()
```

Note: `AppPickerHostImpl.recentlyUsedApps` is the closest analog because it ALREADY combines (a) Executor dispatch, (b) AppOps gate, (c) `queryUsageStats` call, (d) null-coalesce-to-empty. Phase 3 differs from Phase 2 in two ways:
1. **Phase 3 throws `UsageApiError("USAGE_ACCESS_DENIED", …)` on AppOps deny** (CONTEXT.md D-03) — Phase 2 returns `emptyList()` because the picker has its own UI fallback. Dart catches the error and routes to the no-permission fallback (D-13).
2. **Phase 3 uses `UsageStatsManager.INTERVAL_DAILY`** (CONTEXT.md D-02) — Phase 2 uses `INTERVAL_BEST`.

**Phase 3 full skeleton** (verbatim from RESEARCH §Pattern 1 lines 365-451):
```kotlin
package com.nottodo.not_to_do_list.platform

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Process
import java.util.concurrent.Executors

/**
 * Phase 3 implementation of UsageApi.
 *
 * Runs on a private background Executor — never the UI thread (PITFALLS.md
 * anti-pattern #3: queryUsageStats drops frames if called on the main thread).
 *
 * AppOps gate: returns USAGE_ACCESS_DENIED via UsageApiError so Dart routes
 * to the no-permission fallback (D-13).
 *
 * PLAY-02 invariant: this class MUST NEVER call any autonomous-action API.
 */
class UsageApiImpl(private val context: Context) : UsageApi {
    private val executor = Executors.newSingleThreadExecutor()

    override fun queryRange(
        startEpochMs: Long,
        endEpochMs: Long,
        callback: (Result<List<UsagePackageStat>>) -> Unit,
    ) {
        executor.execute {
            try {
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    context.packageName,
                )
                if (mode != AppOpsManager.MODE_ALLOWED) {
                    callback(
                        Result.failure(
                            UsageApiError(
                                code = "USAGE_ACCESS_DENIED",
                                message = "PACKAGE_USAGE_STATS not granted",
                            ),
                        ),
                    )
                    return@execute
                }
                val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                // INTERVAL_DAILY = system bucket type for daily aggregates.
                // queryUsageStats returns null when the device is locked on
                // Android R+ (PITFALLS.md L313). Treat null as empty list.
                val raw = usm.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY,
                    startEpochMs,
                    endEpochMs,
                ) ?: emptyList()
                val grouped = raw
                    .filter { it.totalTimeInForeground > 0L }
                    .groupBy { it.packageName }
                    .map { (pkg, list) ->
                        UsagePackageStat(
                            packageName = pkg,
                            foregroundSeconds = list.sumOf { it.totalTimeInForeground } / 1000L,
                            launchCount = 0L, // INTERVAL_DAILY UsageStats lacks launchCount
                        )
                    }
                callback(Result.success(grouped))
            } catch (e: SecurityException) {
                // Android R+ locked-device occasionally surfaces SecurityException
                // even past the AppOps gate. Treat as transient.
                callback(Result.success(emptyList()))
            } catch (e: Throwable) {
                callback(Result.failure(e))
            }
        }
    }
}
```

Style notes the executor MUST preserve:
- `package com.nottodo.not_to_do_list.platform` — same package as `AppPickerHostImpl.kt` and `PermissionStatusApiImpl.kt`.
- `(private val context: Context)` ctor — verbatim from line 31 of `AppPickerHostImpl.kt`.
- `private val executor = Executors.newSingleThreadExecutor()` — verbatim from line 32 of `AppPickerHostImpl.kt`.
- The PLAY-02 comment block (kept tokens out of file body) — verbatim, byte-for-byte; absence-grep policy depends on it (`test/policy/play_invariants_test.dart` lines 47-65).
- Use `unsafeCheckOpNoThrow` (the public API name in the platform), NOT `checkOpNoThrow` — `PermissionStatusApiImpl.kt` line 32 verbatim.
- `try { … } catch (e: SecurityException) { Result.success(emptyList()) } catch (e: Throwable) { Result.failure(e) }` — TWO catches in this order; the `SecurityException` swallow is load-bearing for D-04.

---

### `android/app/src/main/kotlin/com/nottodo/not_to_do_list/MainActivity.kt` (MODIFY)

- **Wave:** 1
- **Role:** Flutter engine wiring
- **Analog:** self

**Pattern excerpt — Phase 2 stub still present** (verbatim from `MainActivity.kt` lines 23-31):
```kotlin
        UsageApi.setUp(flutterEngine.dartExecutor.binaryMessenger, object : UsageApi {
            override fun queryRange(
                startEpochMs: Long,
                endEpochMs: Long,
                callback: (Result<List<UsagePackageStat>>) -> Unit
            ) {
                callback(Result.failure(NotImplementedError("UsageApi: implemented in Phase 3")))
            }
        })
```

**Pattern excerpt — Phase 2 real-impl shape** (verbatim from `MainActivity.kt` lines 33-41):
```kotlin
        AppPickerApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            AppPickerHostImpl(applicationContext),
        )

        PermissionStatusApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            PermissionStatusApiImpl(applicationContext),
        )
```

**Required divergence in Phase 3** — replace the inline stub with the impl-class registration shape Phase 2 used:
```kotlin
        UsageApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            UsageApiImpl(applicationContext),
        )
```

Style notes:
- Drop the `import com.nottodo.not_to_do_list.platform.UsagePackageStat` line (line 12 of current MainActivity.kt) — no longer referenced inline.
- Add `import com.nottodo.not_to_do_list.platform.UsageApiImpl`.
- Update the leading `// Phase 2 wires AppPickerApi + PermissionStatusApi as real impls;` comment (line 20) to reflect Phase 3's claim on `UsageApi`.
- Do NOT touch the `AccessibilityApi.setUp(...)` or `NotificationApi.setUp(...)` blocks — those stay stubbed for Phase 4 / Phase 5.

---

### `lib/core/router/app_router.dart` (MODIFY)

- **Wave:** 3
- **Role:** GoRouter declaration
- **Analog:** self

**Pattern excerpt — current routes block** (verbatim from `lib/core/router/app_router.dart` lines 32-43):
```dart
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/onboarding/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/onboarding/quick-add', builder: (_, __) => const QuickAddScreen()),
      GoRoute(path: '/onboarding/permissions/usage-access', builder: (_, __) => const UsageAccessStep()),
      GoRoute(path: '/onboarding/permissions/accessibility', builder: (_, __) => const AccessibilityStep()),
      GoRoute(path: '/onboarding/permissions/battery-opt', builder: (_, __) => const BatteryOptStep()),
      GoRoute(path: '/list/add-app', builder: (_, __) => const AddAppPickerScreen()),
      GoRoute(path: '/list/add-habit', builder: (_, __) => const AddHabitScreen()),
      GoRoute(path: '/list/edit/:id', builder: (ctx, state) => EditEntryScreen(id: int.parse(state.pathParameters['id']!))),
    ],
```

**Required divergence in Phase 3** — append ONE route at the end of the array:
```dart
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
```

Style notes:
- Same `(_, __) => const X()` lambda shape used by 8 of 9 existing routes.
- Add the import: `import 'package:not_to_do_list/features/dashboard/pages/dashboard_screen.dart';` (alphabetical — between `core/router/...` and `features/health/...`).
- Do NOT touch the `redirect:` callback (lines 21-31) — `/dashboard` is a post-onboarding route (does NOT start with `/onboarding`), so the existing redirect handles it correctly (CONTEXT.md D-18).

---

### `lib/features/dashboard/pages/dashboard_screen.dart` (NEW)

- **Wave:** 3
- **Role:** Screen (`ConsumerStatefulWidget` + `WidgetsBindingObserver`)
- **Analog:** `lib/features/onboarding/pages/usage_access_step.dart` (lifecycle pattern); `lib/features/home/pages/home_screen.dart` (consumer + Scaffold + banner shell)

**Pattern excerpt — `WidgetsBindingObserver` mixin** (verbatim from `lib/features/onboarding/pages/usage_access_step.dart` lines 20-44):
```dart
class _UsageAccessStepState extends ConsumerState<UsageAccessStep>
    with WidgetsBindingObserver {
  bool _showOemFallback = false;
  String _manufacturer = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // RESEARCH lines 393-466: re-check on mount; if already granted, skip.
    unawaited(_checkAndMaybeAdvance());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkAndMaybeAdvance(fromResume: true));
    }
  }
```

**Reference precedent — alternative top-level observer** (verbatim from `lib/features/health/widgets/_health_lifecycle_observer.dart` lines 25-48):
```dart
class _HealthLifecycleObserverState
    extends ConsumerState<HealthLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Idempotent — RESEARCH §Pitfall F: spurious resumes on the lock
      // screen are harmless; refresh() simply re-reads the 3 permission
      // signals and updates state.
      unawaited(ref.read(permissionHealthProvider.notifier).refresh());
    }
  }
```

**Pattern excerpt — Scaffold + banner + body shell** (verbatim from `lib/features/home/pages/home_screen.dart` lines 30-64):
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final entriesAsync = ref.watch(_homeEntriesProvider);
    final healthAsync = ref.watch(permissionHealthProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Not To-Do List'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: healthAsync.maybeWhen(
              data: (h) => h.allHealthy
                  ? const SizedBox.shrink()
                  : HealthCheckBanner(health: h),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                if (entries.isEmpty) return const EmptyHomeState();
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => BlockListRow(entry: entries[i]),
                );
              },
            ),
          ),
        ],
      ),
```

**Phase 3 divergence**:
- `_DashboardScreenState` mixes `WidgetsBindingObserver` (verbatim from `usage_access_step.dart`).
- `initState` calls `Future.microtask(() => ref.read(usageRepositoryProvider).refreshIfStale())` (RESEARCH §Pattern 4 lines 638-645).
- `didChangeAppLifecycleState` calls the same on `AppLifecycleState.resumed`.
- `build` returns `Scaffold(appBar: AppBar(title: 'Dashboard'), body: Column([HealthCheckBanner-when-unhealthy, DashboardSegmented, PeriodTotalRibbon, Expanded(RefreshIndicator(ListView.builder))]))` — same `Column` + `Expanded` shape as `home_screen.dart` line 39-64.
- `RefreshIndicator(onRefresh: () => ref.read(usageRepositoryProvider).refreshIfStale(forceBypassCache: true))` — pull bypasses the 5-min cache (CONTEXT.md D-12).
- `dashboardRangeProvider` (`StateProvider<DashboardRange>`) drives the segmented control's `value`; `ref.watch(dashboardRowsProvider(range))` drives the list.

---

### `lib/features/dashboard/widgets/dashboard_segmented.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (Material 3 `SegmentedButton`)
- **Analog:** `lib/features/list/widgets/block_mode_segmented.dart`

**Pattern excerpt** (verbatim from `lib/features/list/widgets/block_mode_segmented.dart`, lines 1-43):
```dart
import 'package:flutter/material.dart';

/// Surface 8 — UI-SPEC LIST-08. Apps-only segmented control between
/// `'soft'` (cooldown + "Use anyway") and `'hard'` (cooldown only). The
/// caller is responsible for hiding this widget for habit entries.
class BlockModeSegmented extends StatelessWidget {
  const BlockModeSegmented({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// `'soft'` or `'hard'`. Default for new entries is `'soft'`.
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Block mode', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'soft', label: Text('Soft')),
            ButtonSegment<String>(value: 'hard', label: Text('Hard')),
          ],
          selected: <String>{value},
          onSelectionChanged: (sel) => onChanged(sel.first),
        ),
        // ...
      ],
    );
  }
}
```

**Phase 3 divergence** — widen `<String>` to `<DashboardRange>` (enum); 3 segments (Day/Week/Month) instead of 2; drop the leading `Text('Block mode', ...)` label (the segmented control sits at the top of the screen and doesn't need a sub-title since the AppBar already says "Dashboard"):
```dart
SegmentedButton<DashboardRange>(
  segments: const <ButtonSegment<DashboardRange>>[
    ButtonSegment<DashboardRange>(value: DashboardRange.day,   label: Text('Day')),
    ButtonSegment<DashboardRange>(value: DashboardRange.week,  label: Text('Week')),
    ButtonSegment<DashboardRange>(value: DashboardRange.month, label: Text('Month')),
  ],
  selected: <DashboardRange>{value},
  onSelectionChanged: (sel) => onChanged(sel.first),
),
```

Style notes:
- `class XSegmented extends StatelessWidget` shape — verbatim.
- `final T value; final ValueChanged<T> onChanged;` ctor pattern — verbatim.
- `selected: <T>{value}` set-of-one literal — verbatim (canonical Material 3 idiom for single-select).
- `onSelectionChanged: (sel) => onChanged(sel.first)` lambda — verbatim.

---

### `lib/features/dashboard/widgets/dashboard_row.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (icon + name + bar-fill + duration)
- **Analog:** `lib/features/home/widgets/block_list_row.dart`

**Pattern excerpt — outer container shape** (verbatim from `lib/features/home/widgets/block_list_row.dart`, lines 17-63):
```dart
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 64,
      child: ListTile(
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        tileColor: cs.surfaceContainer,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: _isApp && entry.packageName != null
                ? AppIcon(packageName: entry.packageName!)
                : Icon(
                    Icons.spa_outlined,
                    size: 32,
                    color: cs.onSurfaceVariant,
                  ),
          ),
        ),
        title: Text(
          entry.displayName,
          // ...
        ),
        // ...
        onTap: () => context.go('/list/edit/${entry.id}'),
      ),
    );
  }
```

**Phase 3 divergence — bar-fill body** (verbatim from RESEARCH §Pattern 5 lines 681-716):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final cs = Theme.of(context).colorScheme;
  final isNotToDo = row.isNotToDo;
  final fillRatio = maxSeconds == 0
      ? 0.0
      : (row.foregroundSeconds / maxSeconds).clamp(0.0, 1.0);
  return Container(
    decoration: BoxDecoration(
      border: isNotToDo
          ? Border(left: BorderSide(color: cs.primary, width: 4))
          : null,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      // App icon (cached) or letter-avatar fallback.
      Opacity(
        opacity: isNotToDo ? 1.0 : 0.6,
        child: _IconOrLetter(packageName: row.packageName, displayName: row.displayName),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row.displayName, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fillRatio,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              isNotToDo ? cs.primary : cs.outlineVariant,
            ),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      Text(_formatDuration(row.foregroundSeconds)),
    ]),
  );
}
```

Style notes:
- `final cs = Theme.of(context).colorScheme;` — same Phase 2 idiom (`block_list_row.dart` line 18).
- `colorScheme.primary` for not-to-do, `colorScheme.outlineVariant` for non-not-to-do — load-bearing, drives D-06.
- `Opacity(opacity: isNotToDo ? 1.0 : 0.6, child: ...)` — load-bearing, drives D-06.
- 4-dp `Border(left: BorderSide(color: cs.primary, width: 4))` — load-bearing, drives D-06.
- `LinearProgressIndicator` is Material 3 stock — NO chart library (RESEARCH §Anti-Patterns).
- `_formatDuration` is a local helper — `intl` package's `DateFormat` is overkill for "1 h 23 m"; a simple `'${seconds ~/ 3600} h ${(seconds % 3600) ~/ 60} m'` formatter is sufficient.

---

### `lib/features/dashboard/widgets/letter_avatar.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (icon-cache-miss fallback)
- **Analog:** `lib/features/list/widgets/app_icon.dart` (lines 21-39 — the fallback `Icon(Icons.android, ...)` clause)

**Pattern excerpt** (verbatim from `lib/features/list/widgets/app_icon.dart` lines 18-42):
```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appIconBytesProvider(packageName));
    return SizedBox(
      width: size,
      height: size,
      child: async.when(
        data: (bytes) {
          if (bytes == null) {
            return Icon(
              Icons.android,
              size: size,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );
          }
          return Image.memory(
            bytes,
            gaplessPlayback: true,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => Icon(
          Icons.android,
          size: size,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
```

**Phase 3 divergence** — `LetterAvatar` is a pure `StatelessWidget` (NOT a `ConsumerWidget` — it's the leaf rendered AFTER `AppIcon`'s null branch fires). Per RESEARCH lines 793-799:
```dart
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({required this.label, super.key, this.size = 40});

  /// Source of the first letter — usually `displayName` or last `.`-segment of packageName.
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter = label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.surfaceContainerHighest,
      foregroundColor: cs.onSurfaceVariant,
      child: Text(letter),
    );
  }
}
```

Style notes:
- `colorScheme.surfaceContainerHighest` — Material 3 token; same family as the bar-fill background in `dashboard_row.dart`.
- `label.characters.first.toUpperCase()` — `characters` package is part of Flutter SDK; safe for emoji + unicode.

---

### `lib/features/dashboard/widgets/period_total_ribbon.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (top-of-list summary card)
- **Analog:** GAP — RESEARCH lines 240-243 (period total ribbon mention) is the only spec anchor

**Sketch:**
```dart
class PeriodTotalRibbon extends ConsumerStatefulWidget {
  const PeriodTotalRibbon({required this.range, super.key});
  final DashboardRange range;
  // ...
}

class _PeriodTotalRibbonState extends ConsumerState<PeriodTotalRibbon> {
  bool _filtered = false;

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(dashboardRowsProvider(widget.range));
    return rowsAsync.maybeWhen(
      data: (rows) {
        final relevant = _filtered ? rows.where((r) => r.isNotToDo).toList() : rows;
        final totalSeconds = relevant.fold<int>(0, (a, r) => a + r.foregroundSeconds);
        return Card.outlined(
          child: InkWell(
            onTap: () => setState(() => _filtered = !_filtered),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Text(
                  '${_label(widget.range)} total: ${_formatDuration(totalSeconds)} '
                  'across ${relevant.length} apps',
                ),
              ]),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
```

Style notes:
- Material 3 `Card.outlined` — same widget Phase 3's two home cards use (CONTEXT.md D-17).
- Local `StatefulWidget` toggle — no Riverpod state for ephemeral filter (mirrors `_HealthCheckBannerState._expanded` line 26 of `health_check_banner.dart`).

---

### `lib/features/home/widgets/avoided_today_card.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (Material 3 `Card.outlined`, tap → `/dashboard`)
- **Analog:** `lib/features/health/widgets/health_check_banner.dart` (structural — `Material(child: InkWell(onTap, child: Padding(child: Column([row, optional details])))))`

**Pattern excerpt — InkWell + Padding + Column shape** (verbatim from `lib/features/health/widgets/health_check_banner.dart` lines 39-101):
```dart
    return Material(
      color: bg,
      child: InkWell(
        onTap: _tapToFix,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tracking is offline — tap to fix',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                  // ...
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                // ...
              ],
            ],
          ),
        ),
      ),
    );
```

**Pattern excerpt — `_tapToFix` async navigation** (verbatim from `lib/features/health/widgets/health_check_banner.dart` lines 112-130):
```dart
  Future<void> _tapToFix() async {
    // Reset onboardingComplete so the BatteryOpt step's
    // _completeOnboarding re-fires when the user reaches the end of the
    // funnel again (ONBD-05, T-2-10).
    await ref.read(onboardingCompleteProvider.notifier).reset();
    if (!mounted) return;
    // Route to FIRST failing step in priority order.
    final h = widget.health;
    if (!h.usageAccess) {
      context.go('/onboarding/permissions/usage-access');
    } else if (!h.accessibilityService) {
      context.go('/onboarding/permissions/accessibility');
    } else if (!h.batteryOptExempt) {
      context.go('/onboarding/permissions/battery-opt');
    } else if (h.fingerprintChanged) {
      context.go('/onboarding/permissions/usage-access');
    }
  }
```

**Phase 3 divergence**:
- Substitute `Material` for `Card.outlined` (Material 3 `Card.outlined` is the "lower visual weight" card per CONTEXT.md D-17).
- The card's tap target is the entire surface — wrap in `InkWell` (or use `Card.outlined`'s built-in `clipBehavior` + `InkWell` child).
- `onTap: () => context.go('/dashboard')` — single line, no async needed (no provider mutation).
- Body is `ref.watch(avoidedTodayProvider).when(loading, error, data)` — render copy from D-09:
  - Y > 0 with usageAccess granted: `"Avoided today" / "{X} of {Y} entries succeeded today"`.
  - Y == 0: `"Avoided today" / "No entries yet"` and route to `/list/add-app`.
  - usageAccess offline: `"Avoided today" / "Tracking is offline — tap to fix"` + tap routes via the same priority-step flow as `HealthCheckBanner._tapToFix`.

Style notes:
- The string `"Tracking is offline — tap to fix"` is byte-for-byte enforced by `test/policy/play_invariants_test.dart` (verbatim copy invariant — see `test/features/home/health_banner_test.dart` line 91 for the test). DO NOT paraphrase.
- Use `Theme.of(context).textTheme.titleMedium` for the headline + `bodyMedium?.copyWith(color: cs.onSurfaceVariant)` for the subtitle — same family as `block_list_row.dart` lines 39-52.

---

### `lib/features/home/widgets/cumulative_totals_card.dart` (NEW)

- **Wave:** 3
- **Role:** Widget (Material 3 `Card.outlined`)
- **Analog:** Same as `avoided_today_card.dart` — `lib/features/health/widgets/health_check_banner.dart` structurally

**Phase 3 divergence**:
- Body reads `ref.watch(cumulativeTotalsProvider).when(loading, error, data)`.
- Renders D-11 copy: `"Total avoided" / "{N} launches blocked · {H}h {M}m saved"`.
- Phase 3 starting state: `pause_events` is empty, so the card renders `"0 launches blocked · 0 m saved"` — that is the **expected and correct** state (CONTEXT.md D-11).

---

### `lib/features/home/pages/home_screen.dart` (MODIFY)

- **Wave:** 3
- **Role:** Screen (insert two cards above the entries list)
- **Analog:** self

**Pattern excerpt — current body shape** (verbatim from `lib/features/home/pages/home_screen.dart` lines 39-64):
```dart
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: healthAsync.maybeWhen(
              data: (h) => h.allHealthy
                  ? const SizedBox.shrink()
                  : HealthCheckBanner(health: h),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                if (entries.isEmpty) return const EmptyHomeState();
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => BlockListRow(entry: entries[i]),
                );
              },
            ),
          ),
        ],
      ),
```

**Required divergence in Phase 3** — insert two cards between the `AnimatedSwitcher(banner)` and the `Expanded(child: entriesAsync.when(...))`:
```dart
      body: Column(
        children: [
          AnimatedSwitcher(/* unchanged */),
          // Phase 3 D-17 — two home cards above the unified list.
          // NOT animated-in via AnimatedSwitcher (CONTEXT.md D-17:
          // "they belong to the home identity, not transient state").
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AvoidedTodayCard(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CumulativeTotalsCard(),
          ),
          Expanded(/* unchanged */),
        ],
      ),
```

Style notes:
- Add imports: `import 'package:not_to_do_list/features/home/widgets/avoided_today_card.dart';` + `import 'package:not_to_do_list/features/home/widgets/cumulative_totals_card.dart';` — alphabetically positioned among `lib/features/home/widgets/...` imports.
- Do NOT touch the `AnimatedSwitcher` block (lines 41-49) — banner is visibility-toggled per `permissionHealthProvider`.
- Do NOT touch the `floatingActionButton` block (lines 65-85) — Phase 2 layout invariant.
- Do NOT touch `_homeEntriesProvider` (lines 14-18) — Phase 3's `dashboardRowsProvider` is a separate provider with separate scope.

---

### `test/_fixtures/usage_summary_fixture.dart` (NEW)

- **Wave:** 0
- **Role:** Test fixture (Drift seed)
- **Analog:** `test/_fixtures/permission_status_mock.dart` (location + builder convention) + `test/data/database/app_database_test.dart` lines 38-48 (Drift `into(...).insert(...Companion.insert(...))` form)

**Pattern excerpt — convenience-builder shape** (verbatim from `test/_fixtures/permission_status_mock.dart` lines 1-27):
```dart
// Phase 2 shared fixture: mock PermissionStatusApi for funnel + banner tests.
// Bound to real PermissionStatusApi from Plan 02-03.
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

class MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

/// Convenience builder. Defaults: every check returns false (i.e. nothing granted),
/// fingerprint = 'fp-test', manufacturer = 'pixel'.
MockPermissionStatusApi buildMockPermissionStatusApi({
  bool usageAccess = false,
  // ...
}) {
  final m = MockPermissionStatusApi();
  when(() => m.isUsageAccessGranted()).thenAnswer((_) async => usageAccess);
  // ...
  return m;
}
```

**Pattern excerpt — Drift insert form** (verbatim from `test/data/database/app_database_test.dart` lines 38-52):
```dart
    test('block_list insert + select round-trips', () async {
      await db.into(db.blockList).insert(
            BlockListCompanion.insert(
              kind: 0,
              packageName: const Value('com.instagram.android'),
              displayName: 'Instagram',
              reasonNote: const Value('Doomscrolling at night.'),
              createdAt: DateTime.utc(2026, 4, 27, 12),
              updatedAt: DateTime.utc(2026, 4, 27, 12),
            ),
          );
```

**Phase 3 sketch:**
```dart
import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

/// Seed [db] with [days] × [packages] daily_usage_summary rows for perf tests
/// (D-20) + edge-case asserts. Default = 30 × 20 = 600 rows. Each row has
/// foregroundSeconds = pseudo-random in [0, 7200], launchCount = 0.
Future<void> seedUsageSummary(
  AppDatabase db, {
  int days = 30,
  int packages = 20,
  DateTime? endDay,
}) async {
  final end = endDay ?? DateTime.now();
  final today = DateTime(end.year, end.month, end.day);
  for (var d = 0; d < days; d++) {
    final day = today.subtract(Duration(days: d));
    for (var p = 0; p < packages; p++) {
      final packageName = 'com.test.package$p';
      final foregroundSeconds = ((d * 13 + p * 17) % 7200);
      await db.into(db.dailyUsageSummary).insert(
            DailyUsageSummaryCompanion.insert(
              packageName: packageName,
              day: day,
              foregroundSeconds: foregroundSeconds,
              aggregatedAt: day.add(const Duration(hours: 23)),
            ),
          );
    }
  }
}
```

---

### `test/perf/dashboard_render_test.dart` (NEW)

- **Wave:** 4
- **Role:** Test (perf gate, D-20)
- **Analog:** GAP — RESEARCH §Render-budget perf-test harness lines 28-30, 102-107, 142

**Sketch** (synthesized from RESEARCH + the Phase 2 widget-test harness in `test/features/home/home_screen_unified_list_test.dart` lines 41-50):
```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/data/repositories/usage_repository.dart';
import 'package:not_to_do_list/domain/providers/usage_repo_provider.dart';
import 'package:not_to_do_list/features/dashboard/pages/dashboard_screen.dart';

import '../_fixtures/usage_summary_fixture.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('dashboard first frame < 300 ms with 30×20 fixture (D-20)',
      (tester) async {
    tester.binding.framePolicy =
        LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
    await seedUsageSummary(db, days: 30, packages: 20);

    final repo = UsageRepository(DailyUsageSummaryDao(db), /* mock UsageApi */);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      ],
    );

    final sw = Stopwatch()..start();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usageRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    sw.stop();

    expect(
      sw.elapsedMilliseconds,
      lessThan(300),
      reason: 'D-20: dashboard first frame must render in < 300 ms',
    );
  });
}
```

⚠ Real-device validation deferred to Phase 4 first task per CONTEXT.md D-20.

---

## Shared Patterns

### Authentication / Permission gating (cross-cutting)

**Source:** `lib/features/health/permission_health_provider.dart` (lines 23-28, 76-80) + `lib/features/health/widgets/health_check_banner.dart` (lines 39-130)

**Apply to:** `dashboard_screen.dart`, `avoided_today_card.dart`

**Concrete excerpt — banner copy invariant** (verbatim, byte-for-byte enforced by `test/policy/play_invariants_test.dart`):
```dart
'Tracking is offline — tap to fix'
```

**Concrete excerpt — `permissionHealthProvider` consumer** (verbatim from `health_check_banner.dart` line 5 + `home_screen.dart` line 33):
```dart
final healthAsync = ref.watch(permissionHealthProvider);
return healthAsync.maybeWhen(
  data: (h) => h.allHealthy
      ? const SizedBox.shrink()
      : HealthCheckBanner(health: h),
  orElse: () => const SizedBox.shrink(),
);
```

**Apply rule:** Both `DashboardScreen` and `AvoidedTodayCard` (D-09 fallback path) consume `permissionHealthProvider` via the same `maybeWhen(data:, orElse:)` shape. Tap on a no-permission state in either surface routes to `/onboarding/permissions/usage-access` — the priority-1 step (matches `HealthCheckBanner._tapToFix` line 119-121).

### Pigeon HostApi error handling (Kotlin side)

**Source:** `android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerHostImpl.kt` (lines 34-58, 60-89) + `PermissionStatusApiImpl.kt` (lines 32-41)

**Apply to:** `UsageApiImpl.kt`

**Concrete excerpt — Executor + try/catch envelope** (verbatim from `AppPickerHostImpl.kt`):
```kotlin
override fun listInstalledApps(callback: (Result<List<InstalledApp>>) -> Unit) {
    executor.execute {
        try {
            // ... system-service call ...
            callback(Result.success(...))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }
}
```

**Concrete excerpt — AppOps gate** (verbatim from `AppPickerHostImpl.kt` lines 65-74):
```kotlin
val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
val mode = appOps.unsafeCheckOpNoThrow(
    AppOpsManager.OPSTR_GET_USAGE_STATS,
    Process.myUid(),
    context.packageName,
)
if (mode != AppOpsManager.MODE_ALLOWED) {
    callback(Result.success(emptyList()))  // Phase 2 path
    return@execute
}
```

**Apply rule:** Phase 3 differs in TWO load-bearing ways from this Phase 2 pattern:
1. Phase 3 returns `Result.failure(UsageApiError("USAGE_ACCESS_DENIED", ...))` instead of `Result.success(emptyList())` (CONTEXT.md D-03 — Dart needs a typed signal to route to no-permission fallback).
2. Phase 3 adds a SECOND catch clause: `catch (e: SecurityException) { callback(Result.success(emptyList())) }` (CONTEXT.md D-04 — Android R+ locked-device).

### Hand-written Riverpod providers (no `@riverpod` codegen)

**Source:** `lib/domain/providers/database_provider.dart` (lines 4-14) + `lib/domain/providers/app_picker_api_provider.dart` (lines 1-11) + `lib/domain/providers/block_list_dao_provider.dart` (lines 1-10) + `lib/domain/providers/block_list_repo_provider.dart` (lines 1-10)

**Apply to:** All Phase 3 providers (`usage_api_provider.dart`, `usage_dao_provider.dart`, `usage_repo_provider.dart`, `dashboard_range_provider.dart`, `dashboard_rows_provider.dart`, `avoided_today_provider.dart`, `cumulative_totals_provider.dart`)

**Concrete excerpt — base shape** (verbatim from `database_provider.dart` lines 4-14):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

/// Singleton [AppDatabase] for the app lifetime.
///
/// Phase 1 uses a plain Riverpod [Provider] (not `@riverpod` codegen) because
/// `riverpod_generator` was dropped in Plan 01-01 due to an analyzer-version
/// conflict with `pigeon 26.3.4` + Flutter 3.41 (see 01-01-SUMMARY.md). The DB
/// is closed when the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

**Apply rule:** Every Phase 3 provider uses `final XProvider = Provider<T>((ref) => ...)` or `StateProvider<T>` or `StreamProvider.autoDispose<T>` — NEVER `@riverpod` annotations. Carry the codegen-rationale comment forward in the doc-string of each new provider (mirrors `block_list_dao_provider.dart` line 5-7).

### Drift in-memory test harness

**Source:** `test/data/database/app_database_test.dart` (lines 6-17) + `test/data/repositories/block_list_repo_test.dart` (lines 13-26) + `test/data/repositories/cascade_delete_test.dart` (lines 13-22)

**Apply to:** `test/data/database/daos/daily_usage_summary_dao_test.dart`, `test/data/repositories/usage_repository_test.dart`

**Concrete excerpt** (verbatim from `block_list_repo_test.dart` lines 18-26):
```dart
late AppDatabase db;
late BlockListRepository repo;

setUp(() {
  db = AppDatabase(NativeDatabase.memory());
  repo = BlockListRepository(BlockListDao(db));
});

tearDown(() => db.close());
```

**Apply rule:** Drift unit/repo tests use `NativeDatabase.memory()` + `setUp/tearDown` shell — never a real SQLite file, never an isolate, never `drift_flutter`'s `driftDatabase(name: ...)`. `tearDown` always calls `db.close()`.

### Widget test ProviderScope harness

**Source:** `test/features/home/home_screen_unified_list_test.dart` (lines 21-50, 69-73) + `test/features/home/health_banner_test.dart` (lines 27-66)

**Apply to:** `test/features/dashboard/dashboard_screen_test.dart`, `test/features/home/widgets/avoided_today_card_test.dart`, `test/features/home/widgets/cumulative_totals_card_test.dart`

**Concrete excerpt — `_wrap` builder** (verbatim from `home_screen_unified_list_test.dart` lines 21-50):
```dart
Widget _wrap({required BlockListRepository repo}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/list/add-app',
        builder: (_, __) => const Scaffold(body: Text('add-app-stub')),
      ),
      // ...
    ],
  );
  return ProviderScope(
    overrides: [
      blockListRepoProvider.overrideWithValue(repo),
      appIconBytesProvider.overrideWith((ref, pkg) async => null),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}
```

**Concrete excerpt — `drainStreamTimers` cleanup** (verbatim from `home_screen_unified_list_test.dart` lines 65-73):
```dart
/// Drains pending Drift stream-disposal timers between widget tests.
/// Without this, ProviderScope.dispose → StreamProvider.dispose →
/// Drift's `markAsClosed` schedules a microtask that the test
/// framework counts as a pending timer past widget-tree disposal.
Future<void> drainStreamTimers(WidgetTester tester) =>
    tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(Duration.zero);
    });
```

**Apply rule:** Every Phase 3 widget test that uses Drift streams ends with `await drainStreamTimers(tester)` — without it the suite leaks pending timers and the next test fails with `pending timer found`.

### Test mocks via `mocktail`

**Source:** `test/_fixtures/permission_status_mock.dart`

**Apply to:** Phase 3 test files needing a `UsageApi` mock

**Concrete excerpt — pattern**:
```dart
class MockUsageApi extends Mock implements UsageApi {}

MockUsageApi buildMockUsageApi({List<UsagePackageStat> stats = const []}) {
  final m = MockUsageApi();
  when(() => m.queryRange(any(), any())).thenAnswer((_) async => stats);
  return m;
}
```

**Apply rule:** `mocktail`, never `mockito`. Class extends `Mock implements X` (NOT `MockX`-style annotation). `when(() => m.method(any())).thenAnswer((_) async => …)` for async methods.

### PLAY-02 absence-grep policy

**Source:** `test/policy/play_invariants_test.dart` (lines 17-67)

**Apply to:** Every NEW Dart and Kotlin source file in Phase 3 must NOT contain:
- `\bperformAction\s*\(`
- `\bperformGlobalAction\s*\(`
- `\bdispatchGesture\s*\(`
- (Manifest tokens enforced separately) `QUERY_ALL_PACKAGES`, `SYSTEM_ALERT_WINDOW`, `BIND_DEVICE_ADMIN`

**Apply rule:** Phase 3's new files (`UsageApiImpl.kt`, all dashboard Dart) must include the same `// PLAY-02 invariant: …` comment block from `AppPickerHostImpl.kt` lines 27-30 / `PermissionStatusApiImpl.kt` lines 25-27 (kept-out-of-file-body pattern). DO NOT modify `play_invariants_test.dart` itself.

---

## No Analog Found

Files with no close in-tree match — planner falls back to RESEARCH.md snippets:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/dashboard/widgets/period_total_ribbon.dart` | widget (`Card.outlined` + tap-to-collapse) | request-response (single tap-to-toggle) | No `Card.outlined` ribbon in Phase 1+2; Phase 3 introduces the pattern. RESEARCH lines 240-243 anchors the spec |
| `lib/features/dashboard/widgets/letter_avatar.dart` | widget (`CircleAvatar` fallback) | static | No letter-avatar widget in Phase 1+2 (`AppIcon` falls back to `Icons.android`, not letter). RESEARCH lines 793-799 anchors the snippet |
| `test/perf/dashboard_render_test.dart` | test (perf gate) | wall-clock measurement | No perf tests in Phase 1+2. RESEARCH lines 28-30, 102-107, 142 prescribe the `Stopwatch` + `tester.pumpWidget` harness |
| `test/features/dashboard/widgets/letter_avatar_test.dart` | test (leaf widget) | static | No leaf-widget-only tests in Phase 1+2 (every widget test goes through `MaterialApp.router`). Standard `tester.pumpWidget(MaterialApp(home: LetterAvatar(label: 'I')))` is sufficient |

---

## Metadata

**Analog search scope:** `lib/`, `android/app/src/main/kotlin/`, `test/`, `pigeons/`
**Files scanned:** 56 Dart sources + 7 Kotlin sources + 23 test files = 86
**Files read for excerpts:** 18 (`block_list_dao.dart`, `block_list_dao.g.dart`, `block_list_repository.dart`, `app_database.dart`, `AppPickerHostImpl.kt`, `PermissionStatusApiImpl.kt`, `MainActivity.kt`, `app_picker_api_provider.dart`, `block_list_dao_provider.dart`, `block_list_repo_provider.dart`, `database_provider.dart`, `home_screen.dart`, `block_mode_segmented.dart`, `health_check_banner.dart`, `permission_health_provider.dart`, `_health_lifecycle_observer.dart`, `app_icon_cache_provider.dart`, `app_icon.dart`, `block_list_row.dart`, `app_router.dart`, `daily_usage_summary_table.dart`, `pause_events_table.dart`, `schedule_window.dart`, `usage_access_step.dart`, `edit_entry_screen.dart`, `empty_home_state.dart`, `app_database_test.dart`, `block_list_repo_test.dart`, `home_screen_unified_list_test.dart`, `health_banner_test.dart`, `cascade_delete_test.dart`, `permission_status_mock.dart`, `permission_health_provider_test.dart`, `app_picker_api_test.dart`, `play_invariants_test.dart`, `add_app_picker_screen.dart`, `usage_api.g.dart`, `rationale_screen.dart`)
**Pattern extraction date:** 2026-05-07
**Coverage:** 25 of 25 Phase-3 file slots have either an exact analog (19) or a role-match analog with structural transfer (3) or a documented GAP with RESEARCH.md snippet anchor (3 — period-total-ribbon, letter-avatar, perf test).

---

## PATTERN MAPPING COMPLETE

`/Users/jintanakhomwong/projects/not-to-do-list/.planning/phases/03-screen-time-dashboard/03-PATTERNS.md`
