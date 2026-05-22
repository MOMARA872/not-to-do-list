import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';

/// Hand-written `AsyncNotifier` (no riverpod_annotation codegen) that owns
/// the re-evaluation contract for the POST_NOTIFICATIONS permission state.
///
/// Consumed by:
///   - Plan 05-07 reminder-off banner (gated on `!granted`)
///   - Plan 05-08 earned prompt screen (drives dialog + resume re-poll)
///
/// Tests override via:
/// `postNotificationsGrantedProvider.overrideWith(
///   PostNotificationsGrantedNotifier.new,
/// )` with `permissionStatusApiProvider` also overridden.
class PostNotificationsGrantedNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final api = ref.read(permissionStatusApiProvider);
    return api.isPostNotificationsGranted();
  }

  /// Re-evaluates the permission state. Called by Plan 05-08
  /// PostNotificationsEarnedStep on AppLifecycleState.resumed to observe
  /// the post-dialog grant outcome (T-05-16 re-poll contract).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await build());
  }
}

final AsyncNotifierProvider<PostNotificationsGrantedNotifier, bool>
    postNotificationsGrantedProvider =
    AsyncNotifierProvider<PostNotificationsGrantedNotifier, bool>(
  PostNotificationsGrantedNotifier.new,
);
