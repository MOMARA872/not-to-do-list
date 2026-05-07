// Plan 02-07: Widget tests for HomeScreen unified list (LIST-04, LIST-05,
// LIST-06).
//
// Covers: empty state copy, mixed Apps + Habits in one ListView (no section
// headers), updatedAt-desc ordering, both FABs render, tap-row navigates to
// /list/edit/{id}, FAB navigation, em-dash streak placeholder.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/features/home/pages/home_screen.dart';
import 'package:not_to_do_list/features/home/widgets/block_list_row.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

Widget _wrap({required BlockListRepository repo}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/list/add-app',
        builder: (_, __) => const Scaffold(body: Text('add-app-stub')),
      ),
      GoRoute(
        path: '/list/add-habit',
        builder: (_, __) => const Scaffold(body: Text('add-habit-stub')),
      ),
      GoRoute(
        path: '/list/edit/:id',
        builder: (_, state) =>
            Scaffold(body: Text('edit-stub-${state.pathParameters['id']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      blockListRepoProvider.overrideWithValue(repo),
      // App icon fetcher hits a Pigeon channel in production; stub it to a
      // null-bytes future so AppIcon falls back to Icons.android instantly.
      appIconBytesProvider.overrideWith((ref, pkg) async => null),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late AppDatabase db;
  late BlockListRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BlockListRepository(BlockListDao(db));
  });

  tearDown(() async {
    await db.close();
  });

  /// Drains pending Drift stream-disposal timers between widget tests.
  /// Without this, ProviderScope.dispose → StreamProvider.dispose →
  /// Drift's `markAsClosed` schedules a microtask that the test
  /// framework counts as a pending timer past widget-tree disposal.
  Future<void> drainStreamTimers(WidgetTester tester) =>
      tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await Future<void>.delayed(Duration.zero);
      });

  group('HomeScreen unified list (LIST-04, LIST-05, LIST-06)', () {
    testWidgets('empty list shows EmptyHomeState message', (tester) async {
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('Nothing on your list yet.'), findsOneWidget);
      expect(
        find.text('Add an app or habit you want to avoid to get started.'),
        findsOneWidget,
      );
      await drainStreamTimers(tester);
    });

    testWidgets('renders single app entry with displayName + reason',
        (tester) async {
      await repo.add(
        kind: 0,
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
        reasonNote: 'Doomscrolling',
      );
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Doomscrolling'), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets('renders single habit entry with spa_outlined icon',
        (tester) async {
      await repo.add(kind: 1, displayName: 'Checking news');
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('Checking news'), findsOneWidget);
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets(
      'renders mixed Apps + Habits in single unified ListView '
      '(no section headers)',
      (tester) async {
        await repo.add(
          kind: 0,
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
          reasonNote: 'Doomscrolling',
        );
        await repo.add(kind: 1, displayName: 'Checking news');
        await tester.pumpWidget(_wrap(repo: repo));
        await tester.pumpAndSettle();
        expect(find.text('Instagram'), findsOneWidget);
        expect(find.text('Checking news'), findsOneWidget);
        // Two rows total — no section headers grouping by kind.
        expect(find.byType(BlockListRow), findsNWidgets(2));
        expect(find.text('Apps'), findsNothing);
        expect(find.text('Habits'), findsNothing);
        await drainStreamTimers(tester);
      },
    );

    testWidgets('list is ordered by updatedAt desc (LIST-06)', (tester) async {
      // Drift's default DateTime storage is seconds-precision; gaps must be
      // ≥1.1s for updatedAt ordering to be observable (Plan 02-04 deviation).
      // `runAsync` is required for real wall-clock delays inside a widget
      // test — otherwise pending Timers leak past widget disposal.
      late int appId;
      await tester.runAsync(() async {
        appId = await repo.add(
          kind: 0,
          packageName: 'com.instagram.android',
          displayName: 'Instagram',
        );
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        await repo.add(kind: 1, displayName: 'Checking news');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        await repo.updateEntry(
          id: appId,
          displayName: 'Instagram',
          reasonNote: '',
          blockMode: 'soft',
        );
      });

      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();

      final rows = tester.widgetList<BlockListRow>(find.byType(BlockListRow));
      expect(rows.length, 2);
      // Just-touched app sits at index 0.
      expect(rows.elementAt(0).entry.displayName, 'Instagram');
      expect(rows.elementAt(1).entry.displayName, 'Checking news');
      await drainStreamTimers(tester);
    });

    testWidgets('+ Add app and + Add habit FABs both render', (tester) async {
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('+ Add app'), findsOneWidget);
      expect(find.text('+ Add habit'), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets('+ Add app FAB navigates to /list/add-app', (tester) async {
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add app'));
      await tester.pumpAndSettle();
      expect(find.text('add-app-stub'), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets('+ Add habit FAB navigates to /list/add-habit', (tester) async {
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add habit'));
      await tester.pumpAndSettle();
      expect(find.text('add-habit-stub'), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets('tap row navigates to /list/edit/{id}', (tester) async {
      final id = await repo.add(kind: 1, displayName: 'Checking news');
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checking news'));
      await tester.pumpAndSettle();
      expect(find.text('edit-stub-$id'), findsOneWidget);
      await drainStreamTimers(tester);
    });

    testWidgets('streak placeholder is em-dash for Phase 2', (tester) async {
      await repo.add(
        kind: 0,
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
      );
      await tester.pumpWidget(_wrap(repo: repo));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
      await drainStreamTimers(tester);
    });
  });
}
