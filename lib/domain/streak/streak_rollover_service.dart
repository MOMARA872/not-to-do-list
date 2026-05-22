import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_checkins_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_streak_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/domain/schedule/streak_day.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pure-Dart streak rollover engine (STRK-02, STRK-04, STRK-05, STRK-06,
/// STRK-08, STRK-09).
///
/// Designed as an [AsyncNotifier] so it can be triggered from
/// [AppLifecycleState.resumed] and cold-open (Plan 05-07 wires the observer).
/// The notifier does not auto-evaluate on build — callers invoke [rollover].
///
/// Constructor accepts an optional [clock] and [bootNanosProvider] for
/// deterministic test control (CLAUDE.md Karpathy "Simplicity First" — avoid
/// global mocking). The [bootNanosProvider] defaults to returning 0 until
/// Plan 05-04 wires the real Pigeon call.
class StreakRolloverService extends AsyncNotifier<void> {
  StreakRolloverService({
    DateTime Function()? clock,
    Future<int> Function()? bootNanosProvider,
  })  : _clock = clock ?? DateTime.now,
        _bootNanosProvider = bootNanosProvider ?? (() async => 0);

  final DateTime Function() _clock;
  final Future<int> Function() _bootNanosProvider;

  // Soft-cache: last call timestamp. Two calls within 60s skip re-evaluation.
  DateTime? _lastCalled;

  @override
  Future<void> build() async {}

  /// Roll over all completed days since the last evaluation.
  ///
  /// Call from [AppLifecycleState.resumed] and cold-open. Idempotent —
  /// repeated calls within 60 s are no-ops (soft-cache 60s).
  Future<void> rollover() async {
    final now = _clock();

    // Soft-cache 60s — successive calls inside the window return immediately.
    if (_lastCalled != null &&
        now.difference(_lastCalled!).inSeconds < 60) { // soft-cache 60s
      return;
    }
    _lastCalled = now;

    final prefs = await SharedPreferences.getInstance();

    // 1. Read clocks.
    final nowWallMs = now.millisecondsSinceEpoch;
    // bootMonotonicNanos() is added to PermissionStatusApi in Plan 05-04.
    // Until then, _bootNanosProvider defaults to 0.
    final nowBootNs = await _bootNanosProvider();
    final lastWallMs = prefs.getInt(StreakKeys.lastWallClockMs) ?? nowWallMs;
    final lastBootNs = prefs.getInt(StreakKeys.lastBootMonotonicNs) ?? nowBootNs;

    // 2. Clock-tamper detection (STRK-06).
    // If |wallDelta - bootDeltaMs| > 24h → user tampered.
    // Threshold: Duration(hours: 24).inMilliseconds.
    final wallDelta = nowWallMs - lastWallMs;
    final bootDeltaMs = (nowBootNs - lastBootNs) ~/ 1000000;
    final divergenceMs = (wallDelta - bootDeltaMs).abs();
    final clockTampered =
        divergenceMs > const Duration(hours: 24).inMilliseconds; // 24h tamper threshold

    // 3. Compute today's streak day (STRK-08 — 04:00 local boundary).
    final todayStreakDay = streakDayFor(now);

    // 4. If already evaluated today, only refresh the pending row.
    final lastEvaluatedMs = prefs.getInt(StreakKeys.lastEvaluatedStreakDay);
    if (lastEvaluatedMs != null &&
        lastEvaluatedMs == todayStreakDay.millisecondsSinceEpoch) {
      await _refreshPendingTodayRows(todayStreakDay);
      return;
    }

    // 5. Roll over every completed day between lastEvaluatedDay+1 and today-1.
    final blockListDao = ref.read(_blockListDaoInternalProvider);
    final dailyStreakDao = ref.read(_dailyStreakDaoInternalProvider);
    final dailyCheckinsDao = ref.read(_dailyCheckinsDaoInternalProvider);
    final dailyUsageSummaryDao =
        ref.read(_dailyUsageSummaryDaoInternalProvider);
    final entries = await blockListDao.getAll();
    final threshold = prefs.getInt(StreakKeys.streakThresholdMinutes) ?? 5;

    // Determine the cursor start point.
    DateTime cursor;
    if (lastEvaluatedMs != null) {
      final lastDay = DateTime.fromMillisecondsSinceEpoch(lastEvaluatedMs);
      // DST-safe day step: DateTime constructor, NOT add(Duration(days: 1)).
      cursor = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    } else {
      // First ever rollover: process only yesterday.
      cursor = DateTime(
        todayStreakDay.year,
        todayStreakDay.month,
        todayStreakDay.day - 1,
      );
    }

    // Backfill cap (RESEARCH §10 R-7): cap at 30 days.
    // Days beyond the cap are written status=2 incomplete-data.
    final gapDays = todayStreakDay.difference(cursor).inDays;
    if (gapDays > 30) {
      final capStart = DateTime(
        todayStreakDay.year,
        todayStreakDay.month,
        todayStreakDay.day - 30,
      );
      var gapCursor = cursor;
      while (gapCursor.isBefore(capStart)) {
        for (final entry in entries) {
          final entryCreatedDay = streakDayFor(entry.createdAt);
          if (gapCursor.isBefore(entryCreatedDay)) continue;
          await dailyStreakDao.upsert(
            entryId: entry.id,
            day: gapCursor,
            status: 2, // incomplete-data (beyond 30-day backfill cap)
            source: 0,
            usageMinutesObserved: 0,
            evaluatedAt: _clock(),
          );
        }
        // DST-safe day step: DateTime constructor, NOT add(Duration(days: 1)).
        gapCursor =
            DateTime(gapCursor.year, gapCursor.month, gapCursor.day + 1);
      }
      cursor = capStart;
    }

    // Per-day loop — processes cursor up to (but not including) today.
    while (cursor.isBefore(todayStreakDay)) {
      for (final entry in entries) {
        final entryCreatedDay = streakDayFor(entry.createdAt);
        if (cursor.isBefore(entryCreatedDay)) continue;

        // 5a. Clock tamper → status=2 incomplete-data, source=0.
        if (clockTampered) {
          await dailyStreakDao.upsert(
            entryId: entry.id,
            day: cursor,
            status: 2, // incomplete-data (tamper flag)
            source: 0,
            usageMinutesObserved: 0,
            evaluatedAt: _clock(),
          );
          continue;
        }

        // 5b. Gather observations.
        final usageMinutes = await _usageMinutesForEntry(
          entry,
          cursor,
          dailyUsageSummaryDao,
        );
        final checkin = await dailyCheckinsDao.getFor(entry.id, cursor);
        final a11yWasOnForDay = await _a11yWasOnFor();

        // 5c. Compute (status, source) via the 2x2 matrix.
        final (status, source) = _resolveDay(
          usageMinutes: usageMinutes,
          threshold: threshold,
          checkinAvoided: checkin?.avoided,
          a11yWasOn: a11yWasOnForDay,
        );

        await dailyStreakDao.upsert(
          entryId: entry.id,
          day: cursor,
          status: status,
          source: source,
          usageMinutesObserved: usageMinutes,
          evaluatedAt: _clock(),
        );
      }

      // DST-safe day step: DateTime constructor, NOT add(Duration(days: 1)).
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
    }

    // 6. Seed today's row as status=3 pending (upsertIfAbsent preserves
    //    any row already evaluated for today).
    for (final entry in entries) {
      await dailyStreakDao.upsertIfAbsent(
        entryId: entry.id,
        day: todayStreakDay,
        status: 3, // pending
        source: 0,
        usageMinutesObserved: 0,
        evaluatedAt: _clock(),
      );
    }

    // 7. Persist new state.
    await prefs.setInt(StreakKeys.lastWallClockMs, nowWallMs);
    await prefs.setInt(StreakKeys.lastBootMonotonicNs, nowBootNs);
    await prefs.setInt(
      StreakKeys.lastEvaluatedStreakDay,
      todayStreakDay.millisecondsSinceEpoch,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _refreshPendingTodayRows(DateTime todayStreakDay) async {
    final entries =
        await ref.read(_blockListDaoInternalProvider).getAll();
    final dailyStreakDao = ref.read(_dailyStreakDaoInternalProvider);
    for (final entry in entries) {
      await dailyStreakDao.upsertIfAbsent(
        entryId: entry.id,
        day: todayStreakDay,
        status: 3,
        source: 0,
        usageMinutesObserved: 0,
        evaluatedAt: _clock(),
      );
    }
  }

  /// 2x2 status/source matrix per RESEARCH §4 / D-07.
  ///
  /// Priority order:
  ///   1. Broken by system data (a11y on AND usage > threshold)
  ///   2. Broken by self-report (checkinAvoided == false)
  ///   3. Success with checkin (checkinAvoided == true)
  ///   4. No checkin + a11y on → system-confirmed success
  ///   5. No checkin + a11y off → incomplete-data
  (int status, int source) _resolveDay({
    required int usageMinutes,
    required int threshold,
    required bool? checkinAvoided,
    required bool a11yWasOn,
  }) {
    // 1. Broken by system data (a11y on confirmed the usage).
    if (a11yWasOn && usageMinutes > threshold) {
      return (1, 0); // broken, system-confirmed
    }
    // 2. Broken by self-report.
    if (checkinAvoided == false) {
      return (1, a11yWasOn ? 0 : 1); // broken, source varies
    }
    // 3. Success — user said they avoided.
    if (checkinAvoided == true) {
      return (0, a11yWasOn ? 0 : 1); // success, source varies
    }
    // 4. No check-in but a11y was tracking → success, system-confirmed.
    if (a11yWasOn) {
      return (0, 0); // success, system-confirmed
    }
    // 5. No system data AND no check-in → incomplete-data.
    return (2, 0);
  }

  /// Returns usage minutes for [entry] on [streakDayMidnight].
  ///
  /// Habit entries (packageName == null) return 0 per RESEARCH §10 R-8.
  Future<int> _usageMinutesForEntry(
    BlockListData entry,
    DateTime streakDayMidnight,
    DailyUsageSummaryDao dailyUsageSummaryDao,
  ) async {
    if (entry.packageName == null) return 0; // habit — no usage data (R-8)

    final summary = await dailyUsageSummaryDao.getTodayFor(
      entry.packageName!, // non-null asserted above
      streakDayMidnight,
    );
    if (summary == null) return 0;

    return summary.foregroundSeconds ~/ 60;
  }

  /// Conservative proxy: is the AccessibilityService currently enabled?
  ///
  /// v1 implementation uses current state as a proxy. Per-day accuracy
  /// deferred to v1.x when an `a11y_enabled_since` timestamp is persisted.
  /// Conservative: when a11y is off today, days with no check-in fall to
  /// status=2 incomplete-data (honest framing — T-05-10).
  Future<bool> _a11yWasOnFor() async {
    return ref
        .read(permissionStatusApiProvider)
        .isAccessibilityServiceEnabled();
  }
}

// ---------------------------------------------------------------------------
// Internal DAO providers (backing seams for StreakRolloverService)
// ---------------------------------------------------------------------------

final Provider<BlockListDao> _blockListDaoInternalProvider =
    Provider<BlockListDao>((ref) {
  return ref.watch(databaseProvider).blockListDao;
});

final Provider<DailyUsageSummaryDao> _dailyUsageSummaryDaoInternalProvider =
    Provider<DailyUsageSummaryDao>((ref) {
  return ref.watch(databaseProvider).dailyUsageSummaryDao;
});

final Provider<DailyStreakDao> _dailyStreakDaoInternalProvider =
    Provider<DailyStreakDao>((ref) {
  return ref.watch(databaseProvider).dailyStreakDao;
});

final Provider<DailyCheckinsDao> _dailyCheckinsDaoInternalProvider =
    Provider<DailyCheckinsDao>((ref) {
  return ref.watch(databaseProvider).dailyCheckinsDao;
});

// ---------------------------------------------------------------------------
// Public re-exports for consumers / tests that override specific DAOs
// ---------------------------------------------------------------------------

/// Public [BlockListDao] provider (re-exported from internal seam).
final Provider<BlockListDao> blockListDaoProvider =
    _blockListDaoInternalProvider;

/// Public [DailyUsageSummaryDao] provider (re-exported from internal seam).
final Provider<DailyUsageSummaryDao> dailyUsageSummaryDaoProvider =
    _dailyUsageSummaryDaoInternalProvider;
