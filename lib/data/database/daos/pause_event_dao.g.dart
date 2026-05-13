// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pause_event_dao.dart';

// ignore_for_file: type=lint
mixin _$PauseEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockListTable get blockList => attachedDatabase.blockList;
  $PauseEventsTable get pauseEvents => attachedDatabase.pauseEvents;
  PauseEventDaoManager get managers => PauseEventDaoManager(this);
}

class PauseEventDaoManager {
  final _$PauseEventDaoMixin _db;
  PauseEventDaoManager(this._db);
  $$BlockListTableTableManager get blockList =>
      $$BlockListTableTableManager(_db.attachedDatabase, _db.blockList);
  $$PauseEventsTableTableManager get pauseEvents =>
      $$PauseEventsTableTableManager(_db.attachedDatabase, _db.pauseEvents);
}
