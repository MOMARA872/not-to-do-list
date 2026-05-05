import 'package:not_to_do_list/domain/blocked_app_detector.dart';

/// Kill-switch fallback per STACK.md "Stack patterns by variant: if Play review
/// rejects". Phase 1 ships the stub; this implementation lights up only if Play
/// rejects PLAY-08.
class UsageStatsPollingBlockedAppDetector implements BlockedAppDetector {
  @override
  Future<void> initialize(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Activated only as kill-switch fallback.');
  }

  @override
  Future<void> updateBlockList(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Activated only as kill-switch fallback.');
  }

  @override
  Stream<BlockedAppDetection> get detections =>
      const Stream<BlockedAppDetection>.empty();

  @override
  Future<bool> get isHealthy async => false;

  @override
  Future<void> dispose() async {}
}
