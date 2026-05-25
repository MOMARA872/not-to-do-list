import 'package:flutter/material.dart';

/// M3 section label for the Settings screen (Phase 6 SETT-04).
/// Mirrors the labelSmall + primary + letterSpacing pattern from UI-SPEC
/// §Typography + §Spacing.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
