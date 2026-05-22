// Plan 05-06 -- CheckinScreen widget tests (fills the Wave 0 RED stubs from
// Plan 05-01).
//
// Covers: D-02 (pending entries with Yes/No SegmentedButton),
//         D-03 (Save check-in writes N rows in one Drift transaction),
//         D-01 (idempotent -- already-answered entries show locked SegmentedButton),
//         UI-SPEC empty-state copy ("You're all caught up" + "Check back tomorrow."),
//         UI-SPEC error copy ("Something went wrong...").
//
// Copy locked from 05-UI-SPEC.md Copywriting Contract -- no paraphrase.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/schedule/streak_day.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/features/checkin/controllers/checkin_controller.dart';
import 'package:not_to_do_list/features/checkin/pages/checkin_screen.dart';
import 'package:not_to_do_list/features/checkin/providers/checkin_providers.dart';

/// Inserts a block_list entry (app or habit) and returns the row.
Future<BlockListData> _insertEntry({
  required AppDatabase db,
  required String displayName,
  int kind = 0,
  String? packageName,
}) async {
  final id = await db.into(db.blockList).insert(
        BlockListCompanion.insert(
          kind: kind,
          packageName:
              packageName != null ? Value(packageName) : const Value(null),
          displayName: displayName,
          createdAt: DateTime.utc(2026, 5, 22),
          updatedAt: DateTime.utc(2026, 5, 22),
        ),
      );
  return (await (db.select(db.blockList)..where((t) => t.id.equals(id)))
          .get())
      .first;
}

/// Inserts a daily_checkins row for today, simulating a prior answer.
Future<void> _insertCheckin({
  required AppDatabase db,
  required int entryId,
  required bool avoided,
}) async {
  final today = streakDayFor(DateTime.now());
  await db.dailyCheckinsDao.upsert(
    entryId: entryId,
    day: today,
    avoided: avoided,
    answeredAt: DateTime.now(),
  );
}

/// Builds a CheckinScreen wrapped in ProviderScope.
///
/// [pendingOverride] and [answeredOverride] let tests inject a fixed
/// [pendingCheckinsTodayProvider] result without running the full provider.
/// [controllerError] causes the controller's submit() to throw.
Widget _buildScreen({
  required AppDatabase db,
  List<BlockListData>? pendingOverride,
  List<({BlockListData entry, DailyCheckin answer})>? answeredOverride,
  bool controllerError = false,
}) {
  final overrides = [
    databaseProvider.overrideWithValue(db),
    // Override rollover service so tests don't need Pigeon + SharedPrefs.
    streakRolloverServiceProvider.overrideWith(_NoopRolloverService.new),
  ];

  if (pendingOverride != null || answeredOverride != null) {
    final pending = pendingOverride ?? <BlockListData>[];
    final answered =
        answeredOverride ?? <({BlockListData entry, DailyCheckin answer})>[];
    overrides.add(
      pendingCheckinsTodayProvider.overrideWith(
        (_) async => (pending: pending, answered: answered),
      ),
    );
  }

  if (controllerError) {
    overrides.add(
      checkinControllerProvider.overrideWith(_ErrorCheckinController.new),
    );
  }

  // Use GoRouter so context.go('/') works after successful submit.
  final router = GoRouter(
    initialLocation: '/checkin',
    routes: [
      GoRoute(path: '/checkin', builder: (_, __) => const CheckinScreen()),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

/// No-op rollover service that skips DB + Pigeon calls in widget tests.
class _NoopRolloverService extends StreakRolloverService {
  @override
  Future<void> rollover() async {}
}

/// Controller that always throws on submit() to test the error path.
class _ErrorCheckinController extends CheckinController {
  @override
  Future<void> submit() async {
    state = const AsyncValue<void>.loading();
    await Future<void>.delayed(Duration.zero);
    state = AsyncValue<void>.error(
      Exception('test error'),
      StackTrace.empty,
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group(
    'CheckinScreen lists pending entries with Yes/No SegmentedButton '
    '(D-02 / D-03)',
    () {
      testWidgets(
        'pending entry has SegmentedButton with Yes and No segments',
        (tester) async {
          final entry = await _insertEntry(
            db: db,
            displayName: 'Instagram',
            kind: 0,
            packageName: 'com.instagram.android',
          );

          await tester.pumpWidget(
            _buildScreen(db: db, pendingOverride: [entry]),
          );
          await tester.pump();
          await tester.pump();

          // AppBar title -- D-02 (UI-SPEC Copywriting Contract).
          expect(find.text('Daily check-in'), findsOneWidget);
          // Heading -- UI-SPEC Copywriting Contract.
          expect(find.text('How did today go?'), findsOneWidget);
          // Entry name.
          expect(find.text('Instagram'), findsOneWidget);
          // SegmentedButton segments.
          expect(find.text('Yes'), findsOneWidget);
          expect(find.text('No'), findsOneWidget);
        },
      );

      testWidgets(
        '"Save check-in" button disabled until at least one entry answered',
        (tester) async {
          final entry = await _insertEntry(
            db: db,
            displayName: 'TikTok',
            kind: 0,
            packageName: 'com.zhiliaoapp.musically',
          );

          await tester.pumpWidget(
            _buildScreen(db: db, pendingOverride: [entry]),
          );
          await tester.pump();
          await tester.pump();

          // 'Save check-in' button should be present.
          expect(find.text('Save check-in'), findsOneWidget);

          // The button should be disabled (onPressed == null) before any answer.
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save check-in'),
          );
          expect(button.onPressed, isNull);
        },
      );
    },
  );

  group(
    'CheckinScreen Save check-in writes N rows in one Drift transaction '
    '(D-03)',
    () {
      testWidgets(
        'tapping Save check-in writes all answered rows in single transaction',
        (tester) async {
          // Insert 3 pending entries.
          final entry1 = await _insertEntry(
            db: db,
            displayName: 'Instagram',
            kind: 0,
            packageName: 'com.instagram.android',
          );
          final entry2 = await _insertEntry(
            db: db,
            displayName: 'YouTube',
            kind: 0,
            packageName: 'com.google.android.youtube',
          );
          final entry3 = await _insertEntry(
            db: db,
            displayName: 'Doomscrolling',
            kind: 1,
          );

          await tester.pumpWidget(
            _buildScreen(
              db: db,
              pendingOverride: [entry1, entry2, entry3],
            ),
          );
          await tester.pump();
          await tester.pump();

          // Inject answers directly into the provider state.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(CheckinScreen)),
          );
          container.read(checkinAnswersProvider.notifier).state = <int, bool>{
            entry1.id: true, // avoided
            entry2.id: true, // avoided
            entry3.id: false, // did not avoid
          };
          await tester.pump();

          // Tap 'Save check-in' button.
          await tester.tap(find.widgetWithText(FilledButton, 'Save check-in'));
          await tester.pumpAndSettle();

          // Verify all 3 rows were written to daily_checkins.
          final today = streakDayFor(DateTime.now());
          final ci1 = await db.dailyCheckinsDao.getFor(entry1.id, today);
          final ci2 = await db.dailyCheckinsDao.getFor(entry2.id, today);
          final ci3 = await db.dailyCheckinsDao.getFor(entry3.id, today);

          expect(ci1, isNotNull);
          expect(ci1!.avoided, isTrue);
          expect(ci2, isNotNull);
          expect(ci2!.avoided, isTrue);
          expect(ci3, isNotNull);
          expect(ci3!.avoided, isFalse);
        },
      );
    },
  );

  group(
    'CheckinScreen idempotent -- already-answered entries show locked '
    'SegmentedButton (D-01)',
    () {
      testWidgets(
        'already-answered entry renders SegmentedButton as disabled with prior answer',
        (tester) async {
          final entry = await _insertEntry(
            db: db,
            displayName: 'Reddit',
            kind: 0,
            packageName: 'com.reddit.frontpage',
          );
          // Pre-seed a check-in row (avoided = true).
          await _insertCheckin(db: db, entryId: entry.id, avoided: true);

          final today = streakDayFor(DateTime.now());
          final checkin = await db.dailyCheckinsDao.getFor(entry.id, today);

          await tester.pumpWidget(
            _buildScreen(
              db: db,
              pendingOverride: [],
              answeredOverride: [(entry: entry, answer: checkin!)],
            ),
          );
          await tester.pump();
          await tester.pump();

          // Entry name present.
          expect(find.text('Reddit'), findsOneWidget);
          // SegmentedButton present.
          expect(find.text('Yes'), findsOneWidget);
          expect(find.text('No'), findsOneWidget);

          // The SegmentedButton for the answered entry must be disabled.
          final segmented = tester.widget<SegmentedButton<bool>>(
            find.byType(SegmentedButton<bool>),
          );
          expect(
            segmented.onSelectionChanged,
            isNull,
            reason: 'already-answered entry SegmentedButton must be disabled',
          );

          // Selected segment must reflect the stored answer (avoided = true).
          expect(segmented.selected, equals(<bool>{true}));
        },
      );
    },
  );

  group(
    'CheckinScreen empty state heading "You\'re all caught up" + '
    'body "Check back tomorrow." (UI-SPEC copy)',
    () {
      testWidgets(
        'empty state shows "You\'re all caught up" heading',
        (tester) async {
          await tester.pumpWidget(
            _buildScreen(
              db: db,
              pendingOverride: [],
              answeredOverride: [],
            ),
          );
          await tester.pump();
          await tester.pump();

          // UI-SPEC Copywriting Contract -- exact copy.
          expect(find.text("You're all caught up"), findsOneWidget);
        },
      );

      testWidgets(
        'empty state shows "Check back tomorrow." body text',
        (tester) async {
          await tester.pumpWidget(
            _buildScreen(
              db: db,
              pendingOverride: [],
              answeredOverride: [],
            ),
          );
          await tester.pump();
          await tester.pump();

          // UI-SPEC Copywriting Contract -- exact copy.
          expect(find.text('Check back tomorrow.'), findsOneWidget);
        },
      );
    },
  );

  group(
    'CheckinScreen error shows SnackBar '
    '"Something went wrong..." (UI-SPEC copy)',
    () {
      testWidgets(
        'write error shows SnackBar with verbatim error copy',
        (tester) async {
          final entry = await _insertEntry(
            db: db,
            displayName: 'Twitter',
            kind: 0,
            packageName: 'com.twitter.android',
          );

          await tester.pumpWidget(
            _buildScreen(
              db: db,
              pendingOverride: [entry],
              controllerError: true,
            ),
          );
          await tester.pump();
          await tester.pump();

          // Inject an answer so the button is enabled.
          final container = ProviderScope.containerOf(
            tester.element(find.byType(CheckinScreen)),
          );
          container.read(checkinAnswersProvider.notifier).state = <int, bool>{
            entry.id: true,
          };
          await tester.pump();

          // Tap 'Save check-in'.
          await tester.tap(find.widgetWithText(FilledButton, 'Save check-in'));
          // Multiple pumps: first drains microtasks, second processes callbacks,
          // third allows SnackBar animation frame to render.
          await tester.pump();
          await tester.pump();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          // SnackBar must appear with exact UI-SPEC error copy.
          expect(
            find.text(
              "Something went wrong — your check-in wasn't saved. Try again.",
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}
