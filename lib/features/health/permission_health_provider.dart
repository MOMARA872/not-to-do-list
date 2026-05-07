import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot of the four signals that decide whether tracking is "healthy":
/// the three runtime permissions plus the OS-fingerprint match flag (ONBD-07).
class PermissionHealth {
  const PermissionHealth({
    required this.usageAccess,
    required this.accessibilityService,
    required this.batteryOptExempt,
    required this.fingerprintChanged,
  });

  final bool usageAccess;
  final bool accessibilityService;
  final bool batteryOptExempt;
  final bool fingerprintChanged;

  /// True iff all three permissions are granted AND the OS fingerprint
  /// hasn't changed since the last baseline (REL-02).
  bool get allHealthy =>
      usageAccess &&
      accessibilityService &&
      batteryOptExempt &&
      !fingerprintChanged;
}

/// Hand-written `AsyncNotifier` (no riverpod_annotation codegen) that owns the
/// re-evaluation contract for the three runtime permissions plus the
/// `Build.FINGERPRINT` change flag (ONBD-07). Plan 02-09 wires
/// [refresh] into `AppLifecycleState.resumed` and cold-launch.
class PermissionHealthNotifier extends AsyncNotifier<PermissionHealth> {
  @override
  Future<PermissionHealth> build() => _evaluate();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _evaluate());
  }

  /// Called by onboarding completion + banner re-entry to clear the
  /// `fingerprintChanged` flag once the user has re-verified permissions
  /// after an OS update.
  Future<void> persistCurrentFingerprint() async {
    final api = ref.read(permissionStatusApiProvider);
    final prefs = await SharedPreferences.getInstance();
    final currentFp = await api.currentBuildFingerprint();
    await prefs.setString(OnboardingKeys.lastKnownFingerprint, currentFp);
    await refresh();
  }

  Future<PermissionHealth> _evaluate() async {
    final api = ref.read(permissionStatusApiProvider);
    final prefs = await SharedPreferences.getInstance();
    final storedFp = prefs.getString(OnboardingKeys.lastKnownFingerprint);
    final currentFp = await api.currentBuildFingerprint();
    var fingerprintChanged = false;
    if (storedFp == null) {
      // First run after install — record without flagging
      // (RESEARCH lines 568-576).
      await prefs.setString(OnboardingKeys.lastKnownFingerprint, currentFp);
    } else if (storedFp != currentFp) {
      fingerprintChanged = true;
    }
    return PermissionHealth(
      usageAccess: await api.isUsageAccessGranted(),
      accessibilityService: await api.isAccessibilityServiceEnabled(),
      batteryOptExempt: await api.isIgnoringBatteryOptimizations(),
      fingerprintChanged: fingerprintChanged,
    );
  }
}

final AsyncNotifierProvider<PermissionHealthNotifier, PermissionHealth>
    permissionHealthProvider =
    AsyncNotifierProvider<PermissionHealthNotifier, PermissionHealth>(
  PermissionHealthNotifier.new,
);
