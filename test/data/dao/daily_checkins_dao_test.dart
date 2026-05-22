// Plan 05-02 — Wave 1: DailyCheckinsDao tests (GREEN).
//
// Covers: STRK-03 (one check-in per entry per day, UNIQUE constraint).
//
// Scaffold mirrors test/data/repositories/pause_event_repository_test.dart.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/daily_checkins_dao.dart';

void main() {
  late AppDatabase db;
  late DailyCheckinsDao dao;
  late int blockListEntryId;

  // Use local-time DateTime to match Drift NativeDatabase read-back format.
  final day1 = DateTime(2026, 5, 10);
  final day2 = DateTime(2026, 5, 11);
  final t1 = DateTime(2026, 5, 10, 9, 0);
  final t2 = DateTime(2026, 5, 10, 9, 5);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = DailyCheckinsDao(db);
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
          await dao.upsert(
            entryId: blockListEntryId,
            day: day1,
            avoided: true,
            answeredAt: t1,
          );
          await dao.upsert(
            entryId: blockListEntryId,
            day: day1,
            avoided: false,
            answeredAt: t2,
          );
          final rows = await db.select(db.dailyCheckins).get();
          expect(rows, hasLength(1));
        },
      );

      test(
        'upsert with same (entryId, day) updates avoided field',
        () async {
          await dao.upsert(
            entryId: blockListEntryId,
            day: day1,
            avoided: true,
            answeredAt: t1,
          );
          await dao.upsert(
            entryId: blockListEntryId,
            day: day1,
            avoided: false,
            answeredAt: t2,
          );
          final row = await dao.getFor(blockListEntryId, day1);
          expect(row, isNotNull);
          expect(row!.avoided, isFalse);
          expect(row.answeredAt, t2);
        },
      );

      test(
        'upsert on different days creates separate rows (STRK-03)',
        () async {
          await dao.upsert(
            entryId: blockListEntryId,
            day: day1,
            avoided: true,
            answeredAt: t1,
          );
          await dao.upsert(
            entryId: blockListEntryId,
            day: day2,
            avoided: false,
            answeredAt: t2,
          );
          final rows = await db.select(db.dailyCheckins).get();
          expect(rows, hasLength(2));
        },
      );
    },
  );

  group('DailyCheckinsDao.getFor(entryId, day) returns null on miss', () {
    test(
      'getFor returns null when no row exists for (entryId, day)',
      () async {
        final result = await dao.getFor(blockListEntryId, day1);
        expect(result, isNull);
      },
    );

    test(
      'getFor returns the row when a row exists for (entryId, day)',
      () async {
        await dao.upsert(
          entryId: blockListEntryId,
          day: day1,
          avoided: true,
          answeredAt: t1,
        );
        final result = await dao.getFor(blockListEntryId, day1);
        expect(result, isNotNull);
        expect(result!.entryId, blockListEntryId);
        expect(result.day, day1);
      },
    );
  });

  group('DailyCheckinsDao.upsert roundtrips avoided bool', () {
    test(
      'upsert with avoided=true roundtrips to true on read',
      () async {
        await dao.upsert(
          entryId: blockListEntryId,
          day: day1,
          avoided: true,
          answeredAt: t1,
        );
        final row = await dao.getFor(blockListEntryId, day1);
        expect(row, isNotNull);
        expect(row!.avoided, isTrue);
      },
    );

    test(
      'upsert with avoided=false roundtrips to false on read',
      () async {
        await dao.upsert(
          entryId: blockListEntryId,
          day: day1,
          avoided: false,
          answeredAt: t1,
        );
        final row = await dao.getFor(blockListEntryId, day1);
        expect(row, isNotNull);
        expect(row!.avoided, isFalse);
      },
    );
  });
}
