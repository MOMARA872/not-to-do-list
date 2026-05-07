// Phase 3 Plan 03-01 — Wave 0 stub for UsageApi Pigeon channel.
// Implementation lands in Plan 03-03 (Kotlin UsageApiImpl + MainActivity wire-up).
// Dart-side mock harness is reused by 03-04 (UsageRepository test) and
// 03-05 (DashboardScreen widget tests).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:not_to_do_list/platform/usage_api.g.dart';

/// Reusable mocktail mock — Wave 2+ test files import this class.
class MockUsageApi extends Mock implements UsageApi {}

void main() {
  group('UsageApi (DASH-01)', () {
    test('UsageApi() instantiates without exception', () {
      // Wave 1 (Plan 03-03) ships the Kotlin impl. This smoke test mirrors
      // test/platform/app_picker_api_test.dart's invariant — channel binding
      // is reachable from Dart without throwing during construction.
      expect(UsageApi.new, returnsNormally);
    }, skip: 'Wave 1 — UsageApiImpl lands in Plan 03-03');

    test('MockUsageApi can stub queryRange', () {
      final m = MockUsageApi();
      when(() => m.queryRange(any(), any())).thenAnswer((_) async => const []);
      expect(m, isA<UsageApi>());
    }, skip: 'Wave 2 — UsageRepository tests light this up');
  });
}
