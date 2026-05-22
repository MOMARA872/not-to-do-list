// Plan 05-03 — GREEN: StreakRolloverService tests.
//
// Covers: STRK-02 (break when usage exceeds threshold),
//         STRK-04 (2x2 source resolution matrix),
//         STRK-05 (today=pending row, idempotent),
//         STRK-06 (clock-tamper > 24h → status=2 incomplete-data),
//         STRK-09 (scheduled-entry window anchoring),
//         D-12 (soft-cache 60s idempotency).
//
// All skips removed — Plan 05-03 fills all test bodies.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_checkins_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_streak_dao.dart';
import 'package:not_to_do_list/data/database/daos/daily_usage_summary_dao.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../_fixtures/streak_fixture.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build an in-memory [AppDatabase] for testing.
AppDatabase buildTestDb() => AppDatabase(NativeDatabase.memory());

/// Build a [ProviderContainer] with an in-memory DB and a custom clock.
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
  ).thenAnswer((_) async => 'fp-test');
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

/// Seed a [BlockList] entry with the given package name.
/// Returns the new entry's id.
Future<int> seedEntry(
  AppDatabase db, {
  String? packageName = 'com.instagram.android',
  String displayName = 'Instagram',
  int kind = 0,
  int? scheduleStartMinutes,
  int? scheduleEndMinutes,
  int? scheduleWeekdayMask,
  DateTime? createdAt,
}) async {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return db.into(db.blockList).insert(
        BlockListCompanion.insert(
          kind: kind,
          packageName: packageName != null ? Value(packageName) : const Value(null),
          displayName: displayName,
          createdAt: now,
          updatedAt: now,
          scheduleStartMinutes: scheduleStartMinutes != null
              ? Value(scheduleStartMinutes)
              : const Value(null),
          scheduleEndMinutes: scheduleEndMinutes != null
              ? Value(scheduleEndMinutes)
              : const Value(null),
          scheduleWeekdayMask: scheduleWeekdayMask != null
              ? Value(scheduleWeekdayMask)
              : const Value(null),
        ),
      );
}

/// Seed a daily usage summary row.
Future<void> seedUsage(
  AppDatabase db, {
  required String packageName,
  required DateTime day,
  required int foregroundSeconds,
}) async {
  final dao = DailyUsageSummaryDao(db);
  await dao.upsertDay(
    packageName: packageName,
    day: day,
    foregroundSeconds: foregroundSeconds,
    launchCount: 1,
    aggregatedAt: day,
  );
}

/// Seed a daily checkin row.
Future<void> seedCheckin(
  AppDatabase db, {
  required int entryId,
  required DateTime day,
  required bool avoided,
}) async {
  final dao = DailyCheckinsDao(db);
  await dao.upsert(
    entryId: entryId,
    day: day,
    avoided: avoided,
    answeredAt: day,
  );
}

/// Returns the streak row for (entryId, day), or null.
Future<DailyStreakData?> getRow(
  AppDatabase db, {
  required int entryId,
  required DateTime day,
}) async {
  final dao = DailyStreakDao(db);
  return dao.getFor(entryId, day);
}

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
  // STRK-02: Break when usage exceeds threshold
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService breaks when usage exceeds threshold '
    '(STRK-02) — test_breaks_when_usage_exceeds_threshold',
    () {
      test(
        'test_breaks_when_usage_exceeds_threshold: '
        'status=1 broken when foreground usage > threshold',
        () async {
          // yesterday (from the clock's POV)
          final clockNow = DateTime(2026, 5, 15, 10, 0);
          final yesterday = DateTime(2026, 5, 14); // local midnight

          final entryId = await seedEntry(db);
          // 6 min usage, threshold=5 → broken
          await seedUsage(
            db,
            packageName: 'com.instagram.android',
            day: yesterday,
            foregroundSeconds: 6 * 60,
          );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          // yesterday's row should be status=1 broken, source=0 (a11y on)
          final row = await getRow(db, entryId: entryId, day: yesterday);
          expect(row, isNotNull);
          expect(row!.status, 1, reason: 'broken by system data');
          expect(row.source, 0, reason: 'system-confirmed');
        },
      );

      test(
        'test_breaks_when_usage_exceeds_threshold: '
        'status=0 success when foreground usage <= threshold',
        () async {
          final clockNow = DateTime(2026, 5, 15, 10, 0);
          final yesterday = DateTime(2026, 5, 14);

          final entryId = await seedEntry(db);
          // 3 min usage, threshold=5 → success
          await seedUsage(
            db,
            packageName: 'com.instagram.android',
            day: yesterday,
            foregroundSeconds: 3 * 60,
          );
          // a11y on but usage <= threshold → success
          await seedCheckin(
            db,
            entryId: entryId,
            day: yesterday,
            avoided: true,
          );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          final row = await getRow(db, entryId: entryId, day: yesterday);
          expect(row, isNotNull);
          expect(row!.status, 0, reason: 'success — usage <= threshold');
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // STRK-04: 2x2 source resolution matrix
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService 2x2 source resolution matrix '
    '(STRK-04) — test_source_resolution_matrix',
    () {
      for (final cell in kSourceResolutionMatrix) {
        test(
          'test_source_resolution_matrix: '
          'usageMinutes=${cell.usageMinutes} '
          'checkinAvoided=${cell.checkinAvoided} '
          'a11yWasOn=${cell.a11yWasOn} '
          '→ status=${cell.expectedStatus} source=${cell.expectedSource}',
          () async {
            final clockNow = DateTime(2026, 5, 15, 10, 0);
            final yesterday = DateTime(2026, 5, 14);

            final entryId = await seedEntry(db);

            if (cell.usageMinutes > 0) {
              await seedUsage(
                db,
                packageName: 'com.instagram.android',
                day: yesterday,
                foregroundSeconds: cell.usageMinutes * 60,
              );
            }

            if (cell.checkinAvoided != null) {
              await seedCheckin(
                db,
                entryId: entryId,
                day: yesterday,
                avoided: cell.checkinAvoided!,
              );
            }

            final container = buildContainer(
              db: db,
              clock: () => clockNow,
              a11yOn: cell.a11yWasOn,
            );
            addTearDown(container.dispose);

            await container
                .read(streakRolloverServiceProvider.notifier)
                .rollover();

            final row = await getRow(db, entryId: entryId, day: yesterday);
            expect(row, isNotNull);
            expect(
              row!.status,
              cell.expectedStatus,
              reason: 'status for cell: $cell',
            );
            expect(
              row.source,
              cell.expectedSource,
              reason: 'source for cell: $cell',
            );
          },
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // STRK-06: Clock-tamper detection
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService clock-tamper > 24h flags status=2 '
    '(STRK-06) — test_clock_tamper_flags_status_2',
    () {
      test(
        'test_clock_tamper_flags_status_2: '
        'status=2 when |wallDelta - bootMonoDelta| > 24h',
        () async {
          // Simulate: wall advanced 49h, boot advanced 24h
          // → divergence = |49h - 24h| = 25h > 24h → tampered
          //
          // nowBootNs = 49h_in_ns (current monotonic reading via bootNanosProvider)
          // lastBootNs stored in prefs = 24h_in_ns (reading from last evaluation)
          // bootDeltaMs = (49h_in_ns - 24h_in_ns) / 1_000_000 = 25h_ms
          // wallDelta = 49h_ms (wall advanced 49h from lastWallMs)
          // divergence = |49h - 25h| = 24h → exactly 24h, NOT > 24h
          //
          // Better: nowBootNs = 24h_in_ns, lastBootNs = 0
          // bootDeltaMs = 24h (boot ran 24h since last save)
          // wallDelta = nowMs - lastWallMs = 49h (wall ran 49h since last save)
          // divergence = |49h - 24h| = 25h > 24h → tampered ✓
          final yesterday = DateTime(2026, 5, 14);
          final clockNow = DateTime(2026, 5, 15, 10, 0);

          final nowMs = clockNow.millisecondsSinceEpoch;
          final lastWallMs = nowMs - const Duration(hours: 49).inMilliseconds;
          // nowBootNs = 24h in ns (boot clock ran 24h since last save where lastBootNs=0)
          const nowBootNs = Duration.microsecondsPerHour * 24 * 1000; // 24h in ns
          SharedPreferences.setMockInitialValues({
            'flutter.streak_last_wall_clock_ms': lastWallMs,
            'flutter.streak_last_boot_monotonic_ns': 0, // last saved boot = 0
            'flutter.streak_last_evaluated_day_ms': yesterday
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
          });

          final entryId = await seedEntry(db);

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
            bootNanosProvider: () async => nowBootNs,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          // Yesterday's row should be status=2 incomplete-data (tamper flag).
          final row = await getRow(db, entryId: entryId, day: yesterday);
          expect(row, isNotNull);
          expect(row!.status, 2, reason: 'tamper: status=2 incomplete-data');
        },
      );

      test(
        'test_clock_tamper_flags_status_2: '
        'no tamper detected when clocks are consistent',
        () async {
          // wallDelta = 24h, bootDelta = 24h → divergence = 0 → no tamper
          // nowBootNs = 24h_in_ns, lastBootNs = 0
          // → bootDeltaMs = 24h_ms; wallDelta = 24h_ms → divergence = 0
          final yesterday = DateTime(2026, 5, 14);
          final clockNow = DateTime(2026, 5, 15, 10, 0);

          final nowMs = clockNow.millisecondsSinceEpoch;
          final lastWallMs = nowMs - const Duration(hours: 24).inMilliseconds;
          const nowBootNs = Duration.microsecondsPerHour * 24 * 1000; // 24h in ns
          SharedPreferences.setMockInitialValues({
            'flutter.streak_last_wall_clock_ms': lastWallMs,
            'flutter.streak_last_boot_monotonic_ns': 0,
            'flutter.streak_last_evaluated_day_ms': yesterday
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
          });

          final entryId = await seedEntry(db);
          // No usage — with a11y on and no checkin → success (fallback)
          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
            bootNanosProvider: () async => nowBootNs,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          // No tamper: row should NOT be status=2 (should be success or other)
          final row = await getRow(db, entryId: entryId, day: yesterday);
          expect(row, isNotNull);
          expect(row!.status, isNot(2), reason: 'no tamper: not incomplete-data');
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // STRK-09: Scheduled-entry window anchoring
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService scheduled-entry window anchoring '
    '(STRK-09) — test_scheduled_window_anchoring',
    () {
      test(
        'test_scheduled_window_anchoring: '
        'cross-midnight window usage belongs to start-day streak row',
        () async {
          // Monday is yesterday; window 22:00(Mon)–06:00(Tue)
          // Daily usage for Mon = 12 min, threshold 5 → broken
          final clockNow = DateTime(2026, 1, 6, 10, 0); // Tue 10:00
          final monday = DateTime(2026, 1, 5); // Mon midnight = start day

          final entryId = await seedEntry(
            db,
            scheduleStartMinutes: 22 * 60, // 22:00
            scheduleEndMinutes: 6 * 60, // 06:00
            scheduleWeekdayMask: 0x01, // Mon
          );
          // Usage on Mon = 12 min > 5 min threshold
          await seedUsage(
            db,
            packageName: 'com.instagram.android',
            day: monday,
            foregroundSeconds: 12 * 60,
          );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          // The streak row should be anchored to Monday (start day).
          final row = await getRow(db, entryId: entryId, day: monday);
          expect(row, isNotNull);
          expect(row!.status, 1, reason: 'broken by system data on Mon');
        },
      );

      test(
        'test_scheduled_window_anchoring: '
        'always-on entry attributes full-day usage to calendar day',
        () async {
          // Always-on entry (no schedule): usage on yesterday = 10 min > 5
          final clockNow = DateTime(2026, 5, 15, 10, 0);
          final yesterday = DateTime(2026, 5, 14);

          final entryId = await seedEntry(db); // no schedule fields
          await seedUsage(
            db,
            packageName: 'com.instagram.android',
            day: yesterday,
            foregroundSeconds: 10 * 60,
          );

          final container = buildContainer(
            db: db,
            clock: () => clockNow,
            a11yOn: true,
          );
          addTearDown(container.dispose);

          await container.read(streakRolloverServiceProvider.notifier).rollover();

          final row = await getRow(db, entryId: entryId, day: yesterday);
          expect(row, isNotNull);
          expect(row!.status, 1, reason: 'broken — always-on full-day usage');
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Soft-cache 60s idempotency
  // ---------------------------------------------------------------------------
  group(
    'StreakRolloverService idempotent under repeated rollover() in <60s '
    '(D-12 soft-cache)',
    () {
      test(
        'second rollover() call within 60s does not re-write rows',
        () async {
          // Use a real clock-controlled scenario. Two calls within 1s should
          // result in only one write to the DAO. We verify by checking that the
          // row count for yesterday is 1 (not duplicated), and that evaluatedAt
          // matches only the first call timestamp.
          var callCount = 0;
          // Clock advances by 1s between calls (well within 60s window).
          final timestamps = [
            DateTime(2026, 5, 15, 10, 0),
            DateTime(2026, 5, 15, 10, 0, 1), // 1 second later
          ];
          final clockNow = () {
            final t = timestamps[callCount.clamp(0, 1)];
            callCount++;
            return t;
          };

          final entryId = await seedEntry(db);
          final yesterday = DateTime(2026, 5, 14);

          final container = buildContainer(
            db: db,
            clock: clockNow,
            a11yOn: false,
          );
          addTearDown(container.dispose);

          // First call
          await container.read(streakRolloverServiceProvider.notifier).rollover();
          final row1 = await getRow(db, entryId: entryId, day: yesterday);

          // Second call (within 60s cache window)
          await container.read(streakRolloverServiceProvider.notifier).rollover();
          final row2 = await getRow(db, entryId: entryId, day: yesterday);

          // Row should exist from first call
          expect(row1, isNotNull);
          // Row unchanged from second call (same evaluatedAt from first write)
          expect(row2, isNotNull);
          expect(row2!.evaluatedAt, equals(row1!.evaluatedAt));
        },
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Additional behaviors
  // ---------------------------------------------------------------------------

  test(
    'test_today_row_status_3_pending: '
    'today\'s row gets status=3 pending after rollover',
    () async {
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      final today = DateTime(2026, 5, 15); // streak day = local midnight

      final entryId = await seedEntry(db);

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      final todayRow = await getRow(db, entryId: entryId, day: today);
      expect(todayRow, isNotNull, reason: 'today row should be seeded');
      expect(todayRow!.status, 3, reason: 'today row should be pending');
    },
  );

  test(
    'test_today_row_status_3_pending: '
    'upsertIfAbsent does not overwrite already-evaluated today row',
    () async {
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      final today = DateTime(2026, 5, 15);

      final entryId = await seedEntry(db);

      // Pre-seed today's row as status=0 (already finalized)
      final dao = DailyStreakDao(db);
      await dao.upsert(
        entryId: entryId,
        day: today,
        status: 0,
        source: 1,
        usageMinutesObserved: 0,
        evaluatedAt: clockNow,
      );

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      // Today's row should remain status=0 (not clobbered by pending row).
      final todayRow = await getRow(db, entryId: entryId, day: today);
      expect(todayRow, isNotNull);
      expect(todayRow!.status, 0, reason: 'upsertIfAbsent preserves finalized row');
    },
  );

  test(
    'test_backfill_cap_30_days_writes_incomplete: '
    'backfill cap: days beyond 30 get status=2, last 30 days processed normally',
    () async {
      // Set lastEvaluatedDay to 60 days ago → gap of 60 days.
      // Days [today-60 .. today-31] should be status=2 (beyond cap).
      // Days [today-30 .. today-1] should be processed normally.
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      final today = DateTime(2026, 5, 15);

      final capBoundary = DateTime(
        today.year,
        today.month,
        today.day - 30,
      ); // 30 days ago = first day processed normally

      final lastEvaluatedDay = today
          .subtract(const Duration(days: 61))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'flutter.streak_last_evaluated_day_ms': lastEvaluatedDay,
      });

      final entryId = await seedEntry(db);

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
        a11yOn: false,
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      // A day 45 days ago should be status=2 (beyond the 30-day cap).
      final beyondCapDay = DateTime(
        today.year,
        today.month,
        today.day - 45,
      );
      final beyondCapRow =
          await getRow(db, entryId: entryId, day: beyondCapDay);
      expect(beyondCapRow, isNotNull);
      expect(beyondCapRow!.status, 2, reason: 'day beyond 30-day cap is incomplete');

      // A day within the 30-day window should have been processed.
      // With no checkin and a11y off → status=2 incomplete-data.
      // That's fine — we just verify the row exists and was written.
      final withinCapDay = DateTime(
        today.year,
        today.month,
        today.day - 5,
      );
      final withinCapRow =
          await getRow(db, entryId: entryId, day: withinCapDay);
      expect(withinCapRow, isNotNull, reason: 'day within 30-day window should be written');
    },
  );

  test(
    'test_habit_entry_no_usage_returns_incomplete_when_no_checkin: '
    'habit entry (kind=1, packageName=null) with no checkin + a11y on → status=0',
    () async {
      // Habit entries have no usage data. With a11y on and no checkin:
      // _usageMinutesForEntry returns 0 (R-8), then _resolveDay:
      //   usage=0 <= threshold=5, no checkin, a11y on → (0, 0) success
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      final yesterday = DateTime(2026, 5, 14);

      // kind=1 (habit), packageName=null
      final entryId = await seedEntry(
        db,
        packageName: null,
        kind: 1,
        displayName: 'Morning Run',
      );

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
        a11yOn: true, // a11y on → fallback success when no checkin
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      final row = await getRow(db, entryId: entryId, day: yesterday);
      expect(row, isNotNull);
      // habit + no usage + no checkin + a11y on → success (0, 0)
      expect(row!.status, 0, reason: 'habit no checkin a11y on → success');
    },
  );

  test(
    'test_habit_entry_no_usage_returns_incomplete_when_no_checkin: '
    'habit entry with no checkin and a11y off → status=2 incomplete-data',
    () async {
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      final yesterday = DateTime(2026, 5, 14);

      final entryId = await seedEntry(
        db,
        packageName: null,
        kind: 1,
        displayName: 'Morning Run',
      );

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
        a11yOn: false, // a11y off → incomplete-data
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      final row = await getRow(db, entryId: entryId, day: yesterday);
      expect(row, isNotNull);
      // habit + no usage + no checkin + a11y off → (2, 0) incomplete-data
      expect(
        row!.status,
        2,
        reason: 'habit no checkin a11y off → status=2 incomplete-data (R-8)',
      );
    },
  );

  test(
    'rollover persists state to SharedPreferences after evaluation',
    () async {
      final clockNow = DateTime(2026, 5, 15, 10, 0);
      await seedEntry(db);

      final container = buildContainer(
        db: db,
        clock: () => clockNow,
      );
      addTearDown(container.dispose);

      await container.read(streakRolloverServiceProvider.notifier).rollover();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('streak_last_wall_clock_ms'),
        clockNow.millisecondsSinceEpoch,
        reason: 'lastWallClockMs persisted',
      );
      expect(
        prefs.getInt('streak_last_evaluated_day_ms'),
        isNotNull,
        reason: 'lastEvaluatedStreakDay persisted',
      );
    },
  );

  // ---------------------------------------------------------------------------
  // streakBadgeProvider 3-field record (D-05 break-detection wiring)
  // ---------------------------------------------------------------------------
  group('streakBadgeProvider 3-field record (D-05 break-detection wiring)', () {
    test(
      'test_streak_badge_provider_returns_three_field_record_empty_state: '
      'no rows → (current:0, longest:0, breakDetectedToday:false)',
      () async {
        final entryId = await seedEntry(db);
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final r = await container.read(streakBadgeProvider(entryId).future);
        expect(r.current, 0);
        expect(r.longest, 0);
        expect(r.breakDetectedToday, false);
      },
    );

    test(
      'test_streak_badge_provider_returns_three_field_record_active_streak: '
      'three consecutive success days → (current:3, longest:3, breakDetectedToday:false)',
      () async {
        final entryId = await seedEntry(db);
        final dao = DailyStreakDao(db);
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        // Seed (today-1, today-2, today-3) as status=0
        for (var i = 1; i <= 3; i++) {
          final day = today.subtract(Duration(days: i));
          await dao.upsert(
            entryId: entryId,
            day: day,
            status: 0,
            source: 0,
            usageMinutesObserved: 0,
            evaluatedAt: day,
          );
        }

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final r = await container.read(streakBadgeProvider(entryId).future);
        expect(r.current, 3);
        expect(r.longest, 3);
        expect(r.breakDetectedToday, false);
      },
    );

    test(
      'test_streak_badge_provider_break_detected_today_default_false_when_no_recent_break: '
      'old break (5 days ago) → breakDetectedToday:false',
      () async {
        final entryId = await seedEntry(db);
        final dao = DailyStreakDao(db);
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        // Seed a broken row 5 days ago with evaluatedAt 5 days ago (too old).
        final oldDay = today.subtract(const Duration(days: 5));
        final oldEvaluatedAt = DateTime.now().subtract(const Duration(days: 5));
        await dao.upsert(
          entryId: entryId,
          day: oldDay,
          status: 1, // broken
          source: 0,
          usageMinutesObserved: 0,
          evaluatedAt: oldEvaluatedAt,
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final r = await container.read(streakBadgeProvider(entryId).future);
        expect(r.breakDetectedToday, false, reason: 'too old — > 24h since evaluatedAt');
      },
    );

    test(
      'test_streak_badge_provider_break_detected_today_true_when_recent_status_1: '
      'recent break (evaluatedAt now, status=1) → breakDetectedToday:true',
      () async {
        final entryId = await seedEntry(db);
        final dao = DailyStreakDao(db);
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        // Seed today's streak row as broken, evaluatedAt = now
        await dao.upsert(
          entryId: entryId,
          day: today,
          status: 1, // broken
          source: 0,
          usageMinutesObserved: 0,
          evaluatedAt: DateTime.now(),
        );

        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);

        final r = await container.read(streakBadgeProvider(entryId).future);
        expect(r.breakDetectedToday, true, reason: 'recent break → breakDetectedToday true');
      },
    );
  });
}
