import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/domain/dashboard/dashboard_range.dart';

void main() {
  group('resolveRange (DASH-02/03/04)', () {
    final now = DateTime(2026, 5, 7, 14, 30, 15);
    final today = DateTime(2026, 5, 7);

    test('localMidnight zeroes hour/min/sec', () {
      expect(localMidnight(now), today);
    });

    test('day -> [midnight_today, now]', () {
      final r = resolveRange(DashboardRange.day, now);
      expect(r.start, today);
      expect(r.end, now);
    });

    test('week -> [midnight_today - 6 days, now] (rolling 7d)', () {
      final r = resolveRange(DashboardRange.week, now);
      expect(r.start, DateTime(2026, 5, 1));
      expect(r.end, now);
    });

    test('month -> [midnight_today - 29 days, now] (rolling 30d)', () {
      final r = resolveRange(DashboardRange.month, now);
      expect(r.start, DateTime(2026, 4, 8));
      expect(r.end, now);
    });
  });
}
