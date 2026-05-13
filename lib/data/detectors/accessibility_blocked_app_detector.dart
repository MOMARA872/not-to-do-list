import 'package:not_to_do_list/domain/blocked_app_detector.dart';
import 'package:not_to_do_list/platform/accessibility_api.g.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

/// Phase 4 Plan 04-04 implementation. D-10 / D-16 / REL-05.
///
/// initialize / updateBlockList route through the BlocklistBroadcastApi
/// Pigeon channel — Kotlin side fires a LOCAL broadcast that the
/// AccessibilityService (Plan 04-05) consumes to refresh its in-memory
/// Map&lt;String, ScheduleSlice&gt;.
///
/// detections stays Stream.empty() — the consumer is the Intent path
/// (service launches PauseActivity directly), NOT the Stream. The Stream
/// is reserved for future analytics surfaces explicitly out of v1.
///
/// isHealthy reads the real AccessibilityApi.isServiceEnabled() — flips
/// from Phase 1 hardcoded false to the live AccessibilityManager state
/// (Plan 04-03 wired the underlying Pigeon impl).
///
/// PLAY-02: this Dart file contains no autonomous-action AccessibilityService
/// APIs (the BlockedAppDetector interface in lib/domain/ does not expose them
/// either — REL-05 invariant).
class AccessibilityBlockedAppDetector implements BlockedAppDetector {
  AccessibilityBlockedAppDetector({
    required BlocklistBroadcastApi broadcaster,
    required AccessibilityApi accessibilityApi,
    required Future<List<BlockListEntrySnapshot>> Function() snapshotProvider,
  })  : _broadcaster = broadcaster,
        _accessibilityApi = accessibilityApi,
        _snapshotProvider = snapshotProvider;

  final BlocklistBroadcastApi _broadcaster;
  final AccessibilityApi _accessibilityApi;
  final Future<List<BlockListEntrySnapshot>> Function() _snapshotProvider;

  @override
  Future<void> initialize(Set<String> blockedPackageNames) async {
    // D-10: publish current snapshot on initialize so the service's in-memory
    // map is populated even if no user mutation has happened since service
    // start. The Set<String> argument is unused (Phase 1 interface backward
    // compat) — we read the full snapshot from the injected provider so the
    // service receives schedule + blockMode metadata, not just package names.
    await _broadcaster.publishBlockList(await _snapshotProvider());
  }

  @override
  Future<void> updateBlockList(Set<String> blockedPackageNames) async {
    await _broadcaster.publishBlockList(await _snapshotProvider());
  }

  @override
  Stream<BlockedAppDetection> get detections =>
      const Stream<BlockedAppDetection>.empty();

  @override
  Future<bool> get isHealthy => _accessibilityApi.isServiceEnabled();

  @override
  Future<void> dispose() async {}
}
