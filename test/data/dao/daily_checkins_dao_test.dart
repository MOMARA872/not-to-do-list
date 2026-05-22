// Plan 05-01 — Wave 0 RED stub: DailyCheckinsDao tests.
//
// Covers: STRK-03 (one check-in per entry per day, UNIQUE constraint).
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
            packageName: const Value('com.twitter.android'),
            displayName: 'Twitter',
            createdAt: DateTime.utc(2026, 5, 10, 9),
            updatedAt: DateTime.utc(2026, 5, 10, 9),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group(
    'DailyCheckinsDao.upsert idempotent per (entryId, day) (STRK-03)',
    () {
      test(
        'upsert with same (entryId, day) does not create duplicate row',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'upsert with same (entryId, day) updates avoided field',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );

      test(
        'upsert on different days creates separate rows (STRK-03)',
        () async {
          // Plan 05-02 fills
        },
        skip: 'Plan 05-02 fills',
      );
    },
  );

  group('DailyCheckinsDao.getFor(entryId, day) returns null on miss', () {
    test(
      'getFor returns null when no row exists for (entryId, day)',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );

    test(
      'getFor returns the row when a row exists for (entryId, day)',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );
  });

  group('DailyCheckinsDao.upsert roundtrips avoided bool', () {
    test(
      'upsert with avoided=true roundtrips to true on read',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );

    test(
      'upsert with avoided=false roundtrips to false on read',
      () async {
        // Plan 05-02 fills
      },
      skip: 'Plan 05-02 fills',
    );
  });
}
