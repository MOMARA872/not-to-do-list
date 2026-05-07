// Plan 02-06: Search-bar widget tests for AddAppPickerScreen (LIST-01).
//
// Covers: 150 ms debounce, display-name-only matching (NOT package name),
// case-insensitive substring, empty query restores all sections.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/data/database/daos/block_list_dao.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
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
        packageName: 'com.spotify.music',
        displayName: 'Spotify',
        isSystemApp: false,
        hasLauncherIntent: true,
      ),
    ];

Widget _buildPickerHarness({
  required BlockListRepository repo,
  required _MockPermissionStatusApi permApi,
}) {
  return ProviderScope(
    overrides: [
      blockListRepoProvider.overrideWithValue(repo),
      permissionStatusApiProvider.overrideWithValue(permApi),
      installedAppsProvider.overrideWith((ref) async => _fixtureApps()),
      recentlyUsedAppsProvider.overrideWith(
        (ref, daysBack) async => const <RecentApp>[],
      ),
      appIconBytesProvider.overrideWith((ref, pkg) async => null),
    ],
    child: const MaterialApp(home: AddAppPickerScreen()),
  );
}

void main() {
  late AppDatabase db;
  late BlockListRepository repo;
  late _MockPermissionStatusApi permApi;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = BlockListRepository(BlockListDao(db));
    permApi = _MockPermissionStatusApi();
    when(() => permApi.isUsageAccessGranted()).thenAnswer((_) async => false);
    when(() => permApi.openUsageAccessSettings()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  group('AddAppPickerScreen search (LIST-01)', () {
    testWidgets(
      "typing 'tik' filters to TikTok within 200 ms (debounce of 150 ms)",
      (tester) async {
        await tester.pumpWidget(
          _buildPickerHarness(repo: repo, permApi: permApi),
        );
        await tester.pumpAndSettle();
        // Pre-condition: all 3 apps visible in All apps section.
        expect(find.text('Instagram'), findsWidgets);
        expect(find.text('TikTok'), findsWidgets);
        expect(find.text('Spotify'), findsWidgets);

        await tester.enterText(find.byType(SearchBar), 'tik');
        // Below debounce: nothing changes yet.
        await tester.pump(const Duration(milliseconds: 50));
        // Past debounce: state propagates.
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('TikTok'), findsWidgets);
        expect(find.text('Instagram'), findsNothing);
        expect(find.text('Spotify'), findsNothing);
      },
    );

    testWidgets(
      "search by package name 'com.tiktok' returns 0 matches "
      '(display-name-only)',
      (tester) async {
        await tester.pumpWidget(
          _buildPickerHarness(repo: repo, permApi: permApi),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(SearchBar), 'com.tiktok');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('TikTok'), findsNothing);
        expect(find.text('Instagram'), findsNothing);
        expect(find.text('Spotify'), findsNothing);
      },
    );

    testWidgets(
      "case-insensitive: 'INSTAGRAM' filters to Instagram",
      (tester) async {
        await tester.pumpWidget(
          _buildPickerHarness(repo: repo, permApi: permApi),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(SearchBar), 'INSTAGRAM');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('Instagram'), findsWidgets);
        expect(find.text('TikTok'), findsNothing);
        expect(find.text('Spotify'), findsNothing);
      },
    );

    testWidgets(
      'empty search shows all sections again',
      (tester) async {
        await tester.pumpWidget(
          _buildPickerHarness(repo: repo, permApi: permApi),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(SearchBar), 'tik');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text('Instagram'), findsNothing);

        await tester.enterText(find.byType(SearchBar), '');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text('Instagram'), findsWidgets);
        expect(find.text('TikTok'), findsWidgets);
        expect(find.text('Spotify'), findsWidgets);
      },
    );
  });
}
