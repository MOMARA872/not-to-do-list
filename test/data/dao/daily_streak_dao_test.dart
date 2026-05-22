// Plan 05-02 — Wave 1: DailyStreakDao tests (GREEN).
//
// Covers: STRK-01 (per-item streak counter), STRK-05 (today=pending row),
//         STRK-07 (current + longest streak queries), D-16 (30-day history).
//
// Scaffold mirrors test/data/repositories/pause_event_repository_test.dart.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_streak_dao.dart';

void main() {
  late AppDatabase db;
  late DailyStreakDao dao;
  late int blockListEntryId;

  // Use local-time midnight (matches Drift NativeDatabase read-back format and
  // getCurrentStreakFor's "streak must include yesterday" invariant).
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = DailyStreakDao(db);
    blockListEntryId = await db.into(db.blockList).insert(
          BlockListCompanion.insert(
            kind: 0,
            packageName: const Value('com.instagram.android'),
            displayName: 'Instagram',
            createdAt: DateTime.utc(2026, 5, 10, 9),
            updatedAt: DateTime.utc(2026, 5, 10, 9),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('DailyStreakDao.upsert idempotent per (entryId, day) (STRK-01)', () {
    test(
      'upsert with same (entryId, day) does not create duplicate row',
      () async {
        final day = daysAgo(1);
        await dao.upsert(
          entryId: blockListEntryId,
          day: day,
          status: 0,
          source: 0,
          usageMinutesObserved: 3,
          evaluatedAt: DateTime.utc(2026, 5, 10, 9),
        );
        await dao.upsert(
          entryId: blockListEntryId,
          day: day,
          status: 1,
          source: 0,
          usageMinutesObserved: 5,
          evaluatedAt: DateTime.utc(2026, 5, 10, 9, 5),
        );
        final rows = await db.select(db.dailyStreak).get();
        expect(rows, hasLength(1));
      },
    );

    test(
      'upsert on different days creates separate rows per entry (STRK-01)',
      () async {
        await dao.upsert(
          entryId: blockListEntryId,
          day: daysAgo(2),
          status: 0,
          source: 0,
          usageMinutesObserved: 2,
          evaluatedAt: DateTime.utc(2026, 5, 10, 9),
        );
        await dao.upsert(
          entryId: blockListEntryId,
          day: daysAgo(1),
          status: 0,
          source: 0,
          usageMinutesObserved: 1,
          evaluatedAt: DateTime.utc(2026, 5, 10, 9),
        );
        final rows = await db.select(db.dailyStreak).get();
        expect(rows, hasLength(2));
      },
    );

    test(
      'upsert updates status and source when same (entryId, day) re-submitted',
      () async {
        final day = daysAgo(1);
        await dao.upsert(
          entryId: blockListEntryId,
          day: day,
          status: 3,
          source: 0,
          usageMinutesObserved: 0,
          evaluatedAt: DateTime.utc(2026, 5, 10, 8),
        );
        await dao.upsert(
          entryId: blockListEntryId,
          day: day,
          status: 0,
          source: 1,
          usageMinutesObserved: 3,
          evaluatedAt: DateTime.utc(2026, 5, 10, 9),
        );
        final row = await dao.getFor(blockListEntryId, day);
        expect(row, isNotNull);
        expect(row!.status, 0);
        expect(row.source, 1);
        expect(row.usageMinutesObserved, 3);
      },
    );
  });

  group(
    'DailyStreakDao.upsertIfAbsent does not overwrite (STRK-05 today=pending)',
    () {
      test(
        'upsertIfAbsent on existing row leaves prior values intact',
        () async {
          final day = daysAgo(1);
          await dao.upsert(
            entryId: blockListEntryId,
            day: day,
            status: 0,
            source: 0,
            usageMinutesObserved: 5,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          // upsertIfAbsent should be a no-op — row already exists
          await dao.upsertIfAbsent(
            entryId: blockListEntryId,
            day: day,
            status: 3,
            source: 1,
            usageMinutesObserved: 0,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9, 5),
          );
          final row = await dao.getFor(blockListEntryId, day);
          expect(row, isNotNull);
          // Original values preserved
          expect(row!.status, 0);
          expect(row.source, 0);
          expect(row.usageMinutesObserved, 5);
          final rows = await db.select(db.dailyStreak).get();
          expect(rows, hasLength(1));
        },
      );

      test(
        'upsertIfAbsent on missing row inserts status=3 pending',
        () async {
          final day = daysAgo(1);
          await dao.upsertIfAbsent(
            entryId: blockListEntryId,
            day: day,
            status: 3,
            source: 0,
            usageMinutesObserved: 0,
            evaluatedAt: DateTime.utc(2026, 5, 10, 8),
          );
          final row = await dao.getFor(blockListEntryId, day);
          expect(row, isNotNull);
          expect(row!.status, 3);
          final rows = await db.select(db.dailyStreak).get();
          expect(rows, hasLength(1));
        },
      );
    },
  );

  group(
    'DailyStreakDao.getCurrentStreakFor + getLongestStreakFor (STRK-07)',
    () {
      test(
        'getCurrentStreakFor returns 0 when no success rows exist',
        () async {
          final count = await dao.getCurrentStreakFor(blockListEntryId);
          expect(count, 0);
        },
      );

      test(
        'getCurrentStreakFor returns correct consecutive-day count',
        () async {
          // Days -3 (broken), -2 (success), -1 (success) → streak = 2
          await dao.upsert(
            entryId: blockListEntryId,
            day: daysAgo(3),
            status: 1, // broken
            source: 0,
            usageMinutesObserved: 10,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          await dao.upsert(
            entryId: blockListEntryId,
            day: daysAgo(2),
            status: 0, // success
            source: 0,
            usageMinutesObserved: 2,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          await dao.upsert(
            entryId: blockListEntryId,
            day: daysAgo(1),
            status: 0, // success
            source: 0,
            usageMinutesObserved: 1,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          final count = await dao.getCurrentStreakFor(blockListEntryId);
          expect(count, 2);
        },
      );

      test(
        'getLongestStreakFor returns longest run even after a break (STRK-07)',
        () async {
          // Run of 3: days -10, -9, -8 (success)
          // Break: day -7 (broken)
          // Run of 5: days -6, -5, -4, -3, -2 (success)
          for (int i = 10; i >= 8; i--) {
            await dao.upsert(
              entryId: blockListEntryId,
              day: daysAgo(i),
              status: 0,
              source: 0,
              usageMinutesObserved: 1,
              evaluatedAt: DateTime.utc(2026, 5, 10, 9),
            );
          }
          await dao.upsert(
            entryId: blockListEntryId,
            day: daysAgo(7),
            status: 1, // break
            source: 0,
            usageMinutesObserved: 15,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          for (int i = 6; i >= 2; i--) {
            await dao.upsert(
              entryId: blockListEntryId,
              day: daysAgo(i),
              status: 0,
              source: 0,
              usageMinutesObserved: 1,
              evaluatedAt: DateTime.utc(2026, 5, 10, 9),
            );
          }
          final longest = await dao.getLongestStreakFor(blockListEntryId);
          expect(longest, 5);
        },
      );
    },
  );

  group(
    'DailyStreakDao.watchHistoryFor(entryId, days: 30) (D-16 history)',
    () {
      test(
        'watchHistoryFor emits 30 rows when 30 days of data exist',
        () async {
          // Insert exactly 30 rows: days -29 through 0 (today)
          for (int i = 29; i >= 0; i--) {
            await dao.upsert(
              entryId: blockListEntryId,
              day: daysAgo(i),
              status: 0,
              source: 0,
              usageMinutesObserved: 1,
              evaluatedAt: DateTime.utc(2026, 5, 10, 9),
            );
          }
          // Also insert 1 old row outside the 30-day window — must be excluded
          await dao.upsert(
            entryId: blockListEntryId,
            day: daysAgo(30),
            status: 0,
            source: 0,
            usageMinutesObserved: 1,
            evaluatedAt: DateTime.utc(2026, 5, 10, 9),
          );
          final stream = dao.watchHistoryFor(blockListEntryId, days: 30);
          final rows = await stream.first;
          expect(rows, hasLength(30));
        },
      );

      test(
        'watchHistoryFor emits only available rows when fewer than 30 days',
        () async {
          // Insert 5 rows within the 30-day window
          for (int i = 4; i >= 0; i--) {
            await dao.upsert(
              entryId: blockListEntryId,
              day: daysAgo(i),
              status: 0,
              source: 0,
              usageMinutesObserved: 1,
              evaluatedAt: DateTime.utc(2026, 5, 10, 9),
            );
          }
          final stream = dao.watchHistoryFor(blockListEntryId, days: 30);
          final rows = await stream.first;
          expect(rows, hasLength(5));
          // Verify ordered asc
          for (int i = 1; i < rows.length; i++) {
            expect(
              rows[i].day.isAfter(rows[i - 1].day),
              isTrue,
              reason: 'rows should be ordered by day asc',
            );
          }
        },
      );
    },
  );
}
