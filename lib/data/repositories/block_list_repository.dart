import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';

/// Quick-add seed entry shape — kept on the repository surface so callers
/// don't have to know about Drift companions.
typedef BlockListSeed = ({int kind, String? packageName, String displayName});

/// Domain-language wrapper around [BlockListDao]. UI + onboarding code
/// depends on this seam, NOT directly on the DAO.
class BlockListRepository {
  BlockListRepository(this._dao);

  final BlockListDao _dao;

  Future<List<BlockListData>> getAll() => _dao.getAll();

  Stream<List<BlockListData>> watchAll() => _dao.watchAll();

  Future<BlockListData?> getById(int id) => _dao.getById(id);

  /// Insert one entry; returns the new row's id.
  Future<int> add({
    required int kind,
    required String displayName,
    String? packageName,
    String reasonNote = '',
    String blockMode = 'soft',
    int? scheduleStartMinutes,
    int? scheduleEndMinutes,
    int? scheduleWeekdayMask,
  }) {
    final now = DateTime.now();
    return _dao.insertEntry(
      BlockListCompanion.insert(
        kind: kind,
        packageName: Value(packageName),
        displayName: displayName,
        reasonNote: Value(reasonNote),
        createdAt: now,
        updatedAt: now,
        blockMode: Value(blockMode),
        scheduleStartMinutes: Value(scheduleStartMinutes),
        scheduleEndMinutes: Value(scheduleEndMinutes),
        scheduleWeekdayMask: Value(scheduleWeekdayMask),
      ),
    );
  }

  /// Quick-add seed (LIST-07). Pre-seeds the curated 5 common offenders
  /// regardless of installation status (CONTEXT.md: user is signaling intent,
  /// not verifying device state).
  Future<void> insertMany(List<BlockListSeed> entries) async {
    final now = DateTime.now();
    final companions = entries
        .map(
          (e) => BlockListCompanion.insert(
            kind: e.kind,
            packageName: Value(e.packageName),
            displayName: e.displayName,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
    await _dao.insertMany(companions);
  }

  /// Update by id. Bumps `updatedAt` so the home-screen sort surfaces the
  /// edited entry first (LIST-06). No-op if the row no longer exists.
  Future<void> updateEntry({
    required int id,
    required String displayName,
    required String reasonNote,
    required String blockMode,
    int? scheduleStartMinutes,
    int? scheduleEndMinutes,
    int? scheduleWeekdayMask,
  }) async {
    final existing = await _dao.getById(id);
    if (existing == null) return;
    final companion = BlockListCompanion(
      id: Value(id),
      kind: Value(existing.kind),
      packageName: Value(existing.packageName),
      displayName: Value(displayName),
      reasonNote: Value(reasonNote),
      streakBreakThresholdMinutes: Value(existing.streakBreakThresholdMinutes),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
      blockMode: Value(blockMode),
      scheduleStartMinutes: Value(scheduleStartMinutes),
      scheduleEndMinutes: Value(scheduleEndMinutes),
      scheduleWeekdayMask: Value(scheduleWeekdayMask),
    );
    await _dao.updateEntry(companion);
  }

  Future<void> delete(int id) => _dao.deleteEntryById(id);
}
