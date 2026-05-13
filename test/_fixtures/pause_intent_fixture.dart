// Phase 4 Plan 04-01 — Wave 0 shared fixture: pause Intent extras builder.
//
// Encodes the D-11 Intent extras contract so downstream tests never
// string-literal the key names directly.
//
// Consumed by:
//   - test/data/repositories/pause_event_repository_test.dart (Plan 04-07)
//   - test/features/pause/pause_controller_test.dart            (Plan 04-07)
//   - test/features/pause/pause_screen_test.dart                (Plan 04-07)
//
// Pure Dart — no Flutter imports — so it is safe for both widget tests
// and plain unit tests.

/// D-11 extra key: the package name of the blocked app.
const intentExtraBlockedPackage = 'extra_blocked_package';

/// D-11 extra key: the block_list row id for the triggered entry.
const intentExtraEntryId = 'extra_entry_id';

/// D-11 extra key: block mode string — `"soft"` or `"hard"`.
const intentExtraBlockMode = 'extra_block_mode';

/// D-11 extra key: milliseconds since epoch at which the intercept fired.
const intentExtraTriggeredAtMs = 'extra_triggered_at_ms';

/// Builds a [Map<String, Object>] of Intent extras that mirrors the D-11
/// contract emitted by `NotToDoAccessibilityService` when launching
/// `PauseActivity`.
///
/// [triggeredAtMs] defaults to the current wall-clock milliseconds when
/// omitted or null.
Map<String, Object> buildPauseIntentExtras({
  required int entryId,
  required String packageName,
  String blockMode = 'soft',
  int? triggeredAtMs,
}) {
  return {
    intentExtraEntryId: entryId,
    intentExtraBlockedPackage: packageName,
    intentExtraBlockMode: blockMode,
    intentExtraTriggeredAtMs:
        triggeredAtMs ?? DateTime.now().millisecondsSinceEpoch,
  };
}
