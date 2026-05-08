import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/dashboard/models/avoided_today_summary.dart';
import 'package:not_to_do_list/features/dashboard/providers/avoided_today_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/home/widgets/avoided_today_card.dart';

// ignore: unused_import
import '../../../_fixtures/drain_stream_timers.dart';

class _PermissionHealthFake extends PermissionHealthNotifier {
  _PermissionHealthFake(this._initial);
  final PermissionHealth _initial;
  @override
  Future<PermissionHealth> build() async => _initial;
}

Widget _wrap({
  required AvoidedTodaySummary summary,
  required PermissionHealth health,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: AvoidedTodayCard()),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const Scaffold(body: Text('dashboard-stub')),
      ),
      GoRoute(
        path: '/list/add-app',
        builder: (_, __) => const Scaffold(body: Text('add-app-stub')),
      ),
      GoRoute(
        path: '/onboarding/permissions/usage-access',
        builder: (_, __) => const Scaffold(body: Text('usage-access-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      avoidedTodayProvider.overrideWith((ref) => Stream.value(summary)),
      permissionHealthProvider
          .overrideWith(() => _PermissionHealthFake(health)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

const _healthOk = PermissionHealth(
  usageAccess: true,
  accessibilityService: true,
  batteryOptExempt: true,
  fingerprintChanged: false,
);

const _healthOffline = PermissionHealth(
  usageAccess: false,
  accessibilityService: true,
  batteryOptExempt: true,
  fingerprintChanged: false,
);

void main() {
  group('AvoidedTodayCard (DASH-05 / D-08 / D-09)', () {
    testWidgets('renders "{X} of {Y} entries succeeded today" when Y > 0', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 5, succeeded: 3, pending: 1, failed: 1),
        health: _healthOk,
      ));
      await tester.pump();
      expect(find.text('Avoided today'), findsOneWidget);
      expect(find.text('3 of 5 entries succeeded today'), findsOneWidget);
    });

    testWidgets('renders "No entries yet" when total = 0', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 0, succeeded: 0, pending: 0, failed: 0),
        health: _healthOk,
      ));
      await tester.pump();
      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('renders "Tracking is offline — tap to fix" when usageAccess = false (D-13)', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 5, succeeded: 3, pending: 0, failed: 2),
        health: _healthOffline,
      ));
      await tester.pump();
      expect(find.text('Tracking is offline — tap to fix'), findsOneWidget);
    });

    testWidgets('tap routes to /dashboard when entries > 0 + usageAccess granted', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 3, succeeded: 2, pending: 0, failed: 1),
        health: _healthOk,
      ));
      await tester.pump();
      await tester.tap(find.byType(AvoidedTodayCard));
      await tester.pumpAndSettle();
      expect(find.text('dashboard-stub'), findsOneWidget);
    });

    testWidgets('tap routes to /list/add-app when total = 0', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 0, succeeded: 0, pending: 0, failed: 0),
        health: _healthOk,
      ));
      await tester.pump();
      await tester.tap(find.byType(AvoidedTodayCard));
      await tester.pumpAndSettle();
      expect(find.text('add-app-stub'), findsOneWidget);
    });

    testWidgets('tap routes to /onboarding/permissions/usage-access when offline', (tester) async {
      await tester.pumpWidget(_wrap(
        summary: const AvoidedTodaySummary(total: 5, succeeded: 0, pending: 0, failed: 5),
        health: _healthOffline,
      ));
      await tester.pump();
      await tester.tap(find.byType(AvoidedTodayCard));
      await tester.pumpAndSettle();
      expect(find.text('usage-access-stub'), findsOneWidget);
    });
  });
}
