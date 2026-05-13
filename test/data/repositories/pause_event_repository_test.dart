// Plan 04-07 — Task 04-07-01: PauseEventRepository tests (D-13 single-writer).
//
// outcome mapping:
//   0 = cooldown auto-completed
//   1 = Cancel pressed
//   2 = Use anyway pressed
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/pause_event_dao.dart';
import 'package:not_to_do_list/data/repositories/pause_event_repository.dart';

void main() {
  group('PauseEventRepository.insertOutcome (D-13)', () {
    late AppDatabase db;
    late PauseEventRepository repo;
    late int blockListEntryId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final dao = PauseEventDao(db);
      repo = PauseEventRepository(dao);

      // Insert a FK target row into block_list.
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

    test(
      'insertOutcome with outcome=0 writes a cooldown-completed row',
      () async {
        final id = await repo.insertOutcome(
          entryId: blockListEntryId,
          packageName: 'com.instagram.android',
          triggeredAt: DateTime.utc(2026, 5, 10, 9, 0),
          cooldownChosenSeconds: 180,
          outcome: 0,
        );
        expect(id, isPositive);

        final rows = await db.select(db.pauseEvents).get();
        expect(rows, hasLength(1));
        expect(rows.first.outcome, 0);
        expect(rows.first.cooldownChosenSeconds, 180);
      },
    );

    test(
      'insertOutcome with outcome=1 and null cooldownChosenSeconds writes a row with NULL column',
      () async {
        final id = await repo.insertOutcome(
          entryId: blockListEntryId,
          packageName: 'com.instagram.android',
          triggeredAt: DateTime.utc(2026, 5, 10, 9, 1),
          // no chip was tapped before Cancel
          cooldownChosenSeconds: null,
          outcome: 1,
        );
        expect(id, isPositive);

        final rows = await db.select(db.pauseEvents).get();
        expect(rows, hasLength(1));
        expect(rows.first.outcome, 1);
        expect(rows.first.cooldownChosenSeconds, isNull);
      },
    );

    test(
      'insertOutcome with outcome=2 writes a row that cumulativeTotalsProvider WHERE clause excludes',
      () async {
        // Insert outcome=0 (counts), outcome=1 (counts), outcome=2 (excluded).
        await repo.insertOutcome(
          entryId: blockListEntryId,
          packageName: 'com.instagram.android',
          triggeredAt: DateTime.utc(2026, 5, 10, 9, 0),
          cooldownChosenSeconds: 300,
          outcome: 0,
        );
        await repo.insertOutcome(
          entryId: blockListEntryId,
          packageName: 'com.instagram.android',
          triggeredAt: DateTime.utc(2026, 5, 10, 9, 5),
          cooldownChosenSeconds: 60,
          outcome: 1,
        );
        await repo.insertOutcome(
          entryId: blockListEntryId,
          packageName: 'com.instagram.android',
          triggeredAt: DateTime.utc(2026, 5, 10, 9, 10),
          cooldownChosenSeconds: 180,
          outcome: 2,
        );

        // Verify cumulativeTotalsProvider's WHERE outcome IN (0, 1) contract.
        final result = await db
            .customSelect(
              'SELECT COUNT(*) AS n FROM pause_events WHERE outcome IN (0, 1)',
            )
            .getSingle();
        // Only 2 rows qualify — the use-anyway (outcome=2) is excluded.
        expect(result.read<int>('n'), 2);

        // Total row count is 3 — the use-anyway row does exist, just excluded
        // from the aggregate.
        final total = await db.select(db.pauseEvents).get();
        expect(total, hasLength(3));
      },
    );
  });
}
