import 'package:flutter/foundation.dart';

/// Immutable state for a single pause-screen session.
///
/// The PauseController holds and mutates this via copyWith.
@immutable
class PauseSession {
  const PauseSession({
    required this.entryId,
    required this.packageName,
    required this.blockMode,
    required this.triggeredAt,
    this.cooldownChosenSeconds,
    this.remainingMs,
    this.isComplete = false,
  });

  final int entryId;
  final String packageName;

  /// 'soft' or 'hard'.
  final String blockMode;

  final DateTime triggeredAt;

  /// Null until the user taps a cooldown chip.
  final int? cooldownChosenSeconds;

  /// Null until the user taps a cooldown chip. Counts down to 0.
  final int? remainingMs;

  /// True after outcome has been resolved (cancel/use-anyway/cooldown-done).
  /// The UI flips to DoneConfirmationCard (D-07) or navigates away.
  final bool isComplete;

  PauseSession copyWith({
    int? entryId,
    String? packageName,
    String? blockMode,
    DateTime? triggeredAt,
    Object? cooldownChosenSeconds = _sentinel,
    Object? remainingMs = _sentinel,
    bool? isComplete,
  }) {
    return PauseSession(
      entryId: entryId ?? this.entryId,
      packageName: packageName ?? this.packageName,
      blockMode: blockMode ?? this.blockMode,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      cooldownChosenSeconds: cooldownChosenSeconds == _sentinel
          ? this.cooldownChosenSeconds
          : cooldownChosenSeconds as int?,
      remainingMs: remainingMs == _sentinel
          ? this.remainingMs
          : remainingMs as int?,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PauseSession &&
        other.entryId == entryId &&
        other.packageName == packageName &&
        other.blockMode == blockMode &&
        other.triggeredAt == triggeredAt &&
        other.cooldownChosenSeconds == cooldownChosenSeconds &&
        other.remainingMs == remainingMs &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => Object.hash(
        entryId,
        packageName,
        blockMode,
        triggeredAt,
        cooldownChosenSeconds,
        remainingMs,
        isComplete,
      );
}

/// Sentinel to distinguish "not provided" from null in copyWith.
const _sentinel = Object();

/// Args record for the PauseController family — uniquely keys one session.
///
/// onClose is injected so tests can intercept SystemNavigator.pop.
typedef PauseSessionArgs = ({
  int entryId,
  String packageName,
  String blockMode,
  DateTime triggeredAt,
  Future<void> Function() onClose,
});
