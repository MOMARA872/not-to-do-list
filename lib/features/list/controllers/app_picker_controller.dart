import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search-bar query (debounced) + Show-all-system-apps toggle. Both bits of
/// state are session-only — never persisted.
class AppPickerState {
  const AppPickerState({this.query = '', this.showSystemApps = false});

  final String query;
  final bool showSystemApps;

  AppPickerState copyWith({String? query, bool? showSystemApps}) =>
      AppPickerState(
        query: query ?? this.query,
        showSystemApps: showSystemApps ?? this.showSystemApps,
      );
}

class AppPickerController extends Notifier<AppPickerState> {
  Timer? _debounce;

  @override
  AppPickerState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const AppPickerState();
  }

  /// Debounces 150 ms after the last keystroke before publishing the new
  /// query. Stored lower-case so the per-row substring match below can
  /// be case-insensitive without re-normalising on every comparison.
  void setQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      state = state.copyWith(query: q.toLowerCase());
    });
  }

  void toggleShowAll() =>
      state = state.copyWith(showSystemApps: !state.showSystemApps);
}

final NotifierProvider<AppPickerController, AppPickerState>
    appPickerControllerProvider =
    NotifierProvider<AppPickerController, AppPickerState>(
  AppPickerController.new,
);
