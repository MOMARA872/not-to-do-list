import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/app_picker_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/AppPickerApi.g.kt',
    // See usage_api.dart for the FlutterError-redeclaration rationale.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'AppPickerApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
class InstalledApp {
  InstalledApp({
    required this.packageName,
    required this.displayName,
    required this.isSystemApp,
    required this.hasLauncherIntent,
  });
  final String packageName;
  final String displayName;
  final bool isSystemApp; // ApplicationInfo.FLAG_SYSTEM
  final bool hasLauncherIntent; // resolved via queryIntentActivities(LAUNCHER)
}

class RecentApp {
  RecentApp({
    required this.packageName,
    required this.totalForegroundSeconds,
  });
  final String packageName;
  final int totalForegroundSeconds;
}

@HostApi()
abstract class AppPickerApi {
  /// Returns ALL installed apps; Dart-side filter on `isSystemApp && !hasLauncherIntent`
  /// implements the default "hide non-launchable system apps" view (T-2-01 mitigation).
  /// Visibility scope is governed by Phase 1's <queries> + LAUNCHER manifest entry —
  /// no QUERY_ALL_PACKAGES permission is requested.
  @async
  List<InstalledApp> listInstalledApps();

  /// Returns top apps by foreground seconds in the trailing window.
  /// Caller is responsible for first checking that Usage Access is granted via
  /// PermissionStatusApi.isUsageAccessGranted() — this method returns an empty list
  /// (NOT throw) if not granted, to keep the Dart code branch-light.
  @async
  List<RecentApp> recentlyUsedApps(int daysBack);

  /// Returns null if the package is not installed or the icon couldn't be encoded.
  /// Encoded as PNG bytes. Decoded on the Dart side via Image.memory.
  @async
  Uint8List? getApplicationIconPng(String packageName);
}
