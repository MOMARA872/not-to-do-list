/// Centralized `SharedPreferences` keys for Phase 5 streak engine + daily
/// reminder state. Single source of truth so every provider, service, and the
/// native Kotlin BootReceiver stay in lockstep.
///
/// NOTE: The shared_preferences plugin stores keys under the FlutterSharedPreferences
/// file as `flutter.<key>`. Kotlin reads "flutter.reminder_hour_minute" (the
/// `flutter.` prefix is added by the plugin — do NOT include it here).
/// See RESEARCH §10 R-9 for the cross-process key contract (T-05-04 mitigation).
abstract final class StreakKeys {
  /// Minutes-per-day threshold above which a day is considered broken rather
  /// than incomplete-data. Stored as raw int. Surfaced by the settings screen
  /// (Plan 05-08); consumed by StreakRolloverService (Plan 05-03).
  static const String streakThresholdMinutes = 'streak_threshold_minutes';

  /// Hour*60+minute encoded reminder time (e.g. 9:30 AM → 570). Stored as
  /// raw int. CRITICAL: Kotlin BootReceiver reads 'flutter.reminder_hour_minute'
  /// from FlutterSharedPreferences — this key must match exactly (T-05-04).
  static const String reminderHourMinute = 'reminder_hour_minute';

  /// Wall-clock milliseconds at the last rollover evaluation. Used by
  /// StreakRolloverService to detect DST transitions (Plan 05-03, STRK-08).
  static const String lastWallClockMs = 'streak_last_wall_clock_ms';

  /// Monotonic nanoseconds from the last boot at the last rollover evaluation.
  /// Paired with lastWallClockMs for boot-time drift detection (Plan 05-03).
  static const String lastBootMonotonicNs = 'streak_last_boot_monotonic_ns';

  /// Epoch milliseconds of the last day (UTC midnight) that the rollover
  /// service evaluated. Prevents double-evaluation within the same calendar day.
  static const String lastEvaluatedStreakDay = 'streak_last_evaluated_day_ms';

  /// Bool: true once the "you've earned notifications" earned-prompt has been
  /// shown (Plan 05-09 post_notifications_earned_step). Prevents re-showing
  /// after the user already acted on the dialog.
  // ignore: lines_longer_than_80_chars
  static const String earnedPromptShown = 'post_notifications_earned_prompt_shown';
}
