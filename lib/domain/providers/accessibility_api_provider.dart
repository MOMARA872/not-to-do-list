import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/accessibility_api.g.dart';

/// Hand-written provider (no @riverpod codegen — see 01-01-SUMMARY.md).
/// The Pigeon-generated AccessibilityApi client is constructed with no args;
/// the codec/messenger are bundled inside.
final Provider<AccessibilityApi> accessibilityApiProvider =
    Provider<AccessibilityApi>((ref) => AccessibilityApi());
