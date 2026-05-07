import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/usage_repo_provider.dart';
import 'package:not_to_do_list/features/dashboard/models/dash_row.dart';

/// Per-range minimum foreground seconds for non-not-to-do row inclusion
/// (D-07 — filters trivial background ticks).
const int _kIncludeThresholdSeconds = 60;

/// Joined dashboard rows: not-to-do apps (pinned to top) + non-list apps
/// with >= 60s foreground in the range, sorted by foregroundSeconds desc.
///
/// D-19 literal type:
/// `StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>`.
/// The async* generator:
///   1. awaits `repo.refreshIfStale()` once on first subscription
///      (idempotent lazy-refresh per D-14).
///   2. then re-emits on every
///      `db.tableUpdates(TableUpdateQuery.onAllTables([...]))` tick
///      — the verified Phase 2 + Phase 3 reactive seam
///      (RESEARCH.md L831, RESOLVED).
///   3. Each emission re-queries block_list + resolved-range usage
///      rows and rebuilds the joined DashRow list in-process.
///
/// Consumers (Plan 03-05) call `ref.watch(dashboardRowsProvider(range))` and
/// receive `AsyncValue<List<DashRow>>` (StreamProvider's standard surface);
/// they invoke `.when(data:..., loading:..., error:...)` to render.
final StreamProviderFamily<List<DashRow>, DashboardRange>
    dashboardRowsProvider =
    StreamProvider.autoDispose.family<List<DashRow>, DashboardRange>(
  (ref, range) async* {
    final db = ref.watch(databaseProvider);
    final repo = ref.watch(usageRepositoryProvider);

    // D-14: lazy refresh on first subscription. refreshIfStale is idempotent.
    await repo.refreshIfStale();

    // RESEARCH.md L831 reactive seam: react to ANY of these tables.
    // Drift 2.33 actual API: tableUpdates(TableUpdateQuery.onAllTables([...])).
    await for (final _ in db.tableUpdates(
      TableUpdateQuery.onAllTables([db.blockList, db.dailyUsageSummary]),
    )) {
      final r = resolveRange(range, DateTime.now());
      final entries = await db.select(db.blockList).get();
      final usage = await (db.select(db.dailyUsageSummary)
            ..where(
              (t) => t.day.isBetweenValues(
                localMidnight(r.start),
                localMidnight(r.end),
              ),
            ))
          .get();
      yield _join(entries, usage);
    }
  },
);

/// Pure function: combine block_list entries (apps only) + usage rows into
/// the sorted, highlighted DashRow list.
List<DashRow> _join(
  List<BlockListData> entries,
  List<DailyUsageSummaryData> usage,
) {
  // Sum foreground seconds across the range, per package.
  final totals = <String, int>{};
  for (final u in usage) {
    totals[u.packageName] = (totals[u.packageName] ?? 0) + u.foregroundSeconds;
  }

  final notToDoPackages = <String>{
    for (final e in entries)
      if (e.kind == 0 && e.packageName != null) e.packageName!,
  };

  final notToDoRows = <DashRow>[];
  for (final e in entries) {
    if (e.kind != 0 || e.packageName == null) continue; // habits skip
    notToDoRows.add(
      DashRow(
        isNotToDo: true,
        packageName: e.packageName!,
        displayName: e.displayName,
        foregroundSeconds: totals[e.packageName!] ?? 0,
      ),
    );
  }
  notToDoRows.sort(
    (a, b) => b.foregroundSeconds.compareTo(a.foregroundSeconds),
  );

  final otherRows = <DashRow>[];
  for (final entry in totals.entries) {
    if (notToDoPackages.contains(entry.key)) continue;
    if (entry.value < _kIncludeThresholdSeconds) continue; // D-07
    otherRows.add(
      DashRow(
        isNotToDo: false,
        packageName: entry.key,
        displayName: _packageToDisplay(entry.key),
        foregroundSeconds: entry.value,
      ),
    );
  }
  otherRows.sort((a, b) => b.foregroundSeconds.compareTo(a.foregroundSeconds));

  return [...notToDoRows, ...otherRows];
}

/// "com.example.foo" -> "foo" (last segment, capitalized).
/// Phase 3 doesn't query PackageManager.getApplicationLabel for every row —
/// ~50 IPC calls per dashboard mount. Letter-avatar fallback (Plan 03-05)
/// + last-segment label is the v1 simplification.
String _packageToDisplay(String packageName) {
  final segs = packageName.split('.');
  if (segs.isEmpty) return packageName;
  final last = segs.last;
  if (last.isEmpty) return packageName;
  return last[0].toUpperCase() + last.substring(1);
}
