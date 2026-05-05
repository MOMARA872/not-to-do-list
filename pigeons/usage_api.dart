// Pigeon HostApi inputs require `abstract class` even for single-method APIs.
// ignore_for_file: one_member_abstracts

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/usage_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/UsageApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
class UsagePackageStat {
  UsagePackageStat({
    required this.packageName,
    required this.foregroundSeconds,
    required this.launchCount,
  });
  final String packageName;
  final int foregroundSeconds;
  final int launchCount;
}

@HostApi()
abstract class UsageApi {
  /// Phase 3 will implement this. Phase 1 ships interface only.
  /// Returns daily-bucketed per-package foreground time over
  /// [startEpochMs, endEpochMs].
  @async
  List<UsagePackageStat> queryRange(int startEpochMs, int endEpochMs);
}
