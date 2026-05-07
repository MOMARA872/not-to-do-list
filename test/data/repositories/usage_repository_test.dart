import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/data/repositories/usage_repository.dart';
import 'package:not_to_do_list/platform/usage_api.g.dart';

import '../../platform/usage_api_test.dart' show MockUsageApi;

void main() {
  setUpAll(() {
    registerFallbackValue(0);
  });

  group('UsageRepository.refreshIfStale (DASH-04 / D-12 / D-14)', () {
    late AppDatabase db;
    late DailyUsageSummaryDao dao;
    late MockUsageApi api;
    late UsageRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = DailyUsageSummaryDao(db);
      api = MockUsageApi();
      repo = UsageRepository(dao, api);
      when(() => api.queryRange(any(), any())).thenAnswer(
        (_) async => <UsagePackageStat>[
          UsagePackageStat(
            packageName: 'com.instagram.android',
            foregroundSeconds: 600,
            launchCount: 0,
          ),
        ],
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('first call queries Pigeon and upserts today\'s row', () async {
      final now = DateTime(2026, 5, 7, 14, 30);
      await repo.refreshIfStale(now: now);
      verify(() => api.queryRange(any(), any())).called(1);
      final today = DateTime(2026, 5, 7);
      final row = await dao.getTodayFor('com.instagram.android', today);
      expect(row, isNotNull);
      expect(row!.foregroundSeconds, 600);
    });

    test('second call within 5 minutes does NOT query Pigeon (D-12)', () async {
      final now1 = DateTime(2026, 5, 7, 14, 30);
      await repo.refreshIfStale(now: now1);

      final now2 = now1.add(const Duration(minutes: 4));
      await repo.refreshIfStale(now: now2);
      verify(() => api.queryRange(any(), any())).called(1); // total: still 1
    });

    test('second call after 5 minutes DOES query Pigeon', () async {
      final now1 = DateTime(2026, 5, 7, 14, 30);
      await repo.refreshIfStale(now: now1);
      final now2 = now1.add(const Duration(minutes: 6));
      await repo.refreshIfStale(now: now2);
      verify(() => api.queryRange(any(), any())).called(2);
    });

    test('forceBypassCache=true always queries Pigeon (D-12 pull)', () async {
      final now1 = DateTime(2026, 5, 7, 14, 30);
      await repo.refreshIfStale(now: now1);
      await repo.refreshIfStale(now: now1, forceBypassCache: true);
      verify(() => api.queryRange(any(), any())).called(2);
    });

    test(
        'refreshIfStale only queries [today, now] — never multi-day (DASH-04)',
        () async {
      final now = DateTime(2026, 5, 7, 14, 30);
      final today = DateTime(2026, 5, 7);
      await repo.refreshIfStale(now: now);
      verify(
        () => api.queryRange(
          today.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
        ),
      ).called(1);
    });

    test('watchRange reads from DAO only — no Pigeon call', () async {
      // Seed via DAO directly to simulate "past days from cache"
      await dao.upsertDay(
        packageName: 'com.foo',
        day: DateTime(2026, 4, 8),
        foregroundSeconds: 100,
        launchCount: 0,
        aggregatedAt: DateTime(2026, 4, 8, 23),
      );
      final stream =
          repo.watchRange(DateTime(2026, 4, 8), DateTime(2026, 5, 7));
      final rows = await stream.first;
      expect(rows.length, 1);
      verifyNever(() => api.queryRange(any(), any()));
    });
  });
}
