import 'package:drift/drift.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

/// Quick-add seed entry shape — kept on the repository surface so callers
/// don't have to know about Drift companions.
typedef BlockListSeed = ({int kind, String? packageName, String displayName});

/// Domain-language wrapper around [BlockListDao]. UI + onboarding code
/// depends on this seam, NOT directly on the DAO.
class BlockListRepository {
  BlockListRepository(this._dao, [this._broadcaster]);

  final BlockListDao _dao;

  /// Optional broadcaster — null in Phase 2 tests that don't care about the
  /// broadcast side effect. In production always non-null (T-4-04-04 accept).
  final BlocklistBroadcastApi? _broadcaster;

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
  }) async {
    final now = DateTime.now();
    final id = await _dao.insertEntry(
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
    await _publishCurrent();
    return id;
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
    await _publishCurrent();
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
    await _publishCurrent();
  }

  Future<void> delete(int id) async {
    await _dao.deleteEntryById(id);
    await _publishCurrent();
  }

  /// Re-publish the current block list — called by MainActivity.onResume so
  /// the AccessibilityService's in-memory map is refreshed after a settings
  /// round-trip. D-10.
  Future<void> republishCurrent() => _publishCurrent();

  /// Reads the current app-only block list and fires publishBlockList.
  /// Habit entries (kind == 1, packageName == null) are filtered out —
  /// the service only evaluates app launches, not self-report habits.
  /// No-op when _broadcaster is null (test ergonomics — T-4-04-04 accept).
  Future<void> _publishCurrent() async {
    if (_broadcaster == null) return;
    final all = await _dao.getAll();
    final snapshots = all
        .where((e) => e.kind == 0 && e.packageName != null)
        .map(
          (e) => BlockListEntrySnapshot(
            entryId: e.id,
            packageName: e.packageName!,
            blockMode: e.blockMode,
            scheduleStartMinutes: e.scheduleStartMinutes,
            scheduleEndMinutes: e.scheduleEndMinutes,
            scheduleWeekdayMask: e.scheduleWeekdayMask,
          ),
        )
        .toList();
    await _broadcaster.publishBlockList(snapshots);
  }
}
