import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncNotifierProviderFamily;
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';

/// Mutable draft of the editable subset of a [BlockListData]. Immutable
/// fields (id, kind, packageName) live alongside but are never mutated by
/// the screen; the repository preserves them on `updateEntry`.
class EditEntryDraft {
  const EditEntryDraft({
    required this.id,
    required this.kind,
    required this.packageName,
    required this.displayName,
    required this.reasonNote,
    required this.blockMode,
    required this.scheduleStartMinutes,
    required this.scheduleEndMinutes,
    required this.scheduleWeekdayMask,
  });

  factory EditEntryDraft.fromRow(BlockListData row) => EditEntryDraft(
        id: row.id,
        kind: row.kind,
        packageName: row.packageName,
        displayName: row.displayName,
        reasonNote: row.reasonNote,
        blockMode: row.blockMode,
        scheduleStartMinutes: row.scheduleStartMinutes,
        scheduleEndMinutes: row.scheduleEndMinutes,
        scheduleWeekdayMask: row.scheduleWeekdayMask,
      );

  final int id;
  final int kind;
  final String? packageName;
  final String displayName;
  final String reasonNote;
  final String blockMode;
  final int? scheduleStartMinutes;
  final int? scheduleEndMinutes;
  final int? scheduleWeekdayMask;

  bool get isApp => kind == 0;

  EditEntryDraft copyWith({
    String? displayName,
    String? reasonNote,
    String? blockMode,
    int? scheduleStartMinutes,
    int? scheduleEndMinutes,
    int? scheduleWeekdayMask,
    bool clearSchedule = false,
  }) =>
      EditEntryDraft(
        id: id,
        kind: kind,
        packageName: packageName,
        displayName: displayName ?? this.displayName,
        reasonNote: reasonNote ?? this.reasonNote,
        blockMode: blockMode ?? this.blockMode,
        scheduleStartMinutes: clearSchedule
            ? null
            : scheduleStartMinutes ?? this.scheduleStartMinutes,
        scheduleEndMinutes: clearSchedule
            ? null
            : scheduleEndMinutes ?? this.scheduleEndMinutes,
        scheduleWeekdayMask: clearSchedule
            ? null
            : scheduleWeekdayMask ?? this.scheduleWeekdayMask,
      );
}

class EditEntryController extends AsyncNotifier<EditEntryDraft> {
  EditEntryController(this.entryId);

  final int entryId;

  @override
  Future<EditEntryDraft> build() async {
    final repo = ref.watch(blockListRepoProvider);
    final row = await repo.getById(entryId);
    if (row == null) {
      throw StateError('No block_list row for id=$entryId');
    }
    return EditEntryDraft.fromRow(row);
  }

  void setName(String name) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData<EditEntryDraft>(current.copyWith(displayName: name));
  }

  void setReason(String reason) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData<EditEntryDraft>(current.copyWith(reasonNote: reason));
  }

  void setBlockMode(String mode) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData<EditEntryDraft>(current.copyWith(blockMode: mode));
  }

  /// Atomic schedule update — pass all-null to clear, all-non-null to set.
  /// Mixed values are not legal (the `ScheduleEditor` never emits them).
  void setSchedule({int? start, int? end, int? mask}) {
    final current = state.value;
    if (current == null) return;
    if (start == null && end == null && mask == null) {
      state = AsyncData<EditEntryDraft>(
        current.copyWith(clearSchedule: true),
      );
      return;
    }
    state = AsyncData<EditEntryDraft>(
      current.copyWith(
        scheduleStartMinutes: start,
        scheduleEndMinutes: end,
        scheduleWeekdayMask: mask,
      ),
    );
  }

  Future<void> save() async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(blockListRepoProvider);
    await repo.updateEntry(
      id: current.id,
      displayName: current.displayName,
      reasonNote: current.reasonNote,
      blockMode: current.blockMode,
      scheduleStartMinutes: current.scheduleStartMinutes,
      scheduleEndMinutes: current.scheduleEndMinutes,
      scheduleWeekdayMask: current.scheduleWeekdayMask,
    );
  }

  Future<void> delete() async {
    final current = state.value;
    if (current == null) return;
    final repo = ref.read(blockListRepoProvider);
    await repo.delete(current.id);
  }
}

final AsyncNotifierProviderFamily<EditEntryController, EditEntryDraft, int>
    editEntryControllerProvider =
    AsyncNotifierProvider.family<EditEntryController, EditEntryDraft, int>(
  EditEntryController.new,
);
