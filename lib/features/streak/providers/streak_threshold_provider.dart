import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D-08: Global streak threshold (minutes per day) below which a day is
/// counted as a streak success. Stored as raw int under
/// [StreakKeys.streakThresholdMinutes].
///
/// Default 5 per STRK-02 lock and D-08.
///
/// Valid range [1, 60] (v1 design decision):
///   - Below 1 makes no sense (zero tolerance is not useful).
///   - Above 60 (1 hour) is past the point where "streak" applies
///     to deliberate avoidance behavior.
///
/// The [clampStreakThreshold] helper is exported for direct unit testing and
/// for future callers that write to the prefs key programmatically.
///
/// Hand-written AsyncNotifier (no riverpod_annotation codegen) to match the
/// Phase 1 deviation note in `01-01-SUMMARY.md`.

/// Pure helper — exposed for unit tests.
/// Clamps [raw] to the valid [1, 60] range (T-05-36 mitigation — defense
/// in depth at the provider boundary, even if the picker UI is bypassed).
int clampStreakThreshold(int raw) => raw.clamp(1, 60);

/// AsyncNotifier that owns the global streak-break threshold in minutes.
class StreakThresholdNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StreakKeys.streakThresholdMinutes) ?? 5;
  }

  /// Clamps [minutes] to [1, 60] before writing prefs.
  /// No alarm-re-arm side effect — the rollover service reads the threshold
  /// on every lazy evaluation (AppLifecycleState.resumed), so the next
  /// resume picks up the new value naturally.
  Future<void> set(int minutes) async {
    final clamped = clampStreakThreshold(minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StreakKeys.streakThresholdMinutes, clamped);
    state = AsyncValue.data(clamped);
  }
}

final AsyncNotifierProvider<StreakThresholdNotifier, int>
    streakThresholdProvider =
    AsyncNotifierProvider<StreakThresholdNotifier, int>(
  StreakThresholdNotifier.new,
);
