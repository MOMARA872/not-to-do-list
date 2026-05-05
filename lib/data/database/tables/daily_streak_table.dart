import 'package:drift/drift.dart';
import 'block_list_table.dart';

/// One row per (entry, day). Lazy-evaluated on app open per STRK-05.
class DailyStreak extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get day => dateTime()(); // anchored to home-tz LocalDate at 00:00
  IntColumn get status => integer()(); // 0 success, 1 broken, 2 incomplete-data, 3 pending
  IntColumn get source => integer()(); // 0 system-confirmed, 1 self-reported-only
  IntColumn get usageMinutesObserved =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get evaluatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryId, day}, // one streak row per entry per day
      ];
}
