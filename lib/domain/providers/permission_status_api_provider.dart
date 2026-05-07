import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/platform/permission_status_api.g.dart';

/// Pigeon channel singleton for the four permission status checks + Settings
/// deep-link launchers. Hand-written (no `@riverpod` codegen) to match the
/// Phase 1 deviation note in `01-01-SUMMARY.md`.
///
/// Tests override via:
/// `permissionStatusApiProvider.overrideWith(
///   (ref) => MockPermissionStatusApi(),
/// )`.
final Provider<PermissionStatusApi> permissionStatusApiProvider =
    Provider<PermissionStatusApi>((ref) => PermissionStatusApi());
