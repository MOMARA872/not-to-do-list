import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:not_to_do_list/data/database/app_database.dart'
    show DailyStreakData;
import 'package:not_to_do_list/data/database/daos/daily_checkins_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_streak_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/schedule/streak_day.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service.dart';

/// Provider for [DailyCheckinsDao].
final Provider<DailyCheckinsDao> dailyCheckinsDaoProvider =
    Provider<DailyCheckinsDao>((ref) {
  return ref.watch(databaseProvider).dailyCheckinsDao;
});

/// Provider for [DailyStreakDao].
final Provider<DailyStreakDao> dailyStreakDaoProvider =
    Provider<DailyStreakDao>((ref) {
  return ref.watch(databaseProvider).dailyStreakDao;
});

/// Provider for [StreakRolloverService].
final AsyncNotifierProvider<StreakRolloverService, void>
    streakRolloverServiceProvider =
    AsyncNotifierProvider<StreakRolloverService, void>(
  StreakRolloverService.new,
);

/// Record shape for the streak badge — locked in Wave 2.
///
/// `breakDetectedToday` is computed by checking the most recently finalized
/// streak row for [entryId]: if its `status == 1 broken` AND its `evaluatedAt`
/// is within the last 24 h, return true; else false.
///
/// Plan 05-07 consumes this field for the D-05 strikethrough render path
/// without mutating the provider.
///
/// Shape: `({int current, int longest, bool breakDetectedToday})`
// ignore: lines_longer_than_80_chars
final FutureProviderFamily<({int current, int longest, bool breakDetectedToday}), int>
    streakBadgeProvider = FutureProvider.autoDispose.family<
        ({int current, int longest, bool breakDetectedToday}), int>(
  (ref, entryId) async {
    final dao = ref.watch(dailyStreakDaoProvider);
    final current = await dao.getCurrentStreakFor(entryId);
    final longest = await dao.getLongestStreakFor(entryId);

    // Determine break-detected-today.
    final today = streakDayFor(DateTime.now());
    DailyStreakData? latestFinalized;

    // Try today's row first.
    final todayRow = await dao.getFor(entryId, today);
    if (todayRow != null && todayRow.status != 3) {
      latestFinalized = todayRow;
    }

    if (latestFinalized == null) {
      // Fall back to the most recent finalized row via the all-time stream.
      final allRows = await dao.watchForEntry(entryId).first;
      for (final row in allRows) {
        if (row.status != 3) {
          latestFinalized = row;
          break;
        }
      }
    }

    final breakDetectedToday = latestFinalized != null &&
        latestFinalized.status == 1 &&
        DateTime.now().difference(latestFinalized.evaluatedAt).inHours < 24;

    return (
      current: current,
      longest: longest,
      breakDetectedToday: breakDetectedToday,
    );
  },
);

/// Reactive history stream for [entryId] — last 30 calendar days, day asc.
final StreamProviderFamily<List<DailyStreakData>, int> streakHistoryProvider =
    StreamProvider.autoDispose.family<List<DailyStreakData>, int>(
  (ref, entryId) {
    final dao = ref.watch(dailyStreakDaoProvider);
    return dao.watchHistoryFor(entryId);
  },
);
