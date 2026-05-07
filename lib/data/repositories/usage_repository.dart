import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';
import 'package:not_to_do_list/platform/usage_api.g.dart';

/// Domain-language wrapper around [DailyUsageSummaryDao] + [UsageApi].
///
/// Phase 3 single-seam (D-14): every dashboard surface reads through
/// [refreshIfStale] + [watchRange] — UI code NEVER calls [UsageApi.queryRange]
/// directly. This is the DASH-04 invariant point: the only place that
/// reaches the Pigeon channel is the today-only refresh path.
///
/// Mirrors [BlockListRepository] shape (DAO injection, mutating Future, watch
/// Stream). Hand-written; no @riverpod codegen.
class UsageRepository {
  UsageRepository(this._dao, this._api);

  final DailyUsageSummaryDao _dao;
  final UsageApi _api;

  /// 5-minute soft-cache for today's row (D-12). Past days are immutable.
  static const Duration _todayCacheTtl = Duration(minutes: 5);

  /// Trigger an aggregator pass IFF today's row is older than 5 minutes
  /// (or missing). Idempotent — safe to call on every initState/resume/pull.
  ///
  /// Triggered by:
  /// - DashboardScreen.initState (first refresh on dashboard mount)
  /// - WidgetsBindingObserver.AppLifecycleState.resumed
  /// - RefreshIndicator pull (forceBypassCache: true)
  ///
  /// Always queries [today, now] only — NEVER multi-day. The DASH-04 invariant
  /// (monthly view reads daily_usage_summary directly) is enforced by the
  /// shape of this method: there is no public way to ask the repo to
  /// query Pigeon for an arbitrary range.
  Future<void> refreshIfStale({
    DateTime? now,
    bool forceBypassCache = false,
  }) async {
    final n = now ?? DateTime.now();
    final today = localMidnight(n);

    // Soft-cache check (D-12). We use the canonical not-to-do package list's
    // first entry as the representative — all rows for a given midnight are
    // upserted in the same Pigeon round-trip, so any single row's
    // aggregatedAt is authoritative for the whole batch.
    if (!forceBypassCache) {
      // Probe: pick the most-likely-cached row by checking ANY row for today.
      // We need to materialize a watchRange snapshot OR add a dao method.
      // Cleanest: add a helper that returns the latest aggregatedAt for today.
      final latestRow = await _dao.watchRange(today, today).first;
      if (latestRow.isNotEmpty) {
        final mostRecent = latestRow
            .map((r) => r.aggregatedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        if (n.difference(mostRecent) <= _todayCacheTtl) {
          return; // fresh — no Pigeon call needed
        }
      }
    }

    // Stale (or pull-to-refresh). Query Pigeon for [today, now] ONLY.
    // DASH-04 invariant: never call queryRange for multi-day ranges.
    final stats = await _api.queryRange(
      today.millisecondsSinceEpoch,
      n.millisecondsSinceEpoch,
    );

    for (final s in stats) {
      await _dao.upsertDay(
        packageName: s.packageName,
        day: today,
        foregroundSeconds: s.foregroundSeconds,
        launchCount: s.launchCount,
        aggregatedAt: n,
      );
    }
  }

  /// Reactive stream over [start, end] day-bucket boundaries. Drives the
  /// dashboard's D/W/M list (DASH-02/03/04). Past days are immutable —
  /// the DAO query reads only daily_usage_summary, never raw events.
  Stream<List<DailyUsageSummaryData>> watchRange(DateTime start, DateTime end) {
    return _dao.watchRange(localMidnight(start), localMidnight(end));
  }
}
