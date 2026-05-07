import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
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
  daos: [BlockListDao, DailyUsageSummaryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  /// Phase 1 = schema 1. Each later phase that adds a table or column bumps
  /// this and supplies a migration step in `migration` below.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(blockList, blockList.blockMode);
            await m.addColumn(blockList, blockList.scheduleStartMinutes);
            await m.addColumn(blockList, blockList.scheduleEndMinutes);
            await m.addColumn(blockList, blockList.scheduleWeekdayMask);
          }
        },
        // SQLite's default is PRAGMA foreign_keys=OFF; without this, the
        // onDelete: KeyAction.cascade clauses on daily_streak / pause_events
        // / daily_checkins are silently inert (LIST-05). Enable it on every
        // open. Required by both production and tests.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'not_to_do_list');
  }
}
