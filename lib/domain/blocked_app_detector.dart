/// The single seam between "what the rest of the app needs to know about
/// blocked-app launches" and "how Android tells us about them."
///
/// REL-05 / PLAY-02: This interface deliberately exposes ONLY the read-side
/// (a stream of detected events). It does not expose any autonomous-action
/// APIs (the AccessibilityService capabilities that click, type, navigate, or
/// fire gestures on the user's behalf). The Phase 4 a11y implementation
/// honors that promise; the fallback polling implementation cannot violate
/// it because UsageStatsManager has no such APIs in the first place.
abstract class BlockedAppDetector {
  /// Cold-start: load the in-memory block list from the database.
  /// Called by the Riverpod provider on first read.
  Future<void> initialize(Set<String> blockedPackageNames);

  /// Notify the detector that the user-defined block list changed.
  /// (Phase 4: a11y impl forwards this via LocalBroadcast to the native
  /// service.)
  Future<void> updateBlockList(Set<String> blockedPackageNames);

  /// Stream of blocked-app launches. Emits a `BlockedAppDetection` for every
  /// in-list foregrounding event. May be empty for hours at a time.
  Stream<BlockedAppDetection> get detections;

  /// Whether the detector is currently armed (a11y permission granted,
  /// polling running, etc.). The health-check UI in Phase 2 reads this.
  Future<bool> get isHealthy;

  /// Free resources (called when Riverpod tears down the provider).
  Future<void> dispose();
}

class BlockedAppDetection {
  const BlockedAppDetection({
    required this.packageName,
    required this.detectedAt,
    required this.source,
  });
  final String packageName;
  final DateTime detectedAt;
  final BlockedAppDetectionSource source;
}

enum BlockedAppDetectionSource {
  /// Fired by AccessibilityService TYPE_WINDOW_STATE_CHANGED (Phase 4).
  accessibilityService,

  /// Fired by UsageStatsManager polling (kill-switch fallback).
  usageStatsPolling,
}
