// Phase 3 Plan 03-02 — DailyUsageSummaryDao tests.
// Wave 0 stubs flipped to passing tests when DAO landed.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';

void main() {
  group('DailyUsageSummaryDao (DASH-04)', () {
    late AppDatabase db;
    late DailyUsageSummaryDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = DailyUsageSummaryDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertDay inserts a fresh row', () async {
      final today = DateTime(2026, 5, 7);
      await dao.upsertDay(
        packageName: 'com.instagram.android',
        day: today,
        foregroundSeconds: 600,
        launchCount: 3,
        aggregatedAt: today.add(const Duration(hours: 23)),
      );
      final row = await dao.getTodayFor('com.instagram.android', today);
      expect(row, isNotNull);
      expect(row!.foregroundSeconds, 600);
      expect(row.launchCount, 3);
    });

    test('upsertDay overwrites on (packageName, day) conflict (D-14)', () async {
      final today = DateTime(2026, 5, 7);
      await dao.upsertDay(
        packageName: 'com.instagram.android',
        day: today,
        foregroundSeconds: 600,
        launchCount: 3,
        aggregatedAt: today,
      );
      await dao.upsertDay(
        packageName: 'com.instagram.android',
        day: today,
        foregroundSeconds: 1200, // doubled — mid-day refresh
        launchCount: 5,
        aggregatedAt: today.add(const Duration(minutes: 30)),
      );
      final row = await dao.getTodayFor('com.instagram.android', today);
      expect(row!.foregroundSeconds, 1200, reason: 'idempotent upsert: latest write wins');
      expect(row.launchCount, 5);
      // Verify NO duplicate row was created (UNIQUE key enforced).
      final all = await db.select(db.dailyUsageSummary).get();
      expect(all.length, 1);
    });

    test('watchRange emits ordered rows by day desc (DASH-02/03)', () async {
      final today = DateTime(2026, 5, 7);
      // Seed 3 days for the same package.
      for (var d = 0; d < 3; d++) {
        final day = today.subtract(Duration(days: d));
        await dao.upsertDay(
          packageName: 'com.instagram.android',
          day: day,
          foregroundSeconds: 100 * (d + 1),
          launchCount: 1,
          aggregatedAt: day,
        );
      }
      final rows = await dao
          .watchRange(today.subtract(const Duration(days: 6)), today)
          .first;
      expect(rows.length, 3);
      // Ordered by day desc => today first.
      expect(rows.first.day, today);
      expect(rows.last.day, today.subtract(const Duration(days: 2)));
    });

    test('getTodayFor returns null when no row exists', () async {
      final row = await dao.getTodayFor(
        'com.never.queried',
        DateTime(2026, 5, 7),
      );
      expect(row, isNull);
    });
  });
}
