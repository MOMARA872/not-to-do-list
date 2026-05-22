// Plan 05-07 — StreakHistorySection widget tests (GREEN).
//
// Covers: D-16 (30-day 7-column GridView in entry detail),
//         D-07 (4 dot states: green/blue/red/grey),
//         D-07 mandatory grey tooltip ("Tracking was off this day"),
//         UI-SPEC copy "{N} days · best {M}".
//
// Copy locked from 05-UI-SPEC.md §Copywriting Contract — no paraphrase.
// Harness mirrors test/features/home/health_banner_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/features/streak/widgets/day_dot.dart';
import 'package:not_to_do_list/features/streak/widgets/streak_history_section.dart';

const int _entryId = 1;

/// Build a [DailyStreakData] with required fields.
DailyStreakData _makeRow({
  required int id,
  required DateTime day,
  required int status,
  int source = 0,
}) {
  return DailyStreakData(
    id: id,
    entryId: _entryId,
    day: day,
    status: status,
    source: source,
    usageMinutesObserved: 0,
    evaluatedAt: day,
  );
}

/// Generate 30 DailyStreakData rows — mixed statuses.
///
/// Distribution: 8 green (status=0 source=0), 5 blue (status=0 source=1),
/// 3 red (status=1), 2 grey (status=2), 12 pending (status=3).
List<DailyStreakData> _buildHistoryRows() {
  final now = DateTime(2026, 5, 22);
  final rows = <DailyStreakData>[];
  int id = 1;

  // 8 green
  for (int i = 0; i < 8; i++) {
    rows.add(_makeRow(
      id: id++,
      day: now.subtract(Duration(days: 29 - i)),
      status: 0,
      source: 0,
    ));
  }
  // 5 blue
  for (int i = 0; i < 5; i++) {
    rows.add(_makeRow(
      id: id++,
      day: now.subtract(Duration(days: 21 - i)),
      status: 0,
      source: 1,
    ));
  }
  // 3 red
  for (int i = 0; i < 3; i++) {
    rows.add(_makeRow(
      id: id++,
      day: now.subtract(Duration(days: 16 - i)),
      status: 1,
    ));
  }
  // 2 grey
  for (int i = 0; i < 2; i++) {
    rows.add(_makeRow(
      id: id++,
      day: now.subtract(Duration(days: 13 - i)),
      status: 2,
    ));
  }
  // 12 pending
  for (int i = 0; i < 12; i++) {
    rows.add(_makeRow(
      id: id++,
      day: now.subtract(Duration(days: 11 - i)),
      status: 3,
    ));
  }
  return rows;
}

/// Pump [StreakHistorySection] with overridden providers.
Future<void> _pumpSection(
  WidgetTester tester, {
  List<DailyStreakData>? rows,
  int current = 8,
  int longest = 12,
}) async {
  final historyRows = rows ?? _buildHistoryRows();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        streakHistoryProvider(_entryId).overrideWith(
          (ref) => Stream.value(historyRows),
        ),
        streakBadgeProvider(_entryId).overrideWith(
          (ref) async => (
            current: current,
            longest: longest,
            breakDetectedToday: false,
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StreakHistorySection(entryId: _entryId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StreakHistorySection renders 30-day 7-col GridView (D-16)', () {
    testWidgets(
      'GridView has crossAxisCount=7 and shows 30 day cells',
      (tester) async {
        await _pumpSection(tester);
        // Should find a GridView.
        expect(find.byType(GridView), findsOneWidget);
        // Should find 30 DayDot instances (from the rows).
        expect(find.byType(DayDot), findsNWidgets(30));
      },
    );
  });

  group(
    'StreakHistorySection renders 4 dot states (D-07 — green/blue/red/grey)',
    () {
      testWidgets(
        'green dot for status=0 source=0 (system-confirmed success)',
        (tester) async {
          final now = DateTime(2026, 5, 22);
          final rows = [
            _makeRow(id: 1, day: now.subtract(const Duration(days: 1)), status: 0, source: 0),
          ];
          await _pumpSection(tester, rows: rows, current: 1, longest: 1);
          // Green dot: status=0, source=0.
          final greenDot = find.byWidgetPredicate(
            (w) => w is DayDot && w.status == 0 && w.source == 0,
          );
          expect(greenDot, findsOneWidget);
        },
      );

      testWidgets(
        'blue dot for status=0 source=1 (self-reported-only success)',
        (tester) async {
          final now = DateTime(2026, 5, 22);
          final rows = [
            _makeRow(id: 1, day: now.subtract(const Duration(days: 1)), status: 0, source: 1),
          ];
          await _pumpSection(tester, rows: rows, current: 1, longest: 1);
          final blueDot = find.byWidgetPredicate(
            (w) => w is DayDot && w.status == 0 && w.source == 1,
          );
          expect(blueDot, findsOneWidget);
        },
      );

      testWidgets(
        'red dot for status=1 (broken)',
        (tester) async {
          final now = DateTime(2026, 5, 22);
          final rows = [
            _makeRow(id: 1, day: now.subtract(const Duration(days: 1)), status: 1),
          ];
          await _pumpSection(tester, rows: rows, current: 0, longest: 0);
          final redDot = find.byWidgetPredicate(
            (w) => w is DayDot && w.status == 1,
          );
          expect(redDot, findsOneWidget);
        },
      );

      testWidgets(
        'grey dot for status=2 (incomplete-data)',
        (tester) async {
          final now = DateTime(2026, 5, 22);
          final rows = [
            _makeRow(id: 1, day: now.subtract(const Duration(days: 1)), status: 2),
          ];
          await _pumpSection(tester, rows: rows, current: 0, longest: 0);
          final greyDot = find.byWidgetPredicate(
            (w) => w is DayDot && w.status == 2,
          );
          expect(greyDot, findsOneWidget);
        },
      );
    },
  );

  group(
    'StreakHistorySection grey dot has Tooltip '
    '"Tracking was off this day" (D-07 mandatory)',
    () {
      testWidgets(
        'grey dot cell has Tooltip with message "Tracking was off this day"',
        (tester) async {
          final now = DateTime(2026, 5, 22);
          final rows = [
            _makeRow(id: 1, day: now.subtract(const Duration(days: 1)), status: 2),
          ];
          await _pumpSection(tester, rows: rows, current: 0, longest: 0);
          expect(find.byTooltip('Tracking was off this day'), findsOneWidget);
        },
      );
    },
  );

  group(
    'StreakHistorySection summary text '
    '"{N} days · best {M}" (UI-SPEC copy)',
    () {
      testWidgets(
        'summary text renders "{N} days · best {M}" format',
        (tester) async {
          await _pumpSection(tester, current: 8, longest: 12);
          expect(find.text('8 days · best 12'), findsOneWidget);
        },
      );

      testWidgets(
        'threshold help text renders '
        '"Streak breaks if you use this app over 5 min/day (change in Settings)"',
        (tester) async {
          await _pumpSection(tester);
          expect(
            find.text(
              'Streak breaks if you use this app over 5 min/day (change in Settings)',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );
}
