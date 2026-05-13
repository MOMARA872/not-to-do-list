import 'package:flutter/material.dart';

/// Renders the user's reason text as an italic/serif quote-card (D-02).
///
/// Rendered only when reasonNote is non-empty. The visual weight of this
/// widget is the heaviest element on the pause screen — the user's own
/// words talking back to them.
class ReasonHero extends StatelessWidget {
  const ReasonHero({required this.reasonText, super.key});

  final String reasonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            '“$reasonText”',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
