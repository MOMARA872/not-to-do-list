import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/permission_status_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/PermissionStatusApi.g.kt',
    // See usage_api.dart for the FlutterError-redeclaration rationale.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'PermissionStatusApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
@HostApi()
abstract class PermissionStatusApi {
  /// True iff AppOpsManager.OPSTR_GET_USAGE_STATS == MODE_ALLOWED for our package.
  @async
  bool isUsageAccessGranted();

  /// True iff our specific accessibility service appears in
  /// AccessibilityManager.getEnabledAccessibilityServiceList(). Bundled here
  /// (in addition to AccessibilityApi.isServiceEnabled() from Phase 1) so the
  /// resume-detection round-trip can fetch all four checks in one call.
  @async
  bool isAccessibilityServiceEnabled();

  /// True iff PowerManager.isIgnoringBatteryOptimizations(packageName) is true.
  @async
  bool isIgnoringBatteryOptimizations();

  /// Build.FINGERPRINT — used to detect OS upgrade between launches (ONBD-07).
  @async
  String currentBuildFingerprint();

  /// Build.MANUFACTURER (lowercased on the Kotlin side) — used to look up
  /// per-OEM fallback ComponentNames + dontkillmyapp.com slug (REL-03).
  @async
  String currentManufacturer();

  /// Launches Settings.ACTION_USAGE_ACCESS_SETTINGS, with resolveActivity()
  /// guard + ACTION_APPLICATION_DETAILS_SETTINGS fallback (T-2-02 mitigation).
  @async
  void openUsageAccessSettings();

  /// Launches Settings.ACTION_ACCESSIBILITY_SETTINGS, with resolveActivity()
  /// guard + ACTION_APPLICATION_DETAILS_SETTINGS fallback (T-2-02 mitigation).
  @async
  void openAccessibilitySettings();

  /// Launches Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS with
  /// `package:` data Uri, with resolveActivity() guard + ACTION_IGNORE_*
  /// fallback (T-2-02 mitigation).
  @async
  void openBatteryOptSettings();
}
