// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block_list_dao.dart';

// ignore_for_file: type=lint
mixin _$BlockListDaoMixin on DatabaseAccessor<AppDatabase> {
  $BlockListTable get blockList => attachedDatabase.blockList;
  BlockListDaoManager get managers => BlockListDaoManager(this);
}

class BlockListDaoManager {
  final _$BlockListDaoMixin _db;
  BlockListDaoManager(this._db);
  $$BlockListTableTableManager get blockList =>
      $$BlockListTableTableManager(_db.attachedDatabase, _db.blockList);
}
