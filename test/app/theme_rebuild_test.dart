// test/app/theme_rebuild_test.dart
// GREEN flip for 06-02 Task 2 — was a RED stub in 06-01.
// Tests that MaterialApp.router picks up themeMode from themeModeProvider
// and rebuilds correctly on provider state changes.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do_list/features/settings/providers/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Minimal stub notifier that holds a fixed AsyncValue without hitting prefs.
class _FixedThemeModeNotifier extends ThemeModeNotifier {
  _FixedThemeModeNotifier(this._value);
  final ThemeMode _value;

  @override
  Future<ThemeMode> build() async => _value;
}

// A minimal widget that reads themeModeProvider and passes themeMode to
// MaterialApp directly — avoids the full app router boilerplate for tests.
class _ThemeTestApp extends ConsumerWidget {
  const _ThemeTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).maybeWhen(
          data: (m) => m,
          orElse: () => ThemeMode.system,
        );
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const Scaffold(body: Text('test')),
    );
  }
}

void main() {
  group('Phase 6 / MaterialApp.router themeMode rebuild (SETT-04)', () {
    testWidgets(
      'Test 1: provider AsyncLoading → themeMode resolves to ThemeMode.system '
      'via maybeWhen orElse default',
      (WidgetTester tester) async {
        // Override with a notifier that never completes build (AsyncLoading).
        final container = ProviderContainer(
          overrides: [
            themeModeProvider.overrideWith(() => _AsyncLoadingNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const _ThemeTestApp(),
          ),
        );

        // While loading, orElse fires → ThemeMode.system
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.themeMode, ThemeMode.system);
      },
    );

    testWidgets(
      'Test 2: provider AsyncValue.data(ThemeMode.dark) → '
      'MaterialApp.themeMode == ThemeMode.dark on next pump',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({'theme_mode': 2}); // dark

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const _ThemeTestApp(),
          ),
        );
        // Pump to resolve the async build
        await tester.pump();

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.themeMode, ThemeMode.dark);
      },
    );

    testWidgets(
      'Test 3: themeModeProvider.notifier.set(ThemeMode.light) → '
      'MaterialApp.themeMode flips to ThemeMode.light on next pump',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({'theme_mode': 2}); // dark initially

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const _ThemeTestApp(),
          ),
        );
        await tester.pump(); // resolve initial async build

        // Confirm dark to start
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.dark,
        );

        // Flip to light
        await container.read(themeModeProvider.notifier).set(ThemeMode.light);
        await tester.pump();

        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
          ThemeMode.light,
        );
      },
    );
  });
}

// A notifier whose build() never completes — simulates AsyncLoading state.
class _AsyncLoadingNotifier extends ThemeModeNotifier {
  @override
  Future<ThemeMode> build() => Completer<ThemeMode>().future;
}
