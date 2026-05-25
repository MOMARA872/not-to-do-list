// Phase 6 Wave 2 GREEN — home_appbar_settings_action_test.dart
// Tests for HomeScreen AppBar settings gear icon (Phase 6 D-01).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/features/home/pages/home_screen.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

Widget _wrap({required BlockListRepository repo, required AppDatabase db}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('settings-stub')),
      ),
      GoRoute(
        path: '/settings/reminder',
        builder: (_, __) => const Scaffold(body: Text('reminder-stub')),
      ),
      GoRoute(
        path: '/list/add-app',
        builder: (_, __) => const Scaffold(body: Text('add-app-stub')),
      ),
      GoRoute(
        path: '/list/add-habit',
        builder: (_, __) => const Scaffold(body: Text('add-habit-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      blockListRepoProvider.overrideWithValue(repo),
      databaseProvider.overrideWithValue(db),
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
  Future<void> drainStreamTimers(WidgetTester tester) =>
      tester.runAsync(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await Future<void>.delayed(Duration.zero);
      });

  group('Phase 6 / HomeScreen AppBar settings action (PLAY-08)', () {
    testWidgets(
      'HomeScreen AppBar actions contains IconButton with Icons.settings '
      'and tooltip "Settings"',
      (tester) async {
        await tester.pumpWidget(_wrap(repo: repo, db: db));
        await tester.pump();

        // Settings gear icon must be present
        expect(find.byIcon(Icons.settings), findsOneWidget);

        // Tooltip is set to 'Settings'
        final settingsBtn = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.settings),
        );
        expect(settingsBtn.tooltip, 'Settings');

        await drainStreamTimers(tester);
      },
    );

    testWidgets(
      'tapping settings IconButton routes to /settings',
      (tester) async {
        await tester.pumpWidget(_wrap(repo: repo, db: db));
        await tester.pump();

        // Tap the settings icon
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Should have navigated to /settings stub
        expect(find.text('settings-stub'), findsOneWidget);

        await drainStreamTimers(tester);
      },
    );

    testWidgets(
      'existing notifications IconButton preserved after settings insertion',
      (tester) async {
        await tester.pumpWidget(_wrap(repo: repo, db: db));
        await tester.pump();

        // Both icons must be present
        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

        // Tapping notifications routes to /settings/reminder
        await tester.tap(find.byIcon(Icons.notifications_outlined));
        await tester.pumpAndSettle();

        expect(find.text('reminder-stub'), findsOneWidget);

        await drainStreamTimers(tester);
      },
    );
  });
}
