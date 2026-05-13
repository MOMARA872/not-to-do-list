import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/pause_event_dao.dart';

/// Single-writer seam for pause_events (D-13).
///
/// outcome: 0 = cooldown auto-completed; 1 = Cancel; 2 = Use anyway.
/// cooldownChosenSeconds: null only when Cancel was pressed without ever
/// tapping a cooldown chip (CONTEXT specifics).
class PauseEventRepository {
  PauseEventRepository(this._dao);

  final PauseEventDao _dao;

  Future<int> insertOutcome({
    required int entryId,
    required String packageName,
    required DateTime triggeredAt,
    int? cooldownChosenSeconds,
    required int outcome,
  }) {
    assert(outcome >= 0 && outcome <= 2, 'outcome must be 0, 1, or 2');
    return _dao.insertEvent(
      PauseEventsCompanion.insert(
        entryId: entryId,
        packageName: packageName,
        triggeredAt: triggeredAt,
        cooldownChosenSeconds: Value(cooldownChosenSeconds),
        outcome: outcome,
      ),
    );
  }
}
