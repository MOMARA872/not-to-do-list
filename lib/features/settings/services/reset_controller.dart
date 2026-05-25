// SETT-02: Reset all data — D-13 (calm-tone AlertDialog gate) + D-14 (scope).
//
// ResetController encapsulates the 5-step atomic reset sequence:
//   1. cancelDailyReminder() — kills the pending AlarmManager alarm BEFORE
//      prefs are cleared, so it cannot re-fire on a cleared pref state
//      (RESEARCH §Runtime State Inventory).
//   2. Drift transaction — wipes all 5 tables in FK-safe child-first order
//      (dailyCheckins → pauseEvents → dailyStreak → dailyUsageSummary →
//       blockList) per RESEARCH §Pattern 3 + §Example 3.
//   3. SharedPreferences.clear() — wipes every prefs key including the
//      onboarding-complete flag, per D-14 (NOT per-key remove — clears ALL).
//   4. Provider invalidation — forces all 5 prefs-backed AsyncNotifiers to
//      re-enter AsyncLoading *before* navigation so the Router redirect guard
//      re-reads the now-empty onboardingCompleteProvider and sends the user
//      to /onboarding/welcome (RESEARCH §Pitfall 2 — prevents pre-reset flash).
//   5. context.go('/onboarding/welcome') — explicit GoRouter navigation after
//      the above sequence; guarded by context.mounted per RESEARCH §Pattern 6.
//
// Constructor accepts a [ProviderContainer] (available via
// [ProviderScope.containerOf(context)] in the widget layer, or directly as a
// test [ProviderContainer]). This avoids depending on the sealed [Ref] /
// [WidgetRef] hierarchy — both are backed by the same [ProviderContainer].
//
// References: SETT-02 / D-13 / D-14 / Pitfall 2 / Runtime State Inventory.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/reminder/providers/reminder_providers.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:not_to_do_list/features/streak/providers/streak_threshold_provider.dart';
import 'package:not_to_do_list/platform/notification_api.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plain service class that owns the SETT-02 reset side-effect chain.
///
/// Designed to be constructed ad-hoc in the dialog confirm handler
/// (SettingsScreen) so it does not need to live as a Riverpod provider.
///
/// Obtain a [ProviderContainer] in the widget layer via:
/// ```dart
/// ProviderScope.containerOf(context, listen: false)
/// ```
class ResetController {
  ResetController(
    this._db,
    this._notificationApi,
    this._container,
  );

  final AppDatabase _db;
  final NotificationApi _notificationApi;
  final ProviderContainer _container;

  /// Executes the full reset sequence atomically.
  ///
  /// Ordering is load-bearing:
  ///   cancel alarm → Drift txn → prefs.clear → invalidate → go()
  Future<void> resetAll(BuildContext context) async {
    // Step 1: Cancel pending alarm FIRST so it cannot fire after prefs are
    // gone (RESEARCH §Runtime State Inventory).
    await _notificationApi.cancelDailyReminder();

    // Step 2: Single Drift transaction — child tables deleted before parent
    // (FK-safe, defensive even though CASCADE is enabled per RESEARCH §P3).
    await _db.transaction(() async {
      await _db.delete(_db.dailyCheckins).go();
      await _db.delete(_db.pauseEvents).go();
      await _db.delete(_db.dailyStreak).go();
      await _db.delete(_db.dailyUsageSummary).go();
      // Parent table last.
      await _db.delete(_db.blockList).go();
    });

    // Step 3: Wipe ALL SharedPreferences keys (D-14 — true clean slate,
    // including future-added keys).
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Step 4: Invalidate all prefs-backed providers BEFORE navigation so the
    // router redirect guard reads onboardingCompleteProvider = AsyncLoading and
    // then routes to /onboarding/welcome without a flash of pre-reset state
    // (RESEARCH §Pitfall 2).
    _container
      ..invalidate(onboardingCompleteProvider)
      ..invalidate(themeModeProvider)
      ..invalidate(reminderTimeProvider)
      ..invalidate(streakThresholdProvider)
      ..invalidate(postNotificationsGrantedProvider);

    // Step 5: Navigate to onboarding re-walk; guarded by mounted check
    // (RESEARCH §Pattern 6 — explicit go() avoids refresh-listener race).
    if (context.mounted) {
      context.go('/onboarding/welcome');
    }
  }
}
