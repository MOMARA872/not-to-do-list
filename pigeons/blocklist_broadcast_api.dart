import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/blocklist_broadcast_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/BlocklistBroadcastApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'BlocklistBroadcastApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
class BlockListEntrySnapshot {
  BlockListEntrySnapshot({
    required this.entryId,
    required this.packageName,
    required this.blockMode,
    this.scheduleStartMinutes,
    this.scheduleEndMinutes,
    this.scheduleWeekdayMask,
  });

  final int entryId;
  final String packageName;
  // 'soft' or 'hard' (matches block_list.blockMode column).
  final String blockMode;
  // Schedule triple — all-null = always-on; all-non-null = active window.
  final int? scheduleStartMinutes;
  final int? scheduleEndMinutes;
  final int? scheduleWeekdayMask;
}

@HostApi()
abstract class BlocklistBroadcastApi {
  /// Fire-and-forget Dart→Kotlin call. Kotlin side translates to a
  /// LocalBroadcast with action `com.nottodo.not_to_do_list.ACTION_BLOCKLIST_UPDATED`
  /// carrying the snapshot list as JSON extra.
  ///
  /// Habit entries (no packageName) MUST be filtered out by the caller —
  /// the service only cares about app entries.
  ///
  /// PLAY-02 / D-10: this channel is the SOLE seam between Dart-owned
  /// BlockListRepository and the native AccessibilityService's in-memory
  /// Map<String, ScheduleSlice>. Service NEVER reads SQLite (Pattern 1).
  void publishBlockList(List<BlockListEntrySnapshot> entries);
}
