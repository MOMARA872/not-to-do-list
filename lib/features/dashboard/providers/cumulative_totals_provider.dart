import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/features/dashboard/models/cumulative_totals_summary.dart';

/// Reactive cumulative totals for the home CumulativeTotalsCard (DASH-06 /
/// D-10 / D-11). Aggregates pause_events:
///   COUNT(*)                                 -> launchesBlocked
///   COALESCE(SUM(cooldown_chosen_seconds),0) -> timeAvoidedSeconds
/// over outcome IN (0, 1):
///   0 = cooldown-completed (counts as avoided)
///   1 = cancel             (counts as avoided)
///   2 = use-anyway         (does NOT count — Pitfall #6)
///
/// Phase 3 starts at {0, 0} because pause_events is empty until Phase 4
/// ships PauseActivity (D-11) — that is the expected and correct state.
/// Phase 3 is read-only on pause_events; Phase 4 is the writer.
///
/// Reactive seam: `db.tableUpdates(TableUpdateQuery.onAllTables([...]))`
/// per RESEARCH.md L831 (RESOLVED — Drift 2.33 API; no fallback
/// alternatives).
final StreamProvider<CumulativeTotalsSummary> cumulativeTotalsProvider =
    StreamProvider.autoDispose<CumulativeTotalsSummary>((ref) async* {
  final db = ref.watch(databaseProvider);
  // RESEARCH.md L831 reactive seam: Drift 2.33 actual API is
  // tableUpdates(TableUpdateQuery.onAllTables([...])).
  await for (final _ in db.tableUpdates(
    TableUpdateQuery.onAllTables([db.pauseEvents]),
  )) {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS n, '
          'COALESCE(SUM(cooldown_chosen_seconds), 0) AS s '
          'FROM pause_events '
          'WHERE outcome IN (0, 1)',
        )
        .getSingle();
    yield CumulativeTotalsSummary(
      launchesBlocked: row.read<int>('n'),
      timeAvoidedSeconds: row.read<int>('s'),
    );
  }
});
