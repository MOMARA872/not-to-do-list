// Plan 05-05 — Wave 4: deep-link navigation tests.
//
// Covers: NOTF-03 (tap notification deep-links to /checkin),
//         idempotency (deep_link cleared after consumption — no re-route loop).
//
// Tests verify the SharedPreferences-backed pending_deep_link mechanism:
//   - MainActivity.handleDeepLinkIntent writes flutter.pending_deep_link = "/checkin"
//     when deep_link_to="/checkin" is present in the launch intent.
//   - HomeScreen.initState (Plan 05-07) reads and clears pending_deep_link to navigate.
//
// These tests exercise the mechanism using a minimal test harness widget that
// simulates the read-and-route logic Plan 05-07 will wire into HomeScreen.
// This ensures the SharedPreferences contract is validated before Plan 05-07 ships.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal harness that simulates the HomeScreen.initState pending_deep_link
/// read-and-route logic (Plan 05-07 will implement this directly on HomeScreen).
///
/// On mount: reads 'pending_deep_link' from SharedPreferences; if set to '/checkin',
/// removes the key (idempotent) and records the routed path for test assertions.
class _DeepLinkHarness extends StatefulWidget {
  const _DeepLinkHarness({required this.onNavigate});
  final void Function(String path) onNavigate;

  @override
  State<_DeepLinkHarness> createState() => _DeepLinkHarnessState();
}

class _DeepLinkHarnessState extends State<_DeepLinkHarness> {
  String _label = 'home';

  @override
  void initState() {
    super.initState();
    _consumeDeepLink();
  }

  Future<void> _consumeDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString('pending_deep_link');
    if (pending == '/checkin') {
      await prefs.remove('pending_deep_link');
      widget.onNavigate('/checkin');
      if (mounted) setState(() => _label = '/checkin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Text(_label)),
    );
  }
}

void main() {
  group(
    'pending_deep_link=/checkin in SharedPreferences routes to /checkin '
    'on Home initState (NOTF-03)',
    () {
      testWidgets(
        'test_pending_deep_link_routes_to_checkin: '
        'pending_deep_link=/checkin causes Home to navigate to /checkin on init',
        (tester) async {
          // Arrange: simulate MainActivity writing the pending_deep_link pref
          // (as if the user tapped the daily check-in notification).
          SharedPreferences.setMockInitialValues({
            'pending_deep_link': '/checkin',
          });

          String? navigatedTo;
          await tester.pumpWidget(
            _DeepLinkHarness(onNavigate: (path) => navigatedTo = path),
          );
          await tester.pumpAndSettle();

          // Assert: the harness consumed pending_deep_link and triggered /checkin navigation.
          expect(
            navigatedTo,
            equals('/checkin'),
            reason:
                'NOTF-03: when pending_deep_link=/checkin is set, '
                'HomeScreen.initState must navigate to /checkin',
          );

          // Assert: the route label is updated.
          expect(find.text('/checkin'), findsOneWidget);
        },
      );
    },
  );

  group(
    'deep_link is cleared after consumption '
    '(idempotent, no re-route loop)',
    () {
      testWidgets(
        'pending_deep_link pref is removed after successful /checkin navigation',
        (tester) async {
          // Arrange: set pending_deep_link.
          SharedPreferences.setMockInitialValues({
            'pending_deep_link': '/checkin',
          });

          await tester.pumpWidget(
            _DeepLinkHarness(onNavigate: (_) {}),
          );
          await tester.pumpAndSettle();

          // Assert: the pref was removed after consumption — no re-route loop.
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getString('pending_deep_link'),
            isNull,
            reason:
                'NOTF-03 idempotency: pending_deep_link must be removed after '
                'consumption so a subsequent cold-start does not re-route to /checkin',
          );
        },
      );

      testWidgets(
        'second cold-start without pending_deep_link does not navigate to /checkin',
        (tester) async {
          // Arrange: no pending_deep_link in prefs (second cold-start).
          SharedPreferences.setMockInitialValues({});

          String? navigatedTo;
          await tester.pumpWidget(
            _DeepLinkHarness(onNavigate: (path) => navigatedTo = path),
          );
          await tester.pumpAndSettle();

          // Assert: no navigation triggered — stays on home.
          expect(
            navigatedTo,
            isNull,
            reason:
                'NOTF-03 idempotency: when no pending_deep_link is set, '
                'HomeScreen.initState must NOT navigate to /checkin',
          );
          expect(find.text('home'), findsOneWidget);
        },
      );
    },
  );
}
