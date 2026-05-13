import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/blocklist_broadcast_api.g.dart';

/// Hand-written provider (no @riverpod codegen — see 01-01-SUMMARY.md).
/// Used by:
///   - BlockListRepository (D-10 emit on insert/update/delete/insertMany)
///   - AccessibilityBlockedAppDetector (initialize / updateBlockList)
final Provider<BlocklistBroadcastApi> blocklistBroadcastApiProvider =
    Provider<BlocklistBroadcastApi>((ref) => BlocklistBroadcastApi());
