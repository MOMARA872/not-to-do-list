import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/list/widgets/app_icon.dart';

/// 64 dp compact row. Icon source distinguishes Apps (AppIcon for packageName)
/// from Habits (Icons.spa_outlined). No badges, no tags, no sectioning.
/// CONTEXT.md "App vs Habit visual distinction: Icon source only."
class BlockListRow extends StatelessWidget {
  const BlockListRow({required this.entry, super.key});

  final BlockListData entry;

  bool get _isApp => entry.kind == 0;

  @override
  Widget build(BuildContext context) {
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
        trailing: Text(
          // Phase 2 streak placeholder; Phase 5 STRK-01/07 fills the integer.
          '—',
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        onTap: () => context.go('/list/edit/${entry.id}'),
        // Tap is the only row gesture in v1 (per CONTEXT.md row UX rules).
      ),
    );
  }
}
