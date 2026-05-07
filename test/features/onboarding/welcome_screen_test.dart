// Plan 02-08 implementation. (Wave 0 stub replaced.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/onboarding/pages/welcome_screen.dart';

void main() {
  group('WelcomeScreen (ONBD-01)', () {
    GoRouter buildRouter() => GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
            GoRoute(
              path: '/onboarding/quick-add',
              builder: (_, __) =>
                  const Scaffold(body: Text('quick-add-arrived')),
            ),
          ],
        );

    testWidgets('renders headline + privacy claim + single CTA',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
      await tester.pumpAndSettle();

      expect(find.text('Build your Not-To-Do list'), findsOneWidget);
      expect(find.text('We never see your data.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      // Single primary CTA — no carousel, no second action button.
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('Get Started navigates to /onboarding/quick-add',
        (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      expect(find.text('quick-add-arrived'), findsOneWidget);
    });
  });
}
