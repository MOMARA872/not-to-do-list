import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/usage_api.g.dart';

/// Pigeon channel singleton for [UsageApi]. Hand-written (no `@riverpod`
/// codegen) per Plan 01-01's analyzer-conflict deviation. Mirrors
/// [appPickerApiProvider] verbatim.
///
/// Tests override via:
/// `usageApiProvider.overrideWith((ref) => MockUsageApi())`.
final Provider<UsageApi> usageApiProvider =
    Provider<UsageApi>((ref) => UsageApi());
