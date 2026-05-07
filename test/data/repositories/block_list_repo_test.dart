// Plan 02-04: BlockListRepository round-trip tests.
//
// Covers LIST-02 (add app/habit), LIST-03 (reason note up to 500 chars),
// LIST-04 (edit), LIST-05 (delete), LIST-06 (sort by updatedAt desc),
// LIST-07 (quick-add insertMany), LIST-08 (block_mode round-trip), and
// LIST-09 (schedule columns round-trip).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';

void main() {
  group(
    'BlockListRepository (LIST-02, LIST-03, LIST-04, LIST-05, '
    'LIST-06, LIST-07, LIST-08, LIST-09)',
    () {
      late AppDatabase db;
      late BlockListRepository repo;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        repo = BlockListRepository(BlockListDao(db));
      });

      tearDown(() => db.close());

      test(
          'LIST-02: add habit creates row with kind=1, packageName=null',
          () async {
        final id = await repo.add(kind: 1, displayName: 'Checking news');
        final row = await repo.getById(id);
        expect(row, isNotNull);
        expect(row!.kind, 1);
        expect(row.packageName, isNull);
        expect(row.displayName, 'Checking news');
        expect(row.blockMode, 'soft'); // default
        expect(row.scheduleStartMinutes, isNull);
        expect(row.scheduleEndMinutes, isNull);
        expect(row.scheduleWeekdayMask, isNull);
      });

      test('LIST-03: reasonNote saved as plain text up to 500 chars', () async {
        final reason = 'a' * 500;
        final id = await repo.add(
          kind: 0,
          packageName: 'com.x',
          displayName: 'X',
          reasonNote: reason,
        );
        final row = await repo.getById(id);
        expect(row!.reasonNote.length, 500);
        expect(row.reasonNote, reason);
      });

      test(
        'LIST-04: updateEntry overwrites name + reason + blockMode + schedule '
        'and bumps updatedAt',
        () async {
          final id = await repo.add(
            kind: 0,
            packageName: 'com.tiktok',
            displayName: 'TikTok',
          );
          final before = (await repo.getById(id))!.updatedAt;
          // Drift stores DateTime as integer seconds-since-epoch by default,
          // so we need >1s between writes for isAfter to be reliable.
          await Future<void>.delayed(const Duration(milliseconds: 1100));
          await repo.updateEntry(
            id: id,
            displayName: 'TikTok',
            reasonNote: 'Doomscrolling',
            blockMode: 'hard',
            scheduleStartMinutes: 1320, // 22:00
            scheduleEndMinutes: 360, // 06:00 (cross-midnight)
            scheduleWeekdayMask: 0x1F, // Mon-Fri
          );
          final after = await repo.getById(id);
          expect(after!.reasonNote, 'Doomscrolling');
          expect(after.blockMode, 'hard');
          expect(after.scheduleStartMinutes, 1320);
          expect(after.scheduleEndMinutes, 360);
          expect(after.scheduleWeekdayMask, 0x1F);
          expect(after.updatedAt.isAfter(before), isTrue);
        },
      );

      test('LIST-05: delete removes row', () async {
        final id = await repo.add(
          kind: 0,
          packageName: 'com.x',
          displayName: 'X',
        );
        await repo.delete(id);
        expect(await repo.getById(id), isNull);
      });

      test('LIST-06: getAll returns rows sorted by updatedAt desc', () async {
        final id1 = await repo.add(
          kind: 0,
          packageName: 'com.a',
          displayName: 'A',
        );
        // Drift's default seconds-precision DateTime storage requires >1s
        // between writes for the desc sort to distinguish them.
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        final id2 = await repo.add(kind: 1, displayName: 'Habit B');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        // Touch id1 so it bubbles to the top.
        await repo.updateEntry(
          id: id1,
          displayName: 'A',
          reasonNote: 'r',
          blockMode: 'soft',
        );
        final rows = await repo.getAll();
        expect(rows.first.id, id1);
        expect(rows.last.id, id2);
      });

      test(
        'LIST-07: insertMany seeds 5 quick-add entries regardless of install '
        'status',
        () async {
          await repo.insertMany(const [
            (
              kind: 0,
              packageName: 'com.instagram.android',
              displayName: 'Instagram',
            ),
            (
              kind: 0,
              packageName: 'com.zhiliaoapp.musically',
              displayName: 'TikTok',
            ),
            (kind: 0, packageName: 'com.twitter.android', displayName: 'X'),
            (
              kind: 0,
              packageName: 'com.google.android.youtube',
              displayName: 'YouTube',
            ),
            (
              kind: 0,
              packageName: 'com.reddit.frontpage',
              displayName: 'Reddit',
            ),
          ]);
          final rows = await repo.getAll();
          expect(rows.length, 5);
          expect(
            rows.map((r) => r.displayName).toSet(),
            {'Instagram', 'TikTok', 'X', 'YouTube', 'Reddit'},
          );
          // All seeded entries are apps with default block_mode + no schedule.
          expect(rows.every((r) => r.kind == 0), isTrue);
          expect(rows.every((r) => r.blockMode == 'soft'), isTrue);
          expect(rows.every((r) => r.scheduleStartMinutes == null), isTrue);
        },
      );

      test('LIST-08: blockMode persists exactly as provided (soft/hard)',
          () async {
        final softId = await repo.add(
          kind: 0,
          packageName: 'com.soft',
          displayName: 'Soft',
        );
        final hardId = await repo.add(
          kind: 0,
          packageName: 'com.hard',
          displayName: 'Hard',
          blockMode: 'hard',
        );
        expect((await repo.getById(softId))!.blockMode, 'soft');
        expect((await repo.getById(hardId))!.blockMode, 'hard');
      });

      test(
        'LIST-09: schedule columns round-trip when all three are non-null',
        () async {
          final id = await repo.add(
            kind: 0,
            packageName: 'com.tiktok',
            displayName: 'TikTok',
            scheduleStartMinutes: 540, // 09:00
            scheduleEndMinutes: 1320, // 22:00
            scheduleWeekdayMask: 0x7F, // all 7 days
          );
          final row = await repo.getById(id);
          expect(row!.scheduleStartMinutes, 540);
          expect(row.scheduleEndMinutes, 1320);
          expect(row.scheduleWeekdayMask, 0x7F);
        },
      );

      test(
        'cascade-delete: deleting a parent block_list row removes children '
        '(LIST-05; PRAGMA foreign_keys = ON)',
        () async {
          final id = await repo.add(
            kind: 0,
            packageName: 'com.cascade',
            displayName: 'Cascade Target',
          );
          // Insert a pause-events child via the Drift API directly — the repo
          // does not expose pause-events writes (Phase 4's territory).
          await db.into(db.pauseEvents).insert(
                PauseEventsCompanion.insert(
                  entryId: id,
                  packageName: 'com.cascade',
                  triggeredAt: DateTime.now(),
                  outcome: 0, // 0 = cooldown-completed
                ),
              );
          final childrenBefore = await db.select(db.pauseEvents).get();
          expect(childrenBefore.length, 1);

          await repo.delete(id);

          final childrenAfter = await db.select(db.pauseEvents).get();
          expect(childrenAfter, isEmpty);
        },
      );
    },
  );
}
