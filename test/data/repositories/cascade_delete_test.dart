// Plan 02-02 fills in the assertion originally stubbed in Plan 02-01.
//
// Verifies LIST-05: deleting a block_list row cascades to its pause_events
// rows. Cascade is declared on the FK in pause_events_table.dart with
// onDelete: KeyAction.cascade. SQLite enforces the cascade only when
// PRAGMA foreign_keys = ON, which Drift turns on by default.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

void main() {
  group('BlockList cascade delete (LIST-05)', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('deleting a block_list row removes child pause_events rows',
        () async {
      // Insert parent
      final parentId = await db.into(db.blockList).insert(
            BlockListCompanion.insert(
              kind: 0,
              packageName: const Value('com.x'),
              displayName: 'X',
              createdAt: DateTime.utc(2026, 5, 5),
              updatedAt: DateTime.utc(2026, 5, 5),
            ),
          );

      // Insert child pause_events row referencing parent
      await db.into(db.pauseEvents).insert(
            PauseEventsCompanion.insert(
              entryId: parentId,
              packageName: 'com.x',
              triggeredAt: DateTime.utc(2026, 5, 5),
              outcome: 1, // 1 = cancel per pause_events_table.dart comment
            ),
          );

      // Sanity: child exists
      final childrenBefore = await (db.select(db.pauseEvents)
            ..where((t) => t.entryId.equals(parentId)))
          .get();
      expect(childrenBefore, hasLength(1));

      // Delete parent — cascade should fire.
      // Acceptance literal:
      // (db.delete(db.blockList)..where((t) => t.id.equals(parentId))).go()
      final deletedRows =
          await (db.delete(db.blockList)..where((t) => t.id.equals(parentId)))
              .go();
      expect(deletedRows, 1);

      // Child must be gone
      final childrenAfter = await (db.select(db.pauseEvents)
            ..where((t) => t.entryId.equals(parentId)))
          .get();
      expect(childrenAfter, isEmpty);
    });
  });
}
