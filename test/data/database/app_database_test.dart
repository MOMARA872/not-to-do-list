import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';

void main() {
  group('AppDatabase schema v1 round-trip', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('all 5 tables exist after onCreate', () async {
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' "
            'ORDER BY name;',
          )
          .get();
      final names = tables.map((r) => r.read<String>('name')).toSet();
      expect(
        names,
        containsAll(<String>{
          'block_list',
          'daily_streak',
          'pause_events',
          'daily_checkins',
          'daily_usage_summary',
        }),
      );
    });

    test('block_list insert + select round-trips', () async {
      await db.into(db.blockList).insert(
            BlockListCompanion.insert(
              kind: 0,
              packageName: const Value('com.instagram.android'),
              displayName: 'Instagram',
              reasonNote: const Value('Doomscrolling at night.'),
              createdAt: DateTime.utc(2026, 4, 27, 12),
              updatedAt: DateTime.utc(2026, 4, 27, 12),
            ),
          );
      final rows = await db.select(db.blockList).get();
      expect(rows, hasLength(1));
      expect(rows.first.packageName, 'com.instagram.android');
    });

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });
}
