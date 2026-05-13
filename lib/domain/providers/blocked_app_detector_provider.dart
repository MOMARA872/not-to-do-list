import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/data/detectors/accessibility_blocked_app_detector.dart';
import 'package:not_to_do_list/data/detectors/usage_stats_polling_blocked_app_detector.dart';
import 'package:not_to_do_list/domain/blocked_app_detector.dart';
import 'package:not_to_do_list/domain/providers/accessibility_api_provider.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/blocklist_broadcast_provider.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

/// Hand-written providers (no `@riverpod` codegen) — see Plan 01-01 SUMMARY:
/// `riverpod_annotation`/`riverpod_generator` were dropped in Phase 1 because
/// their analyzer pins conflict with `pigeon 26.3.4` + Flutter 3.41
/// (`meta 1.17`). Reintroduce when the ecosystem converges on analyzer 12+.

/// Flag that decides which detector ships. In Phase 1 this is a constant
/// `true`; in Phase 6 we may flip it to a settings toggle. Tests override it
/// via `overrideWith` to exercise REL-05's swap contract.
final Provider<bool> useAccessibilityServiceProvider = Provider<bool>(
  (ref) => true,
);

/// The single Riverpod entry point. The rest of the app depends ONLY on this.
/// Swapping the implementation requires changing one line in this file.
final Provider<BlockedAppDetector> blockedAppDetectorProvider =
    Provider<BlockedAppDetector>((ref) {
      final useA11y = ref.watch(useAccessibilityServiceProvider);
      if (useA11y) {
        final broadcaster = ref.read(blocklistBroadcastApiProvider);
        final accessibilityApi = ref.read(accessibilityApiProvider);
        // snapshotProvider is a lazy closure — the repo is only read when
        // initialize() or updateBlockList() is actually called, not at
        // construction time. This prevents the provider from eagerly resolving
        // the database during tests that only verify the detector type.
        return AccessibilityBlockedAppDetector(
          broadcaster: broadcaster,
          accessibilityApi: accessibilityApi,
          snapshotProvider: () async {
            final repo = ref.read(blockListRepoProvider);
            final all = await repo.getAll();
            return all
                .where((e) => e.kind == 0 && e.packageName != null)
                .map(
                  (e) => BlockListEntrySnapshot(
                    entryId: e.id,
                    packageName: e.packageName!,
                    blockMode: e.blockMode,
                    scheduleStartMinutes: e.scheduleStartMinutes,
                    scheduleEndMinutes: e.scheduleEndMinutes,
                    scheduleWeekdayMask: e.scheduleWeekdayMask,
                  ),
                )
                .toList();
          },
        );
      } else {
        return UsageStatsPollingBlockedAppDetector();
      }
    });
