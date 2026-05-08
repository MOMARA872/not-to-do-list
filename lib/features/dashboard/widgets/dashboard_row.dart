import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/dashboard/models/dash_row.dart';
import 'package:not_to_do_list/features/dashboard/widgets/letter_avatar.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

/// One row in the dashboard list (DASH-02). Renders:
/// - 4dp left BorderSide(color: cs.primary, width: 4) when isNotToDo (D-06)
/// - 100% opacity icon for not-to-do; 60% for others (D-06)
/// - LinearProgressIndicator value = foregroundSeconds / maxSeconds clamped
///   (D-15) — colorScheme.primary for not-to-do, outlineVariant for others
/// - Duration text "1h 23m" (decorative bar; screen reader reads the number)
class DashboardRow extends ConsumerWidget {
  const DashboardRow({required this.row, required this.maxSeconds, super.key});

  final DashRow row;
  final int maxSeconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isNotToDo = row.isNotToDo;
    final fillRatio = maxSeconds == 0
        ? 0.0
        : (row.foregroundSeconds / maxSeconds).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        border: isNotToDo
            ? Border(left: BorderSide(color: cs.primary, width: 4))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Opacity(
            opacity: isNotToDo ? 1.0 : 0.6,
            child: _IconOrLetter(
              packageName: row.packageName,
              displayName: row.displayName,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.displayName, style: tt.bodyMedium),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: fillRatio,
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isNotToDo ? cs.primary : cs.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_formatDuration(row.foregroundSeconds), style: tt.bodyMedium),
        ],
      ),
    );
  }
}

/// Internal: try AppIconLruCache -> fall back to LetterAvatar.
class _IconOrLetter extends ConsumerWidget {
  const _IconOrLetter({required this.packageName, required this.displayName});
  final String packageName;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appIconBytesProvider(packageName));
    return SizedBox(
      width: 40,
      height: 40,
      child: async.when(
        data: (bytes) {
          if (bytes == null) return LetterAvatar(label: displayName);
          return Image.memory(bytes, gaplessPlayback: true);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => LetterAvatar(label: displayName),
      ),
    );
  }
}

/// "1h 23m" / "23m" / "0m". Phase 3 doesn't need second precision.
String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}
