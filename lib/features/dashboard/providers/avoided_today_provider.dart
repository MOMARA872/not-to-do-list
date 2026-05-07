import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/features/dashboard/models/avoided_today_summary.dart';

/// Reactive count of how many block_list entries the user has "avoided" so
/// far today (DASH-05 / D-08). Drives the home AvoidedTodayCard (D-09).
///
/// Rule:
/// - Apps (kind=0): today's foregroundSeconds <= streakBreakThresholdMinutes
///   * 60 (default 5min*60 = 300s). Zero foreground time counts as success.
/// - Habits (kind=1): today's daily_checkins.avoided = true. No row -> pending.
/// - Hard-block entries (LIST-08): same threshold rule — Phase 3 doesn't yet
///   have pause_events data (Phase 4 writes it).
///
/// A6 simplification (per 03-CONTEXT.md `<specifics>` and 03-RESEARCH.md
/// Open Questions §1, RESOLVED): Phase 3 thresholds against the daily-total
/// foreground_seconds for ALL entries — including scheduled (LIST-09)
/// entries. Strict schedule-window filtering is deferred to Phase 5 STRK-09
/// with no public-stream interface change. The output shape
/// (AvoidedTodaySummary) and provider type
/// (`StreamProvider.autoDispose<AvoidedTodaySummary>`) stay stable when
/// STRK-09 ships; only the internal threshold computation changes from
/// "daily total" to "in-window total" at that time.
///
/// Reactive seam: `db.tableUpdates(TableUpdateQuery.onAllTables([db.blockList,
/// db.dailyUsageSummary, db.dailyCheckins]))` per RESEARCH.md L831 (RESOLVED
/// — verbatim verified pattern; Drift 2.33 API name is tableUpdates with
/// TableUpdateQuery.onAllTables; no fallback alternatives).
final StreamProvider<AvoidedTodaySummary> avoidedTodayProvider =
    StreamProvider.autoDispose<AvoidedTodaySummary>((ref) async* {
  final db = ref.watch(databaseProvider);
  final today = localMidnight(DateTime.now());

  // RESEARCH.md L831 reactive seam: Drift 2.33 actual API is
  // tableUpdates(TableUpdateQuery.onAllTables([...])).
  await for (final _ in db.tableUpdates(
    TableUpdateQuery.onAllTables(
      [db.blockList, db.dailyUsageSummary, db.dailyCheckins],
    ),
  )) {
    final entries = await db.select(db.blockList).get();
    final usageToday = await (db.select(db.dailyUsageSummary)
          ..where((t) => t.day.equals(today)))
        .get();
    final checkinsToday = await (db.select(db.dailyCheckins)
          ..where((t) => t.day.equals(today)))
        .get();

    var succeeded = 0;
    var pending = 0;
    var failed = 0;
    for (final e in entries) {
      if (e.kind == 0) {
        // App — threshold rule. A6 simplification: Phase 3 thresholds
        // against the daily total even for scheduled entries; Phase 5
        // STRK-09 will swap in window-aware accounting without changing
        // this provider's output shape.
        final pkg = e.packageName ?? '';
        var seconds = 0;
        for (final u in usageToday) {
          if (u.packageName == pkg) seconds = u.foregroundSeconds;
        }
        final thresholdSec = e.streakBreakThresholdMinutes * 60;
        if (seconds <= thresholdSec) {
          succeeded++;
        } else {
          failed++;
        }
      } else {
        // Habit — daily_checkins.avoided. No row -> pending.
        DailyCheckin? ci;
        for (final c in checkinsToday) {
          if (c.entryId == e.id) {
            ci = c;
            break;
          }
        }
        if (ci == null) {
          pending++;
        } else if (ci.avoided) {
          succeeded++;
        } else {
          failed++;
        }
      }
    }

    yield AvoidedTodaySummary(
      total: entries.length,
      succeeded: succeeded,
      pending: pending,
      failed: failed,
    );
  }
});
