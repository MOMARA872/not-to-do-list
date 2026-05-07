/// Pure-Dart helper that decides whether a given moment is inside a
/// schedule's active window. Consumed by:
/// - Phase 2 editor preview (LIST-09 visual indicator on the entry row)
/// - Phase 4 PAUS-10 (interception is gated on this returning true)
/// - Phase 5 STRK-09 (streak counting only when the entry is "active")
///
/// Pure Dart — no Flutter, no Riverpod imports.
library;

/// True iff [now] falls within the schedule defined by start/end
/// minutes-of-day and a weekday bitmask.
///
/// The three schedule values are nullable as a triple: an entry has a
/// schedule iff all three are non-null. Returning false when ANY of them is
/// null lets callers treat "no schedule" as "dormant for the purpose of this
/// helper" — they can layer their own always-on policy on top.
///
/// **Same-day windows** (`start <= end`) use a half-open interval
/// `[start, end)`. At `start`, the entry is in the window; at `end`, it is
/// out. This matches typical "from 09:00 to 17:00" intent — at 17:00:00 the
/// window is closed.
///
/// **Cross-midnight windows** (`end < start`, e.g., 22:00 → 06:00) cover
/// `[today's start → tomorrow's end]`. The weekday mask refers to the
/// **START day** for both halves: a "weekdays-only 22:00–06:00" schedule is
/// active Mon-night-into-Tue, …, Fri-night-into-Sat. So at 03:00 on a
/// Saturday, the START day was Friday — we look up `yesterday.weekday`.
///
/// **Streak day boundary (04:00)** is OUT of scope for this helper. Phase 5
/// shifts wall-clock day → streak day via `streakDayFor` separately
/// (see `lib/domain/schedule/streak_day.dart`).
bool isInScheduleWindow({
  required DateTime now,
  required int? startMinutes,
  required int? endMinutes,
  required int? weekdayMask,
}) {
  if (startMinutes == null || endMinutes == null || weekdayMask == null) {
    return false;
  }
  final localNow = now.toLocal();
  final nowMinutes = localNow.hour * 60 + localNow.minute;
  final todayWeekdayBit = 1 << (localNow.weekday - 1); // Mon=1..Sun=7

  if (startMinutes <= endMinutes) {
    // Same-day window
    final inWindow = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    return inWindow && (weekdayMask & todayWeekdayBit) != 0;
  } else {
    // Cross-midnight window
    if (nowMinutes >= startMinutes) {
      // Tail of [start..midnight) on TODAY — START-day weekday must match
      return (weekdayMask & todayWeekdayBit) != 0;
    } else if (nowMinutes < endMinutes) {
      // Tail of [midnight..end) on TODAY — START day was YESTERDAY
      final yesterday = localNow.subtract(const Duration(days: 1));
      final yesterdayBit = 1 << (yesterday.weekday - 1);
      return (weekdayMask & yesterdayBit) != 0;
    }
    return false;
  }
}
