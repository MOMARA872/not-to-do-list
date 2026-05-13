import 'package:flutter/material.dart';

/// Renders the blocked app's display name as the hero (D-03).
///
/// Rendered only when reasonNote is null or empty. Displays the app's
/// display name in M3 DisplayMedium with a trailing period: "Instagram."
/// NO quote-card chrome, NO app icon, NO subcaption.
class AppNameHero extends StatelessWidget {
  const AppNameHero({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$displayName.',
      style: theme.textTheme.displayMedium,
      textAlign: TextAlign.center,
    );
  }
}
