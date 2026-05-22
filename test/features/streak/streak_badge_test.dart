// Plan 05-07 — StreakBadge widget tests (GREEN).
//
// Covers: STRK-07 (home shows current + longest streak),
//         D-14 (badge format "🔥 N · best M"),
//         D-15 (day-0 renders "🔥 0 · best 0"),
//         D-05 (break-detection day shows strikethrough on prior count).
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/features/streak/widgets/streak_badge.dart';

/// Helper: pump a [StreakBadge] with the given badge record override.
Future<void> _pumpBadge(
  WidgetTester tester, {
  required int current,
  required int longest,
  required bool breakDetectedToday,
  int entryId = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streakBadgeProvider(entryId).overrideWith(
          (ref) async => (
            current: current,
            longest: longest,
            breakDetectedToday: breakDetectedToday,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: StreakBadge(entryId: 1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group(
    'StreakBadge renders 🔥 3 · best 12 when current=3, longest=12 '
    '(STRK-07 + D-14)',
    () {
      testWidgets(
        'badge text matches "🔥 3 · best 12" when current=3 longest=12',
        (tester) async {
          await _pumpBadge(
            tester,
            current: 3,
            longest: 12,
            breakDetectedToday: false,
          );
          expect(find.text('🔥 3 · best 12'), findsOneWidget);
        },
      );
    },
  );

  group('StreakBadge renders 🔥 0 · best 0 on day-0 (D-15)', () {
    testWidgets(
      'badge text matches "🔥 0 · best 0" when current=0 longest=0',
      (tester) async {
        await _pumpBadge(
          tester,
          current: 0,
          longest: 0,
          breakDetectedToday: false,
        );
        expect(find.text('🔥 0 · best 0'), findsOneWidget);
      },
    );
  });

  group('StreakBadge renders strikethrough on break-detection day (D-05)', () {
    testWidgets(
      'badge prior-count has TextDecoration.lineThrough on break day',
      (tester) async {
        await _pumpBadge(
          tester,
          current: 0,
          longest: 3,
          breakDetectedToday: true,
        );
        // Find a Text widget containing a TextSpan with lineThrough decoration.
        final richTextFinder = find.byWidgetPredicate((widget) {
          if (widget is! RichText) return false;
          bool hasLineThrough = false;
          widget.text.visitChildren((span) {
            if (span is TextSpan &&
                span.style?.decoration == TextDecoration.lineThrough) {
              hasLineThrough = true;
            }
            return true;
          });
          return hasLineThrough;
        });
        expect(richTextFinder, findsOneWidget);
      },
    );

    testWidgets(
      'badge format "🔥 0 · best N" from next day after break (no strikethrough)',
      (tester) async {
        await _pumpBadge(
          tester,
          current: 0,
          longest: 3,
          breakDetectedToday: false,
        );
        // Standard format — no RichText with lineThrough.
        final richTextFinder = find.byWidgetPredicate((widget) {
          if (widget is! RichText) return false;
          bool hasLineThrough = false;
          widget.text.visitChildren((span) {
            if (span is TextSpan &&
                span.style?.decoration == TextDecoration.lineThrough) {
              hasLineThrough = true;
            }
            return true;
          });
          return hasLineThrough;
        });
        expect(richTextFinder, findsNothing);
        expect(find.text('🔥 0 · best 3'), findsOneWidget);
      },
    );
  });
}
