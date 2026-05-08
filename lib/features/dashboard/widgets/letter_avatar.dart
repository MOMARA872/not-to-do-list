import 'package:flutter/material.dart';

/// Cache-miss fallback widget for an app icon. Renders a CircleAvatar with
/// the first letter of [label] uppercased. Used by DashboardRow when
/// AppIconLruCache + appIconBytesProvider both return null (uninstalled or
/// non-launchable package).
class LetterAvatar extends StatelessWidget {
  const LetterAvatar({required this.label, super.key, this.size = 40});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final letter =
        label.isEmpty ? '?' : label.characters.first.toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: cs.surfaceContainerHighest,
      foregroundColor: cs.onSurfaceVariant,
      child: Text(letter),
    );
  }
}
