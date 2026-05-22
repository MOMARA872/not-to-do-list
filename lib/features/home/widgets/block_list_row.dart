import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/list/widgets/app_icon.dart';
import 'package:not_to_do_list/features/streak/widgets/streak_badge.dart';

/// 64 dp compact row. Icon source distinguishes Apps (AppIcon for packageName)
/// from Habits (Icons.spa_outlined). No badges, no tags, no sectioning.
/// CONTEXT.md "App vs Habit visual distinction: Icon source only."
class BlockListRow extends ConsumerWidget {
  const BlockListRow({required this.entry, super.key});

  final BlockListData entry;

  bool get _isApp => entry.kind == 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 64,
      child: ListTile(
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        tileColor: cs.surfaceContainer,
        leading: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: _isApp && entry.packageName != null
                ? AppIcon(packageName: entry.packageName!)
                : Icon(
                    Icons.spa_outlined,
                    size: 32,
                    color: cs.onSurfaceVariant,
                  ),
          ),
        ),
        title: Text(
          entry.displayName,
          style: tt.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: entry.reasonNote.isEmpty
            ? null
            : Text(
                entry.reasonNote,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: StreakBadge(entryId: entry.id),
        onTap: () => context.go('/list/edit/${entry.id}'),
        // Tap is the only row gesture in v1 (per CONTEXT.md row UX rules).
      ),
    );
  }
}
