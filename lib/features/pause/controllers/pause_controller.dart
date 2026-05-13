import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/pause/models/pause_session.dart';
import 'package:not_to_do_list/features/pause/providers/pause_providers.dart';

/// Hand-written Riverpod Notifier (no @riverpod codegen — see
/// 01-01-SUMMARY.md for the analyzer-pin incompatibility).
///
/// Owns the cooldown timer, outcome resolution, and pause_events write.
/// Constructed by the family provider with the session args; see
/// [pauseControllerProvider] in pause_providers.dart.
class PauseController extends Notifier<PauseSession> {
  PauseController(this._arg);

  final PauseSessionArgs _arg;
  Timer? _timer;

  @override
  PauseSession build() {
    ref.onDispose(_cancelTimer);
    return PauseSession(
      entryId: _arg.entryId,
      packageName: _arg.packageName,
      blockMode: _arg.blockMode,
      triggeredAt: _arg.triggeredAt,
    );
  }

  /// Start (or restart) the cooldown at [seconds].
  ///
  /// Tapping a different chip while running RESTARTS at the new duration
  /// (D-04 — replace, not add).
  void startCooldown(int seconds) {
    _cancelTimer();
    state = state.copyWith(
      cooldownChosenSeconds: seconds,
      remainingMs: seconds * 1000,
      isComplete: false,
    );
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final remaining = (state.remainingMs ?? 0) - 100;
      if (remaining <= 0) {
        _cancelTimer();
        state = state.copyWith(remainingMs: 0);
        unawaited(_writeOutcomeAndClose(outcome: 0));
      } else {
        state = state.copyWith(remainingMs: remaining);
      }
    });
  }

  /// Cancel the cooldown. Writes outcome=1.
  ///
  /// cooldownChosenSeconds may be null if no chip was tapped before cancel.
  Future<void> cancel() async {
    _cancelTimer();
    await _writeOutcomeAndClose(outcome: 1);
  }

  /// Use anyway (soft entries only). Writes outcome=2.
  ///
  /// The UI enforces blockMode=='soft' by omitting this button for hard entries
  /// (PAUS-09, D-06). This assert is a developer-time backstop.
  Future<void> useAnyway() async {
    assert(
      _arg.blockMode == 'soft',
      'useAnyway must not be called for hard entries',
    );
    _cancelTimer();
    await _writeOutcomeAndClose(outcome: 2);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _writeOutcomeAndClose({required int outcome}) async {
    final repo = ref.read(pauseEventRepositoryProvider);
    await repo.insertOutcome(
      entryId: _arg.entryId,
      packageName: _arg.packageName,
      triggeredAt: _arg.triggeredAt,
      outcome: outcome,
      cooldownChosenSeconds: state.cooldownChosenSeconds,
    );
    state = state.copyWith(isComplete: true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await _arg.onClose();
  }
}
