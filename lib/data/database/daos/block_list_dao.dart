import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/tables/block_list_table.dart';

part 'block_list_dao.g.dart';

/// Drift DAO for the [BlockList] table — typed CRUD over the v2 schema
/// landed by Plan 02-02. Phase 2 sort key is `updatedAt` desc; Phase 4/5
/// will join `pause_events.last_pause_event_time` and
/// `daily_checkins.last_check_in_time` (CONTEXT.md "last activity desc").
@DriftAccessor(tables: [BlockList])
class BlockListDao extends DatabaseAccessor<AppDatabase>
    with _$BlockListDaoMixin {
  BlockListDao(super.attachedDatabase);

  /// All entries sorted by `updatedAt` desc.
  Future<List<BlockListData>> getAll() {
    return (select(blockList)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Stream variant for reactive home-screen rebinding.
  Stream<List<BlockListData>> watchAll() {
    return (select(blockList)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<BlockListData?> getById(int id) {
    return (select(blockList)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert one entry; returns the new row id.
  Future<int> insertEntry(BlockListCompanion entry) {
    return into(blockList).insert(entry);
  }

  /// Batch insert for quick-add seeding (LIST-07). Drift's [batch] does not
  /// surface the inserted ids; Phase 2 callers do not need them.
  Future<void> insertMany(List<BlockListCompanion> entries) async {
    await batch((b) {
      for (final e in entries) {
        b.insert(blockList, e);
      }
    });
  }

  /// Replace by primary key. Returns true iff a row was updated.
  Future<bool> updateEntry(BlockListCompanion entry) {
    return update(blockList).replace(entry);
  }

  Future<int> deleteEntryById(int id) {
    return (delete(blockList)..where((t) => t.id.equals(id))).go();
  }
}
