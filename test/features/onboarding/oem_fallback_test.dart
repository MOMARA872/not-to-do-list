// Plan 02-08 implementation. (Wave 0 stub replaced.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/onboarding/widgets/oem_fallback_panel.dart';

void main() {
  group('OemFallbackPanel (ONBD-04, REL-03)', () {
    Widget wrap(Widget c) => MaterialApp(home: Scaffold(body: c));

    testWidgets('xiaomi: shows MIUI-specific copy and dontkillmyapp link',
        (tester) async {
      await tester.pumpWidget(
        wrap(const OemFallbackPanel(manufacturerLower: 'xiaomi')),
      );
      expect(find.textContaining('On Xiaomi'), findsOneWidget);
      expect(find.text('Step-by-step guide for your phone'), findsOneWidget);
    });

    testWidgets('samsung: shows Samsung-specific copy and dontkillmyapp link',
        (tester) async {
      await tester.pumpWidget(
        wrap(const OemFallbackPanel(manufacturerLower: 'samsung')),
      );
      expect(find.textContaining('On Samsung'), findsOneWidget);
      expect(find.text('Step-by-step guide for your phone'), findsOneWidget);
    });

    testWidgets(
        'unknown manufacturer (pixel): shows generic copy and NO '
        'dontkillmyapp link', (tester) async {
      await tester.pumpWidget(
        wrap(const OemFallbackPanel(manufacturerLower: 'pixel')),
      );
      expect(find.textContaining('Open your phone'), findsOneWidget);
      expect(find.text('Step-by-step guide for your phone'), findsNothing);
    });

    testWidgets('all 6 known OEMs render the dontkillmyapp link',
        (tester) async {
      const known = ['xiaomi', 'huawei', 'samsung', 'oppo', 'vivo', 'oneplus'];
      for (final mfr in known) {
        await tester.pumpWidget(
          wrap(OemFallbackPanel(manufacturerLower: mfr)),
        );
        expect(
          find.text('Step-by-step guide for your phone'),
          findsOneWidget,
          reason: 'manufacturer=$mfr should expose the dontkillmyapp link',
        );
      }
    });
  });
}
