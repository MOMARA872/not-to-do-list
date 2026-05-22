// Plan 05-01 — Wave 0 RED stub: DailyStreakDao tests.
//
// Covers: STRK-01 (per-item streak counter), STRK-05 (today=pending row),
//         STRK-07 (current + longest streak queries), D-16 (30-day history).
//
// All tests are skipped — Plan 05-02 fills.
// Scaffold mirrors test/data/repositories/pause_event_repository_test.dart.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

void main() {
  late AppDatabase db;
  late int blockListEntryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
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
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );

    test(
      'upsert on different days creates separate rows per entry (STRK-01)',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );

    test(
      'upsert updates status and source when same (entryId, day) re-submitted',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );
  });

  group(
    'DailyStreakDao.upsertIfAbsent does not overwrite (STRK-05 today=pending)',
    () {
      test(
        'upsertIfAbsent on existing row leaves prior values intact',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'upsertIfAbsent on missing row inserts status=3 pending',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );
    },
  );

  group(
    'DailyStreakDao.getCurrentStreakFor + getLongestStreakFor (STRK-07)',
    () {
      test(
        'getCurrentStreakFor returns 0 when no success rows exist',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'getCurrentStreakFor returns correct consecutive-day count',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'getLongestStreakFor returns longest run even after a break (STRK-07)',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );
    },
  );

  group(
    'DailyStreakDao.watchHistoryFor(entryId, days: 30) (D-16 history)',
    () {
      test(
        'watchHistoryFor emits 30 rows when 30 days of data exist',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'watchHistoryFor emits only available rows when fewer than 30 days',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );
    },
  );
}
