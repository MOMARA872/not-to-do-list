import 'package:flutter/material.dart';

abstract class AppTheme {
  /// Seed color: deep forest green. Adult self-control tone, not playful.
  /// Sourced from UI-SPEC §Color (`Color(0xFF2D6A4F)`).
  static const Color seed = Color(0xFF2D6A4F);

  /// Static fallback ThemeData used when dynamic_color is unavailable
  /// (Android < 12) or `lightDynamic == null` from `DynamicColorBuilder`.
  /// Plan 02-09 will wire `DynamicColorBuilder` in `lib/app.dart` and pass
  /// the harmonized scheme via the optional [dynamic] parameter.
  static ThemeData light({ColorScheme? dynamic}) => ThemeData(
        useMaterial3: true,
        colorScheme: dynamic ?? ColorScheme.fromSeed(seedColor: seed),
        textTheme: _textTheme,
      );

  static ThemeData dark({ColorScheme? dynamic}) => ThemeData(
        useMaterial3: true,
        colorScheme: dynamic ??
            ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
        textTheme: _textTheme,
      );

  /// Phase 2 typography — UI-SPEC explicitly fixes labelSmall at 14sp
  /// (NOT the M3 default 11sp).
  static const TextTheme _textTheme = TextTheme(
    labelSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  );
}
