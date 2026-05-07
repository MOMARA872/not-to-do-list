// Phase 3 Plan 03-01 — Wave 0 stub for DailyUsageSummaryDao.
// Implementation lands in Plan 03-02.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

void main() {
  group('DailyUsageSummaryDao (DASH-04)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('upsertDay inserts a fresh row', () async {
      // Wave 1 (Plan 03-02) ships DailyUsageSummaryDao + the build_runner
      // codegen that registers the dao on AppDatabase.
    }, skip: 'Wave 1 — DailyUsageSummaryDao lands in Plan 03-02');

    test('upsertDay overwrites on (packageName, day) conflict', () async {
      // D-14 idempotent upsert — verified Wave 1.
    }, skip: 'Wave 1 — DailyUsageSummaryDao lands in Plan 03-02');

    test('watchRange emits ordered rows by day desc', () async {
      // DASH-02/03/04 — verified Wave 1.
    }, skip: 'Wave 1 — DailyUsageSummaryDao lands in Plan 03-02');
  });
}
