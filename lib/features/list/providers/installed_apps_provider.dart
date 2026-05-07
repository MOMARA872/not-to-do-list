import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/app_picker_api_provider.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

/// One-shot fetch of all installed apps via the Pigeon channel. Auto-disposes
/// when the picker closes; re-runs on next picker open. Visibility scope is
/// governed by Phase 1's `<queries>` + LAUNCHER manifest entry — no
/// `QUERY_ALL_PACKAGES` permission is requested.
final FutureProvider<List<InstalledApp>> installedAppsProvider =
    FutureProvider.autoDispose<List<InstalledApp>>((ref) async {
  final api = ref.watch(appPickerApiProvider);
  return api.listInstalledApps();
});
