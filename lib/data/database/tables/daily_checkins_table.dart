import 'package:drift/drift.dart';
import 'block_list_table.dart';

/// One self-report check-in per entry per day (STRK-03).
class DailyCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(BlockList, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get day => dateTime()();
  BoolColumn get avoided => boolean()();
  DateTimeColumn get answeredAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryId, day},
      ];
}
