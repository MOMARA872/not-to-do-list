/// Pure-Dart utility for the v1 streak day boundary.
///
/// Consumed by Phase 5 (STRK-09) to decide which calendar day a moment of
/// usage counts toward. Ships in Phase 2 so the contract is one-stop.
///
/// Pure Dart — no Flutter, no Riverpod imports.
library;

/// Returns the streak day (a [DateTime] at local midnight) for [now].
///
/// v1 uses a **04:00 local-time boundary**: anything before 04:00 counts
/// toward the previous calendar day's streak. So usage at 02:00 on May 5
/// returns May 4; usage at 04:00 on May 5 returns May 5.
DateTime streakDayFor(DateTime now) {
  final local = now.toLocal();
  final shifted = local.subtract(const Duration(hours: 4));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
