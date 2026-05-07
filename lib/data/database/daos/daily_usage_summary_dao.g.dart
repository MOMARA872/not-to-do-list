// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_usage_summary_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyUsageSummaryDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyUsageSummaryTable get dailyUsageSummary =>
      attachedDatabase.dailyUsageSummary;
  DailyUsageSummaryDaoManager get managers => DailyUsageSummaryDaoManager(this);
}

class DailyUsageSummaryDaoManager {
  final _$DailyUsageSummaryDaoMixin _db;
  DailyUsageSummaryDaoManager(this._db);
  $$DailyUsageSummaryTableTableManager get dailyUsageSummary =>
      $$DailyUsageSummaryTableTableManager(
          _db.attachedDatabase, _db.dailyUsageSummary);
}
