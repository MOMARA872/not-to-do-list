// test/features/settings/theme_mode_provider_test.dart
// GREEN flip for 06-02 Task 1 — was a RED stub in 06-01.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Phase 6 / themeModeProvider (SETT-04)', () {
    test(
      'default ThemeMode.system when no prefs value stored',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final result = await container.read(themeModeProvider.future);
        expect(result, ThemeMode.system);
      },
    );

    test(
      'persists ThemeMode int across notifier rebuild',
      () async {
        // decode(1) == light; decode(2) == dark; decode(0) == system
        SharedPreferences.setMockInitialValues({'theme_mode': 1});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final light = await container.read(themeModeProvider.future);
        expect(light, ThemeMode.light);

        // Update to dark
        await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
        expect(container.read(themeModeProvider).value, ThemeMode.dark);

        // Verify prefs were written
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), 2);
      },
    );

    test(
      'encode/decode round-trip: 0=system 1=light 2=dark',
      () async {
        // Test unknown int → system (fail-safe)
        SharedPreferences.setMockInitialValues({'theme_mode': 99});
        final container1 = ProviderContainer();
        addTearDown(container1.dispose);
        expect(await container1.read(themeModeProvider.future), ThemeMode.system);

        // Verify all three expected mappings by setting each value and
        // checking the prefs int that gets written back.
        SharedPreferences.setMockInitialValues({});
        final container2 = ProviderContainer();
        addTearDown(container2.dispose);

        await container2.read(themeModeProvider.notifier).set(ThemeMode.system);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), 0); // encode(system) == 0

        await container2.read(themeModeProvider.notifier).set(ThemeMode.light);
        expect(prefs.getInt('theme_mode'), 1); // encode(light) == 1

        await container2.read(themeModeProvider.notifier).set(ThemeMode.dark);
        expect(prefs.getInt('theme_mode'), 2); // encode(dark) == 2
      },
    );

    test(
      'set(ThemeMode.dark) writes int 2 and state becomes AsyncValue.data(ThemeMode.dark)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Ensure provider is initialised first
        await container.read(themeModeProvider.future);

        await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
        final state = container.read(themeModeProvider);
        expect(state, equals(const AsyncValue<ThemeMode>.data(ThemeMode.dark)));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), 2);
      },
    );
  });
}
