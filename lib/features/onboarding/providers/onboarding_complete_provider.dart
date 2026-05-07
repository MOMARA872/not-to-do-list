import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sticky bool — true once the user has finished the install-time funnel.
/// Hand-written `AsyncNotifier` (no riverpod_annotation codegen) so Phase 1's
/// analyzer-pin deviation continues to apply.
class OnboardingCompleteNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(OnboardingKeys.complete) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingKeys.complete, true);
    state = const AsyncValue.data(true);
  }

  /// Allow tests + re-entry from health-check banner to reset state.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingKeys.complete, false);
    state = const AsyncValue.data(false);
  }
}

final AsyncNotifierProvider<OnboardingCompleteNotifier, bool>
    onboardingCompleteProvider =
    AsyncNotifierProvider<OnboardingCompleteNotifier, bool>(
  OnboardingCompleteNotifier.new,
);
