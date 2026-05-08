/// Result shape of cumulativeTotalsProvider (DASH-06). Drives the home
/// "Cumulative totals" card copy (D-11).
///
/// Phase 3 starts at {launchesBlocked: 0, timeAvoidedSeconds: 0} because
/// pause_events is empty until Phase 4 ships PauseActivity (D-11).
class CumulativeTotalsSummary {
  const CumulativeTotalsSummary({
    required this.launchesBlocked,
    required this.timeAvoidedSeconds,
  });

  /// COUNT(pause_events WHERE outcome IN (0, 1)).
  final int launchesBlocked;

  /// COALESCE(SUM(cooldown_chosen_seconds), 0) for the same rows.
  final int timeAvoidedSeconds;
}
