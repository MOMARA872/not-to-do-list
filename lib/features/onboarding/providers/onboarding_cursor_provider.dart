import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cursor: 0 = welcome, 1 = quick-add, 2 = usage-access step,
/// 3 = accessibility, 4 = battery-opt. (Funnel proper has 3 steps; cursor
/// includes welcome + quick-add for resume coherence.)
///
/// Hand-written `AsyncNotifier` (no riverpod_annotation codegen).
class OnboardingCursorNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(OnboardingKeys.cursor) ?? 0;
  }

  Future<void> set(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OnboardingKeys.cursor, step);
    state = AsyncValue.data(step);
  }

  Future<void> advance() async {
    final current = state.value ?? 0;
    await set(current + 1);
  }
}

final AsyncNotifierProvider<OnboardingCursorNotifier, int>
    onboardingCursorProvider =
    AsyncNotifierProvider<OnboardingCursorNotifier, int>(
  OnboardingCursorNotifier.new,
);
