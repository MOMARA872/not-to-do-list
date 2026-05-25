// Theme mode persistence provider — Phase 6 SETT-04 (D-07 lock).
// Stores ThemeMode as an int in SharedPreferences under
// OnboardingKeys.themeMode (0=system, 1=light, 2=dark).
// Hand-written AsyncNotifier (no riverpod_annotation codegen) matching the
// Phase 1 deviation noted in 01-01-SUMMARY.md. Mirrors the shape of
// streak_threshold_provider.dart exactly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/onboarding/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pure top-level helper — exposed for unit tests.
/// Decodes stored int to [ThemeMode].
/// Fail-safe: any unrecognised value returns [ThemeMode.system].
ThemeMode _decode(int raw) {
  switch (raw) {
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Pure top-level helper — exposed for unit tests.
/// Encodes [ThemeMode] to int for SharedPreferences storage.
int _encode(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 1;
    case ThemeMode.dark:
      return 2;
    case ThemeMode.system:
      return 0;
  }
}

/// AsyncNotifier that owns the app-wide theme mode.
///
/// Default is [ThemeMode.system] (0) per D-06.
/// Reads/writes [OnboardingKeys.themeMode] in SharedPreferences.
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getInt(OnboardingKeys.themeMode) ?? 0);
  }

  /// Persists [mode] to prefs and updates state synchronously per D-07.
  Future<void> set(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OnboardingKeys.themeMode, _encode(mode));
    state = AsyncValue.data(mode);
  }
}

final AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
