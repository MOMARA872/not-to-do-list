import 'package:not_to_do_list/domain/blocked_app_detector.dart';

/// Phase 4 fills the body. Phase 1 ships an UnimplementedError stub so the
/// provider switch compiles and `flutter analyze` passes.
class AccessibilityBlockedAppDetector implements BlockedAppDetector {
  @override
  Future<void> initialize(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Phase 4 will implement.');
  }

  @override
  Future<void> updateBlockList(Set<String> blockedPackageNames) async {
    throw UnimplementedError('Phase 4 will implement.');
  }

  @override
  Stream<BlockedAppDetection> get detections =>
      const Stream<BlockedAppDetection>.empty();

  @override
  Future<bool> get isHealthy async => false;

  @override
  Future<void> dispose() async {}
}
