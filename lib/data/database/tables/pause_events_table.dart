import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/tables/block_list_table.dart';

/// One row per pause-screen interaction. Single writer = Dart (PauseActivity).
class PauseEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  TextColumn get packageName => text()();
  DateTimeColumn get triggeredAt => dateTime()();
  // null = user hit Cancel before picking
  IntColumn get cooldownChosenSeconds => integer().nullable()();
  // 0 cooldown-completed, 1 cancel, 2 use-anyway
  IntColumn get outcome => integer()();

  // Indexed by (entryId, triggeredAt) for fast per-entry timeline queries.
}
