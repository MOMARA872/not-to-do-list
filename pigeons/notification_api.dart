import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/notification_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/nottodo/not_to_do_list/platform/NotificationApi.g.kt',
    // See usage_api.dart for the FlutterError-redeclaration rationale.
    kotlinOptions: KotlinOptions(
      package: 'com.nottodo.not_to_do_list.platform',
      errorClassName: 'NotificationApiError',
    ),
    dartPackageName: 'not_to_do_list',
  ),
)
@HostApi()
abstract class NotificationApi {
  /// Phase 5 will implement. Schedules a daily reminder at the next
  /// occurrence of [hour]:[minute] in the device's home timezone via
  /// setExactAndAllowWhileIdle.
  @async
  void scheduleDailyReminder(int hour, int minute);

  @async
  void cancelDailyReminder();
}
