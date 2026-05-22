import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/schedule/streak_day.dart';
import 'package:not_to_do_list/domain/streak/streak_rollover_service_providers.dart';
import 'package:not_to_do_list/features/checkin/providers/checkin_providers.dart';

/// Notifier that owns the single-transaction check-in submit + post-rollover
/// trigger. Screen observes the state via `ref.listen` to surface errors.
///
/// Hand-written Riverpod Notifier (no @riverpod codegen — see
/// 01-01-SUMMARY.md for the analyzer-pin incompatibility).
class CheckinController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue<void>.data(null);

  /// Submit all answered entries (from [checkinAnswersProvider]) in a single
  /// Drift transaction (D-03 — one write, atomic), then re-trigger the streak
  /// rollover service so badges update before returning to Home.
  ///
  /// On success: state becomes AsyncData(null).
  /// On error:   state becomes AsyncError with the caught exception.
  Future<void> submit() async {
    final answers = ref.read(checkinAnswersProvider);
    if (answers.isEmpty) return;

    state = const AsyncValue<void>.loading();
    try {
      final db = ref.read(databaseProvider);
      final dao = db.dailyCheckinsDao;
      final today = streakDayFor(DateTime.now());
      final now = DateTime.now();

      // D-03: write ALL answered entries in ONE Drift transaction.
      await db.transaction(() async {
        for (final entry in answers.entries) {
          await dao.upsert(
            entryId: entry.key,
            day: today,
            avoided: entry.value,
            answeredAt: now,
          );
        }
      });

      // Trigger streak rollover so badges refresh before Home opens.
      await ref.read(streakRolloverServiceProvider.notifier).rollover();

      state = const AsyncValue<void>.data(null);
    } on Object catch (e, st) {
      state = AsyncValue<void>.error(e, st);
    }
  }
}

/// Provider for [CheckinController].
final NotifierProvider<CheckinController, AsyncValue<void>>
    checkinControllerProvider =
    NotifierProvider<CheckinController, AsyncValue<void>>(
  CheckinController.new,
);
