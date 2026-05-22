import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/schedule/schedule_window.dart';
import 'package:not_to_do_list/domain/schedule/streak_day.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';

/// Result type returned by [pendingCheckinsTodayProvider].
///
/// `pending` = entries that have no check-in row for today.
/// `answered` = entries that have already been answered today (show as locked).
typedef CheckinTodayResult = ({
  List<BlockListData> pending,
  List<({BlockListData entry, DailyCheckin answer})> answered,
});

/// FutureProvider that reads all block_list entries, filters by STRK-09
/// weekday-mask, and splits into pending vs. already-answered buckets for
/// today.
///
/// Schedule filter (STRK-09): an entry with a non-null schedule is only
/// included when today's weekday is in-mask. Out-of-mask entries are dormant
/// and not displayed. Always-on entries (schedule null) are always included.
///
/// Uses `streakDayFor` to derive "today" anchor consistent with rollover
/// engine.
final FutureProvider<CheckinTodayResult> pendingCheckinsTodayProvider =
    FutureProvider<CheckinTodayResult>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = ref.watch(dailyCheckinsDaoProvider);

  // Use the streak-day boundary (04:00 local) as "today" anchor.
  final today = streakDayFor(DateTime.now());
  final nowLocal = DateTime.now().toLocal();

  final allEntries = await db.blockListDao.getAll();

  final pending = <BlockListData>[];
  final answered = <({BlockListData entry, DailyCheckin answer})>[];

  for (final entry in allEntries) {
    // STRK-09 weekday-mask filter: if entry has a schedule, check if today's
    // weekday is in-mask. Entries without a schedule are always included.
    final hasSched = entry.scheduleStartMinutes != null &&
        entry.scheduleEndMinutes != null &&
        entry.scheduleWeekdayMask != null;

    if (hasSched) {
      final start = entry.scheduleStartMinutes!;
      final end = entry.scheduleEndMinutes!;
      final mask = entry.scheduleWeekdayMask!;

      // Determine if today's weekday is in-mask by testing a time in the
      // middle of the schedule window (same-day) or 30 min after start
      // (cross-midnight). We only care about the weekday bit, not the
      // time-of-day portion.
      final testMinutes =
          start <= end ? (start + end) ~/ 2 : start + 30;
      final testHour = testMinutes ~/ 60;
      final testMin = testMinutes % 60;
      final testTime = DateTime(
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
        testHour,
        testMin,
      );
      final inMask = isInScheduleWindow(
        now: testTime,
        startMinutes: start,
        endMinutes: end,
        weekdayMask: mask,
      );
      if (!inMask) {
        // This weekday is not in the entry's schedule mask — dormant today.
        continue;
      }
    }

    // Check if there's already a check-in row for this entry today.
    final existingCheckin = await dao.getFor(entry.id, today);
    if (existingCheckin == null) {
      pending.add(entry);
    } else {
      answered.add((entry: entry, answer: existingCheckin));
    }
  }

  // Sort by entry.id asc for stable ordering.
  pending.sort((a, b) => a.id.compareTo(b.id));
  answered.sort((a, b) => a.entry.id.compareTo(b.entry.id));

  return (pending: pending, answered: answered);
});

/// Transient state provider tracking unsaved Yes/No answers for the current
/// /checkin session. Keys are entry IDs; values are the chosen bool answer.
final StateProvider<Map<int, bool>> checkinAnswersProvider =
    StateProvider<Map<int, bool>>((_) => <int, bool>{});
