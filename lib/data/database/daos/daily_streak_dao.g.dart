// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_streak_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyStreakDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockListTable get blockList => attachedDatabase.blockList;
  $DailyStreakTable get dailyStreak => attachedDatabase.dailyStreak;
  DailyStreakDaoManager get managers => DailyStreakDaoManager(this);
}

class DailyStreakDaoManager {
  final _$DailyStreakDaoMixin _db;
  DailyStreakDaoManager(this._db);
  $$BlockListTableTableManager get blockList =>
      $$BlockListTableTableManager(_db.attachedDatabase, _db.blockList);
  $$DailyStreakTableTableManager get dailyStreak =>
      $$DailyStreakTableTableManager(_db.attachedDatabase, _db.dailyStreak);
}
