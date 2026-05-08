import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/dashboard/models/cumulative_totals_summary.dart';
import 'package:not_to_do_list/features/dashboard/providers/cumulative_totals_provider.dart';
import 'package:not_to_do_list/features/home/widgets/cumulative_totals_card.dart';

// ignore: unused_import
import '../../../_fixtures/drain_stream_timers.dart';

Widget _wrap({required CumulativeTotalsSummary summary}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: CumulativeTotalsCard()),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const Scaffold(body: Text('dashboard-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      cumulativeTotalsProvider.overrideWith((ref) => Stream.value(summary)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('CumulativeTotalsCard (DASH-06 / D-10 / D-11)', () {
    testWidgets('renders "0 launches blocked · 0m saved" with empty pause_events', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const CumulativeTotalsSummary(launchesBlocked: 0, timeAvoidedSeconds: 0),
      ));
      await tester.pump();
      expect(find.text('Total avoided'), findsOneWidget);
      expect(find.text('0 launches blocked · 0m saved'), findsOneWidget);
    });

    testWidgets('formats time as "{H}h {M}m saved" for large totals', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const CumulativeTotalsSummary(launchesBlocked: 42, timeAvoidedSeconds: 5025),
      ));
      await tester.pump();
      // 5025s = 1h + 23m + 45s -> "1h 23m saved"
      expect(find.text('42 launches blocked · 1h 23m saved'), findsOneWidget);
    });

    testWidgets('tap routes to /dashboard', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const CumulativeTotalsSummary(launchesBlocked: 1, timeAvoidedSeconds: 60),
      ));
      await tester.pump();
      await tester.tap(find.byType(CumulativeTotalsCard));
      await tester.pumpAndSettle();
      expect(find.text('dashboard-stub'), findsOneWidget);
    });
  });
}
