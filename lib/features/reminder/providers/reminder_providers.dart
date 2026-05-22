import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/notification_api_provider.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AsyncNotifier that owns the daily reminder time as minutes-since-midnight
/// encoded as `hour * 60 + minute` (e.g. 21:00 → 1260).
///
/// Default 1260 (21:00) per D-09 lock.
///
/// set(hm): atomically (1) writes prefs, (2) cancels existing alarm,
/// (3) schedules new alarm. The cancel-before-schedule order prevents
/// a race where two alarms could overlap (NOTF-01, T-05-34).
///
/// Hand-written AsyncNotifier (no riverpod_annotation codegen) to match the
/// Phase 1 deviation note in `01-01-SUMMARY.md`.
class ReminderTimeNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StreakKeys.reminderHourMinute) ?? 1260;
  }

  Future<void> set(int hm) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StreakKeys.reminderHourMinute, hm);
    final api = ref.read(notificationApiProvider);
    await api.cancelDailyReminder();
    await api.scheduleDailyReminder(hm ~/ 60, hm % 60);
    state = AsyncValue.data(hm);
  }
}

final AsyncNotifierProvider<ReminderTimeNotifier, int> reminderTimeProvider =
    AsyncNotifierProvider<ReminderTimeNotifier, int>(
  ReminderTimeNotifier.new,
);
