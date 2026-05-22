// Plan 05-03 — GREEN: StreakRolloverService DST boundary tests.
//
// Covers: STRK-08 (DST 23h + 25h day correctness).
// Spring forward: 2026-03-08 (US DST, 23h day).
// Fall back:      2025-11-02 (US DST, 25h day).
//
// Key invariant: day stepping uses DateTime(y, m, d+1) — NOT
// cursor.add(Duration(days:1)). This prevents DST false-positives where
// a 23h day would look like a one-day gap, and a 25h day would appear to
// double-count. Verified by the grep acceptance gate.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_streak_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AppDatabase buildTestDb() => AppDatabase(NativeDatabase.memory());

ProviderContainer buildContainer({
  required AppDatabase db,
  required DateTime Function() clock,
  bool a11yOn = false,
  Future<int> Function()? bootNanosProvider,
}) {
  final mockApi = MockPermissionStatusApi();
  when(() => mockApi.isUsageAccessGranted()).thenAnswer((_) async => false);
  when(
    () => mockApi.isAccessibilityServiceEnabled(),
  ).thenAnswer((_) async => a11yOn);
  when(
    () => mockApi.isIgnoringBatteryOptimizations(),
  ).thenAnswer((_) async => false);
  when(
    () => mockApi.currentBuildFingerprint(),
  ).thenAnswer((_) async => 'fp-dst-test');
  when(() => mockApi.currentManufacturer()).thenAnswer((_) async => 'pixel');
  when(() => mockApi.openUsageAccessSettings()).thenAnswer((_) async {});
  when(() => mockApi.openAccessibilitySettings()).thenAnswer((_) async {});
  when(() => mockApi.openBatteryOptSettings()).thenAnswer((_) async {});

  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      permissionStatusApiProvider.overrideWithValue(mockApi),
      streakRolloverServiceProvider.overrideWith(
        () => StreakRolloverService(
          clock: clock,
          bootNanosProvider: bootNanosProvider,
        ),
      ),
    ],
  );
}

class MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = buildTestDb();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // STRK-08: DST spring-forward (23h day) — test_spring_forward_23h_day
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService DST spring-forward 23h day '
    '(STRK-08) — test_spring_forward_23h_day',
    () {
      test(
        'test_spring_forward_23h_day: '
        'rollover handles spring-forward 2026-03-08 without off-by-one on streak day',
        () async {
          // Spring forward: 2026-03-08 is a 23h day in US DST zones.
          // Test scenario:
          //   - lastEvaluatedDay = March 7
          //   - clockNow = March 8 10:30 local (after 04:00 boundary)
          //   - wallDelta ≈ 23h (DST spring skips 1h), bootDelta ≈ 23h
          //   - divergence ≈ 0 → NO false-positive tamper (STRK-06)
          //   - Cursor: March 7 + 1 day via DateTime(y,m,d+1) = March 8
          //     (no off-by-one from 23h day)

          // Use a local time after the 04:00 boundary to avoid ambiguity.
          final clockNow = DateTime(2026, 3, 8, 10, 30);
          // lastEvaluatedDay = March 6 midnight.
          // Cursor = March 7. March 7 is before today (March 8) → processed.
          // DST-safe step: DateTime(2026,3,7+1) = March 8 = today → loop ends.
          // Only one March 7 row written — no off-by-one from the 23h day.
          final march6 = DateTime(2026, 3, 6);
          final march7 = DateTime(2026, 3, 7);

          // Wall delta ≈ clock−lastWall (no tamper: boot≈wall for this test).
          SharedPreferences.setMockInitialValues({
            'flutter.streak_last_evaluated_day_ms': march6.millisecondsSinceEpoch,
            'flutter.streak_last_wall_clock_ms':
                march6.millisecondsSinceEpoch,
            'flutter.streak_last_boot_monotonic_ns': 0,
          });

          final entryId = await db.into(db.blockList).insert(
                BlockListCompanion.insert(
                  kind: 0,
                  packageName: const Value('com.instagram.android'),
                  displayName: 'Instagram',
                  createdAt: DateTime(2026, 1, 1),
                  updatedAt: DateTime(2026, 1, 1),
                ),
              );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: false,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          final dao = DailyStreakDao(db);

          // March 7 row should exist (it was the last evaluated day's next day
          // in the cursor loop). With no checkin + a11y off → status=2
          final march7Row = await dao.getFor(entryId, march7);
          expect(march7Row, isNotNull, reason: 'March 7 row was processed');

          // March 8 today row should be status=3 pending (not doubled)
          final march8 = DateTime(2026, 3, 8);
          final march8Row = await dao.getFor(entryId, march8);
          expect(march8Row, isNotNull, reason: 'March 8 pending row seeded');
          expect(march8Row!.status, 3, reason: 'March 8 is today — status=3 pending');

          // Crucially: NO double-counting — only one row for March 8
          // (the DST-safe DateTime constructor step didn't duplicate it).
          final allRows = await dao.watchForEntry(entryId).first;
          final march8Rows =
              allRows.where((r) => r.day.day == 8 && r.day.month == 3).toList();
          expect(march8Rows.length, 1, reason: 'no off-by-one DST duplication');
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // STRK-08: DST fall-back (25h day) — test_fall_back_25h_day
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService DST fall-back 25h day '
    '(STRK-08) — test_fall_back_25h_day',
    () {
      test(
        'test_fall_back_25h_day: '
        'rollover handles fall-back 2025-11-02 without double-counting on streak day',
        () async {
          // Fall back: 2025-11-02 is a 25h day in US DST zones.
          // Test scenario:
          //   - lastEvaluatedDay = November 1
          //   - clockNow = November 2 10:30 local (after 04:00 boundary)
          //   - wallDelta ≈ 25h (DST fall adds 1h), bootDelta ≈ 25h
          //   - divergence ≈ 0 → NO false-positive tamper
          //   - Cursor: Nov 1 + 1 day via DateTime(y,m,d+1) = Nov 2
          //     (no double-counting from 25h day)

          final clockNow = DateTime(2025, 11, 2, 10, 30);
          // lastEvaluatedDay = Oct 31 midnight.
          // Cursor = Nov 1. Nov 1 is before today (Nov 2) → processed.
          // DST-safe step: DateTime(2025,11,1+1) = Nov 2 = today → loop ends.
          // Only one Nov 1 row written — no double-counting from the 25h day.
          final oct31 = DateTime(2025, 10, 31);
          final nov1 = DateTime(2025, 11, 1);

          SharedPreferences.setMockInitialValues({
            'flutter.streak_last_evaluated_day_ms': oct31.millisecondsSinceEpoch,
            'flutter.streak_last_wall_clock_ms': oct31.millisecondsSinceEpoch,
            'flutter.streak_last_boot_monotonic_ns': 0,
          });

          final entryId = await db.into(db.blockList).insert(
                BlockListCompanion.insert(
                  kind: 0,
                  packageName: const Value('com.example.app'),
                  displayName: 'Example App',
                  createdAt: DateTime(2025, 10, 1),
                  updatedAt: DateTime(2025, 10, 1),
                ),
              );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: false,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          final dao = DailyStreakDao(db);

          // Nov 1 row should exist.
          final nov1Row = await dao.getFor(entryId, nov1);
          expect(nov1Row, isNotNull, reason: 'Nov 1 row processed');

          // Nov 2 today row should be status=3 pending.
          final nov2 = DateTime(2025, 11, 2);
          final nov2Row = await dao.getFor(entryId, nov2);
          expect(nov2Row, isNotNull, reason: 'Nov 2 pending row seeded');
          expect(nov2Row!.status, 3, reason: 'Nov 2 is today — status=3 pending');

          // No double-counting for Nov 2 (25h day safety).
          final allRows = await dao.watchForEntry(entryId).first;
          final nov2Rows =
              allRows.where((r) => r.day.day == 2 && r.day.month == 11).toList();
          expect(nov2Rows.length, 1, reason: 'no double-counting on 25h DST day');
        },
      );
    },
  );
}
