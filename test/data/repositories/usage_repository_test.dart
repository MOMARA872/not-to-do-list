// Phase 3 Plan 03-01 — Wave 0 stub for UsageRepository.refreshIfStale +
// watchRange. Implementation lands in Plan 03-04. The DASH-04 invariant
// ("monthly view never calls usageApi.queryRange") is asserted here.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

import '../../platform/usage_api_test.dart' show MockUsageApi;

void main() {
  group('UsageRepository.refreshIfStale (DASH-04)', () {
    late AppDatabase db;
    late MockUsageApi api;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = MockUsageApi();
      when(() => api.queryRange(any(), any())).thenAnswer((_) async => const []);
    });

    tearDown(() async {
      await db.close();
    });

    test('first call queries Pigeon and upserts today\'s row', () async {
      // D-12 — 5-min staleness; first call has no cached row so it queries.
    }, skip: 'Wave 2 — UsageRepository lands in Plan 03-04');

    test('second call within 5 minutes does NOT query Pigeon', () async {
      // D-12 — 5-min soft-cache.
    }, skip: 'Wave 2 — UsageRepository lands in Plan 03-04');

    test('forceBypassCache=true always queries Pigeon (pull-to-refresh)', () async {
      // D-12 — pull bypasses the cache.
    }, skip: 'Wave 2 — UsageRepository lands in Plan 03-04');

    test('refreshIfStale never queries Pigeon for >yesterday range (DASH-04)', () async {
      // DASH-04 invariant: monthly view reads daily_usage_summary only.
      // refreshIfStale only ever calls queryRange for today (or yesterday backfill).
    }, skip: 'Wave 2 — UsageRepository lands in Plan 03-04');
  });
}
