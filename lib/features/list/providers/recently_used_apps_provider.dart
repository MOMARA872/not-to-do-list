import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:not_to_do_list/domain/providers/app_picker_api_provider.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

/// Caller passes `daysBack` (e.g. 7 for the picker's "Recently used" section).
/// Returns an empty list if Usage Access is not granted (the Pigeon impl in
/// Plan 02-03 enforces the AppOps gate; T-2-03 silent-empty avoidance — the
/// caller MUST also check `PermissionStatusApi.isUsageAccessGranted()` and
/// surface the inline grant prompt when false).
final FutureProviderFamily<List<RecentApp>, int> recentlyUsedAppsProvider =
    FutureProvider.autoDispose.family<List<RecentApp>, int>(
  (ref, daysBack) async {
    final api = ref.watch(appPickerApiProvider);
    return api.recentlyUsedApps(daysBack);
  },
);
