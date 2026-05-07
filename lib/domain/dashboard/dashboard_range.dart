/// Pure-Dart helper for the dashboard range selector (CONTEXT.md D-05).
/// Pure Dart — no Flutter, no Riverpod, no Drift imports.
///
/// Phase 3 owns the dashboard's D/W/M boundary math. Phase 5 STRK-08 owns
/// rigorous DST-correct local-day handling for streak counting; this helper
/// is "DST-safe-enough" for dashboard ranges (research A2).
library;

/// Three ranges the dashboard's SegmentedButton selects between.
enum DashboardRange { day, week, month }

/// Local-timezone midnight floor of [t]. DST-safe enough for Phase 3:
/// on transition days the resulting [DateTime] might "skip" or "double" an
/// hour, but DateTime arithmetic handles this transparently — Phase 3 never
/// reasons about "how many hours since midnight."
DateTime localMidnight(DateTime t) {
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Range resolution for D-12 / DASH-03 / DASH-04.
/// Day  -> [midnight_today, now]
/// Week -> [midnight_today - 6 days, now] (rolling 7 days, ending today)
/// Month -> [midnight_today - 29 days, now] (rolling 30 days, ending today)
({DateTime start, DateTime end}) resolveRange(DashboardRange r, DateTime now) {
  final today = localMidnight(now);
  switch (r) {
    case DashboardRange.day:
      return (start: today, end: now);
    case DashboardRange.week:
      return (start: today.subtract(const Duration(days: 6)), end: now);
    case DashboardRange.month:
      return (start: today.subtract(const Duration(days: 29)), end: now);
  }
}
