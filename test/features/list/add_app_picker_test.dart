// Plan 02-06: Widget tests for AddAppPickerScreen (LIST-01, LIST-07).
//
// Covers: section rendering, "already added" disabled state, tap → repo.add,
// "Show all apps" toggle reveals system apps without LAUNCHER intent.
//
// We use mocktail for the PermissionStatusApi (cheap to stub) and an
// in-memory AppDatabase + real BlockListRepository (easier than mocking the
// repo's whole surface; the repo itself is exercised in 02-04 tests).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/list/controllers/app_picker_controller.dart';
import 'package:not_to_do_list/features/list/pages/add_app_picker_screen.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';
import 'package:not_to_do_list/features/list/providers/installed_apps_provider.dart';
import 'package:not_to_do_list/features/list/providers/recently_used_apps_provider.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

class _MockPermissionStatusApi extends Mock implements PermissionStatusApi {}

List<InstalledApp> _fixtureApps() => <InstalledApp>[
      InstalledApp(
        packageName: 'com.instagram.android',
        displayName: 'Instagram',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
      InstalledApp(
        packageName: 'com.zhiliaoapp.musically',
        displayName: 'TikTok',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
      InstalledApp(
        packageName: 'com.twitter.android',
        displayName: 'X',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
      InstalledApp(
        packageName: 'com.google.android.youtube',
        displayName: 'YouTube',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
      // System app WITHOUT launcher intent — hidden by default.
      InstalledApp(
        packageName: 'com.android.providers.downloads',
        displayName: 'Download Manager',
        isSystemApp: true,
        hasLauncherIntent: false,
      ),
      // Non-system app for the alphabetical section.
      InstalledApp(
        packageName: 'com.spotify.music',
        displayName: 'Spotify',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
    ];

Future<ProviderContainer> _makeContainer({
  required AppDatabase db,
  required BlockListRepository repo,
  required _MockPermissionStatusApi permApi,
}) async {
  final container = ProviderContainer(
    overrides: [
      blockListRepoProvider.overrideWithValue(repo),
      permissionStatusApiProvider.overrideWithValue(permApi),
      installedAppsProvider.overrideWith((ref) async => _fixtureApps()),
      recentlyUsedAppsProvider.overrideWith(
        (ref, daysBack) async => const <RecentApp>[],
      ),
      // appIconBytesProvider returns null for every package — the screen
      // falls back to Icons.android.
      appIconBytesProvider.overrideWith((ref, pkg) async => null),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Widget _wrap(ProviderContainer container) {
  // We mount the picker under a tiny GoRouter so `context.go('/')` after
  // tapping a row resolves cleanly to the home placeholder route.
  final router = GoRouter(
    initialLocation: '/list/add-app',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('home-stub')),
      ),
      GoRoute(
        path: '/list/add-app',
        builder: (_, __) => const AddAppPickerScreen(),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late AppDatabase db;
  late BlockListRepository repo;
  late _MockPermissionStatusApi permApi;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = BlockListRepository(BlockListDao(db));
    permApi = _MockPermissionStatusApi();
    // Default: usage access NOT granted; the recently-used section becomes
    // an inline grant prompt (T-2-03 mitigation).
    when(() => permApi.isUsageAccessGranted()).thenAnswer((_) async => false);
    when(() => permApi.openUsageAccessSettings()).thenAnswer((_) async {});

    // Pre-seed Instagram as already-added so the picker greys it out.
    await repo.add(
      kind: 0,
      packageName: 'com.instagram.android',
      displayName: 'Instagram',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AddAppPickerScreen (LIST-01, LIST-07)', () {
    testWidgets(
      'renders Suggested + Recently used + All apps section headers',
      (tester) async {
        final container =
            await _makeContainer(db: db, repo: repo, permApi: permApi);
        await tester.pumpWidget(_wrap(container));
        // Settle the FutureProviders.
        await tester.pumpAndSettle();

        // Suggested header is visible because TikTok / X / YouTube are not
        // already added.
        expect(find.text('Suggested'), findsOneWidget);
        // Recently used header is visible because we surface the inline
        // grant prompt when usage access is denied.
        expect(find.text('Recently used'), findsOneWidget);
        expect(find.text('All apps'), findsOneWidget);
      },
    );

    testWidgets(
      "Instagram row renders with 'Already added' subtitle and is disabled",
      (tester) async {
        final container =
            await _makeContainer(db: db, repo: repo, permApi: permApi);
        await tester.pumpWidget(_wrap(container));
        await tester.pumpAndSettle();

        // The "Already added" subtitle must appear at least once (for the
        // Instagram row in the All apps section). Suggested filters it out.
        expect(find.text('Already added'), findsOneWidget);

        // Find the Instagram tile in the All apps section and confirm
        // it's disabled.
        final instagramTile = find.ancestor(
          of: find.text('Instagram'),
          matching: find.byType(ListTile),
        );
        expect(instagramTile, findsOneWidget);
        final tile = tester.widget<ListTile>(instagramTile);
        expect(tile.enabled, isFalse);
        expect(tile.onTap, isNull);
      },
    );

    testWidgets(
      'tapping TikTok row calls repo.add with kind=0, '
      "packageName='com.zhiliaoapp.musically'",
      (tester) async {
        final container =
            await _makeContainer(db: db, repo: repo, permApi: permApi);
        await tester.pumpWidget(_wrap(container));
        await tester.pumpAndSettle();

        // TikTok appears in Suggested AND in All apps. Tap the first one.
        await tester.tap(find.text('TikTok').first);
        await tester.pumpAndSettle();

        final all = await repo.getAll();
        // Pre-seed Instagram (kind=0) + new TikTok = 2 apps.
        expect(all.length, 2);
        final tikTokRow = all.firstWhere(
          (r) => r.packageName == 'com.zhiliaoapp.musically',
        );
        expect(tikTokRow.kind, 0);
        expect(tikTokRow.displayName, 'TikTok');
      },
    );

    testWidgets(
      'Show all toggle reveals system apps without LAUNCHER intent',
      (tester) async {
        final container =
            await _makeContainer(db: db, repo: repo, permApi: permApi);
        await tester.pumpWidget(_wrap(container));
        await tester.pumpAndSettle();

        // Hidden by default.
        expect(find.text('Download Manager'), findsNothing);

        // The toggle ListTile is the last entry on the picker, possibly
        // off-screen on test viewports. Trigger the controller directly —
        // this is the same code path the on-screen tap drives.
        container.read(appPickerControllerProvider.notifier).toggleShowAll();
        await tester.pumpAndSettle();

        // Now the system app should appear in the All apps section.
        expect(find.text('Download Manager'), findsOneWidget);
        // And the controller's flipped state must be reflected.
        expect(
          container.read(appPickerControllerProvider).showSystemApps,
          isTrue,
        );
      },
    );
  });
}
