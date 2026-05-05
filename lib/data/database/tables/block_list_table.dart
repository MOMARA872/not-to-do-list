import 'package:drift/drift.dart';

/// One row per user-listed not-to-do entry (app or habit).
/// kind: 0 = app (system-tracked), 1 = habit (self-report only).
class BlockList extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => integer()(); // 0 app, 1 habit
  TextColumn get packageName => text().nullable()(); // null for habits
  TextColumn get displayName => text()();
  TextColumn get reasonNote => text().withDefault(const Constant(''))();
  IntColumn get streakBreakThresholdMinutes =>
      integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        // Same package can appear at most once for an app entry.
        // Habits (packageName null) skip uniqueness via partial index in raw SQL if needed.
        {kind, packageName},
      ];
}
