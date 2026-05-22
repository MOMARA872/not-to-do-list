// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_checkins_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyCheckinsDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockListTable get blockList => attachedDatabase.blockList;
  $DailyCheckinsTable get dailyCheckins => attachedDatabase.dailyCheckins;
  DailyCheckinsDaoManager get managers => DailyCheckinsDaoManager(this);
}

class DailyCheckinsDaoManager {
  final _$DailyCheckinsDaoMixin _db;
  DailyCheckinsDaoManager(this._db);
  $$BlockListTableTableManager get blockList =>
      $$BlockListTableTableManager(_db.attachedDatabase, _db.blockList);
  $$DailyCheckinsTableTableManager get dailyCheckins =>
      $$DailyCheckinsTableTableManager(_db.attachedDatabase, _db.dailyCheckins);
}
