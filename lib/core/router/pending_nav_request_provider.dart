import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// Riverpod nav-signal used by [BlockListRepository] to trigger one-time
/// navigation from outside the widget tree (NOTF-06 earned-prompt fire-once).
///
/// Option A pattern (cleaner Riverpod vs. passing BuildContext):
/// - BlockListRepository writes the route string after the first insert.
/// - HomeScreen has a `ref.listen` that calls `context.go(route)` on non-null,
///   then resets this provider back to null so it does not re-fire.
///
/// Lifecycle: set to non-null exactly once (after first block_list insert with
/// earnedPromptShown=false and isPostNotificationsGranted=false); HomeScreen
/// listener clears to null after consuming.
final StateProvider<String?> pendingNavRequestProvider =
    StateProvider<String?>((ref) => null);
