import 'package:flutter/material.dart';

/// Brief confirmation card shown after the cooldown drains to 0 (D-07).
///
/// Displayed for 1500ms before SystemNavigator.pop() is called by
/// PauseController. No streak callout, no additional copy.
class DoneConfirmationCard extends StatelessWidget {
  const DoneConfirmationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Text('✓ Cooldown complete'),
        ),
      ),
    );
  }
}
