// Phase 3 shared fixture: drainStreamTimers helper for widget tests.
// Extracted from test/features/home/home_screen_unified_list_test.dart
// lines 65-73 (Phase 2 precedent) so Phase 3+ widget tests don't redefine
// the helper inline.
//
// Consumed by:
// - test/features/dashboard/dashboard_screen_test.dart (Plan 03-05)
// - test/features/home/widgets/avoided_today_card_test.dart (Plan 03-06)
// - test/features/home/widgets/cumulative_totals_card_test.dart (Plan 03-06)
// - test/perf/dashboard_render_test.dart (Plan 03-06)
//
// Phase 2's home_screen_unified_list_test.dart keeps its inline copy
// unchanged — backporting Phase 2 is out of scope (Karpathy "Don't
// refactor things that aren't broken").
import 'package:flutter_test/flutter_test.dart';

/// Drains pending Drift stream-disposal timers between widget tests.
/// Without this, ProviderScope.dispose → StreamProvider.dispose →
/// Drift's `markAsClosed` schedules a microtask that the test
/// framework counts as a pending timer past widget-tree disposal.
Future<void> drainStreamTimers(WidgetTester tester) =>
    tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(Duration.zero);
    });
