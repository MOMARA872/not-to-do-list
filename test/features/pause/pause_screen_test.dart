// Plan 04-07 — Task 04-07-03: PauseScreen widget tests.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/features/pause/models/pause_session.dart';
import 'package:not_to_do_list/features/pause/pages/pause_screen.dart';
import 'package:not_to_do_list/features/pause/providers/pause_providers.dart';
import 'package:not_to_do_list/features/pause/widgets/app_name_hero.dart';
import 'package:not_to_do_list/features/pause/widgets/reason_hero.dart';

// A no-op onClose for tests (no SystemNavigator.pop in tests).
Future<void> _noop() async {}

/// Builds a PauseScreen wrapped in ProviderScope with the given overrides.
Widget _buildScreen({
  required int entryId,
  required String packageName,
  required String blockMode,
  required AppDatabase db,
  required BlockListData? entry,
  PauseSession? sessionOverride,
}) {
  final triggeredAt = DateTime.utc(2026, 5, 10, 9);
  final args = (
    entryId: entryId,
    packageName: packageName,
    blockMode: blockMode,
    triggeredAt: triggeredAt,
    onClose: _noop,
  );

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      blockListEntryProvider(entryId)
          .overrideWith((_) => Future.value(entry)),
    ],
    child: MaterialApp(
      home: PauseScreen(
        entryId: entryId,
        packageName: packageName,
        blockMode: blockMode,
        triggeredAt: triggeredAt,
      ),
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper to build a BlockListData in-memory and retrieve it.
  Future<BlockListData> insertEntry({
    required AppDatabase db,
    required String displayName,
    required String packageName,
    String reasonNote = '',
    String blockMode = 'soft',
  }) async {
    final id = await db.into(db.blockList).insert(
          BlockListCompanion.insert(
            kind: 0,
            packageName: Value(packageName),
            displayName: displayName,
            reasonNote: Value(reasonNote),
            blockMode: Value(blockMode),
            createdAt: DateTime.utc(2026, 5, 10),
            updatedAt: DateTime.utc(2026, 5, 10),
          ),
        );
    final rows = await (db.select(db.blockList)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.first;
  }

  group('PAUS-02 reason hero (D-02)', () {
    testWidgets(
      'renders ReasonHero when reasonNote is non-empty',
      (tester) async {
        final entry = await insertEntry(
          db: db,
          displayName: 'Instagram',
          packageName: 'com.instagram.android',
          reasonNote: 'Focus on deep work',
        );

        await tester.pumpWidget(
          _buildScreen(
            entryId: entry.id,
            packageName: 'com.instagram.android',
            blockMode: 'soft',
            db: db,
            entry: entry,
          ),
        );
        // Two pumps: first resolves the Future, second repaints.
        await tester.pump();
        await tester.pump();

        expect(find.byType(ReasonHero), findsOneWidget);
        // ReasonHero wraps text in ASCII double-quote glyphs.
        expect(find.textContaining('Focus on deep work'), findsOneWidget);
        expect(find.byType(AppNameHero), findsNothing);
      },
    );
  });

  group('PAUS-02 empty-reason app-name hero (D-03)', () {
    testWidgets(
      'renders AppNameHero when reasonNote is empty — no ReasonHero',
      (tester) async {
        final entry = await insertEntry(
          db: db,
          displayName: 'Instagram',
          packageName: 'com.instagram.android',
          reasonNote: '',
        );

        await tester.pumpWidget(
          _buildScreen(
            entryId: entry.id,
            packageName: 'com.instagram.android',
            blockMode: 'soft',
            db: db,
            entry: entry,
          ),
        );
        await tester.pump();

        expect(find.byType(AppNameHero), findsOneWidget);
        // AppNameHero appends a period: "Instagram."
        expect(find.text('Instagram.'), findsOneWidget);
        expect(find.byType(ReasonHero), findsNothing);
      },
    );
  });

  group('PAUS-09 hard entry omits Use anyway (D-06)', () {
    testWidgets(
      'hard entry omits Use anyway from widget tree entirely',
      (tester) async {
        final entry = await insertEntry(
          db: db,
          displayName: 'Instagram',
          packageName: 'com.instagram.android',
          blockMode: 'hard',
        );

        await tester.pumpWidget(
          _buildScreen(
            entryId: entry.id,
            packageName: 'com.instagram.android',
            blockMode: 'hard',
            db: db,
            entry: entry,
          ),
        );
        await tester.pump();

        // Use anyway must NOT be in the widget tree (D-06 / PAUS-09).
        expect(find.text('Use anyway'), findsNothing);
        // Cancel is always present.
        expect(find.text('Cancel'), findsOneWidget);
      },
    );
  });

  group('PAUS-03 cooldown chips [1m,3m,5m,10m] (D-04)', () {
    testWidgets(
      'soft entry renders Cancel and Use anyway buttons',
      (tester) async {
        final entry = await insertEntry(
          db: db,
          displayName: 'Instagram',
          packageName: 'com.instagram.android',
          blockMode: 'soft',
        );

        await tester.pumpWidget(
          _buildScreen(
            entryId: entry.id,
            packageName: 'com.instagram.android',
            blockMode: 'soft',
            db: db,
            entry: entry,
          ),
        );
        await tester.pump();

        // Both buttons present for soft mode.
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Use anyway'), findsOneWidget);
        // Cooldown chips present.
        expect(find.text('1m'), findsOneWidget);
        expect(find.text('3m'), findsOneWidget);
        expect(find.text('5m'), findsOneWidget);
        expect(find.text('10m'), findsOneWidget);
      },
    );
  });
}
