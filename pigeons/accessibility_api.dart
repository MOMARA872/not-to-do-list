import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/accessibility_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AccessibilityApi.g.kt',
    // See usage_api.dart for the FlutterError-redeclaration rationale.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'AccessibilityApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
@HostApi()
abstract class AccessibilityApi {
  /// True iff our specific service appears in
  /// AccessibilityManager.getEnabledAccessibilityServiceList().
  /// NOTE: this only reports state. The API explicitly does NOT expose
  /// autonomous-action APIs per PLAY-02.
  @async
  bool isServiceEnabled();

  /// Open Settings.ACTION_ACCESSIBILITY_SETTINGS deep-link (Phase 2 will use
  /// this).
  void openAccessibilitySettings();
}
