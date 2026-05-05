import 'package:drift/drift.dart';

/// Pre-aggregated per-package per-day totals (DASH-04). Read by monthly view.
/// Written by the usage-aggregation worker (Phase 3); read-only in Phase 1.
class DailyUsageSummary extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get foregroundSeconds => integer()();
  IntColumn get launchCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get aggregatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {packageName, day},
      ];
}
