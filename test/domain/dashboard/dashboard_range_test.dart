// Phase 3 Plan 03-01 — Wave 0 stub for DashboardRange + resolveRange helper.
// Implementation lands in Plan 03-04 (lib/domain/dashboard/dashboard_range.dart).
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveRange (DASH-02/03/04)', () {
    test('day -> [midnight_today, now]', () {
      // D-12 — local midnight floor.
    }, skip: 'Wave 2 — dashboard_range.dart lands in Plan 03-04');

    test('week -> [midnight_today - 6 days, now]', () {
      // D-12 — rolling 7 days ending today.
    }, skip: 'Wave 2 — dashboard_range.dart lands in Plan 03-04');

    test('month -> [midnight_today - 29 days, now]', () {
      // D-12 — rolling 30 days ending today.
    }, skip: 'Wave 2 — dashboard_range.dart lands in Plan 03-04');

    test('localMidnight zeroes hour/min/sec', () {
      // RESEARCH lines 758-762.
    }, skip: 'Wave 2 — dashboard_range.dart lands in Plan 03-04');
  });
}
