// Plan 02-08 implementation — sibling of quick_add_screen_test.dart.
//
// Where quick_add_screen_test.dart focuses on UI shape (5 cards present,
// unchecked-by-default, toggle, navigation), THIS file focuses on the
// data-layer wiring contract: when Continue is tapped with selections,
// repo.insertMany receives entries with kind=0 and exact packageName /
// displayName mappings.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/features/onboarding/pages/quick_add_screen.dart';

class _MockBlockListRepository extends Mock implements BlockListRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<BlockListSeed>[]);
  });

  group('QuickAddScreen → repo.insertMany contract (LIST-07)', () {
    late _MockBlockListRepository repo;

    setUp(() {
      repo = _MockBlockListRepository();
      when(() => repo.insertMany(any())).thenAnswer((_) async {});
    });

    Widget buildApp() {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const QuickAddScreen()),
          GoRoute(
            path: '/onboarding/permissions/usage-access',
            builder: (_, __) => const Scaffold(body: Text('next')),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          blockListRepoProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
        'Continue with 3 selected: insertMany invoked once, every entry '
        'has kind=0 and exact packageName/displayName', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Pick Instagram, X, Reddit.
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('X'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reddit'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.insertMany(captureAny())).captured;
      expect(captured, hasLength(1));
      final entries = captured.single as List<BlockListSeed>;
      expect(entries, hasLength(3));

      for (final e in entries) {
        expect(e.kind, 0, reason: 'kind must be 0 (App) for quick-add seeds');
      }

      final byPkg = {for (final e in entries) e.packageName: e.displayName};
      expect(byPkg['com.instagram.android'], 'Instagram');
      expect(byPkg['com.twitter.android'], 'X');
      expect(byPkg['com.reddit.frontpage'], 'Reddit');
    });

    testWidgets('packageName mapping is exact for all 5 curated apps',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      const allFive = ['Instagram', 'TikTok', 'X', 'YouTube', 'Reddit'];
      for (final name in allFive) {
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final captured = verify(() => repo.insertMany(captureAny())).captured;
      final entries = captured.single as List<BlockListSeed>;
      final byPkg = {for (final e in entries) e.packageName: e.displayName};

      // Locked CONTEXT.md / RESEARCH §Open Question 5 mapping.
      expect(byPkg['com.instagram.android'], 'Instagram');
      expect(byPkg['com.zhiliaoapp.musically'], 'TikTok');
      expect(byPkg['com.twitter.android'], 'X');
      expect(byPkg['com.google.android.youtube'], 'YouTube');
      expect(byPkg['com.reddit.frontpage'], 'Reddit');
    });
  });
}
