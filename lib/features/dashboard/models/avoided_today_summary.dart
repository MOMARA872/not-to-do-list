/// Result shape of avoidedTodayProvider (DASH-05). Drives the home
/// "Avoided today" card copy (D-09).
class AvoidedTodaySummary {
  const AvoidedTodaySummary({
    required this.total,
    required this.succeeded,
    required this.pending,
    required this.failed,
  });

  /// Total block_list entries (apps + habits).
  final int total;

  /// Apps where today's foregroundSeconds <= streakBreakThresholdMinutes*60
  /// + Habits where today's daily_checkins.avoided = true.
  final int succeeded;

  /// Habits with no daily_checkins row yet for today.
  final int pending;

  /// total - succeeded - pending.
  final int failed;
}
