// Plan 02-08 implementation. (Wave 0 stub replaced.)
//
// Widget-level coverage of QuickAddScreen — UI shape, default-unchecked,
// toggle, and Continue routing.
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

  group('QuickAddScreen (LIST-07, ONBD-02)', () {
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
            builder: (_, __) =>
                const Scaffold(body: Text('usage-access-arrived')),
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

    testWidgets('renders all 5 cards: Instagram, TikTok, X, YouTube, Reddit',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('Reddit'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(5));
    });

    testWidgets('all 5 cards default to unchecked', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final tiles = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .toList();
      expect(tiles.length, 5);
      for (final t in tiles) {
        expect(
          t.value,
          isFalse,
          reason: 'card "${t.title}" should default to unchecked',
        );
      }
    });

    testWidgets('tapping a card toggles it selected', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      final igTile = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('Instagram'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(igTile.value, isTrue);
    });

    testWidgets(
        'Continue with 0 selected: insertMany NOT called, navigates to '
        '/onboarding/permissions/usage-access', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.insertMany(any()));
      expect(find.text('usage-access-arrived'), findsOneWidget);
    });

    testWidgets(
        'Continue with all 5 selected: insertMany called with 5 entries',
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
      expect(captured, hasLength(1));
      final entries = captured.single as List<BlockListSeed>;
      expect(entries, hasLength(5));
      expect(
        entries.map((e) => e.displayName).toSet(),
        {'Instagram', 'TikTok', 'X', 'YouTube', 'Reddit'},
      );
      expect(find.text('usage-access-arrived'), findsOneWidget);
    });
  });
}
