import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/tables/pause_events_table.dart';

part 'pause_event_dao.g.dart';

/// Drift DAO for the [PauseEvents] table — single-writer seam (D-13).
///
/// Plan 04-07's PauseController is the ONLY caller in v1.
/// No read methods here — cumulativeTotalsProvider reads via raw SQL.
@DriftAccessor(tables: [PauseEvents])
class PauseEventDao extends DatabaseAccessor<AppDatabase>
    with _$PauseEventDaoMixin {
  PauseEventDao(super.db);

  /// Insert one pause_events row. Returns the new row id.
  Future<int> insertEvent(PauseEventsCompanion entry) =>
      into(pauseEvents).insert(entry);
}
