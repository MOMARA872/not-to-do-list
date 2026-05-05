import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:not_to_do_list/data/database/tables/block_list_table.dart';
import 'package:not_to_do_list/data/database/tables/daily_checkins_table.dart';
import 'package:not_to_do_list/data/database/tables/daily_streak_table.dart';
import 'package:not_to_do_list/data/database/tables/daily_usage_summary_table.dart';
import 'package:not_to_do_list/data/database/tables/pause_events_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BlockList,
    DailyStreak,
    PauseEvents,
    DailyCheckins,
    DailyUsageSummary,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Phase 1 = schema 1. Each later phase that adds a table or column bumps
  /// this and supplies a migration step in `migration` below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // No upgrades yet — schema is at version 1.
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'not_to_do_list');
  }
}
