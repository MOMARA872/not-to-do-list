import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/list/providers/app_icon_cache_provider.dart';

/// Renders the launcher icon for [packageName]. Backed by the in-memory
/// LRU(50) cache via [appIconBytesProvider]. Falls back to a generic
/// `Icons.android` glyph while loading or when the package has no icon.
class AppIcon extends ConsumerWidget {
  const AppIcon({required this.packageName, super.key, this.size = 40});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appIconBytesProvider(packageName));
    return SizedBox(
      width: size,
      height: size,
      child: async.when(
        data: (bytes) {
          if (bytes == null) {
            return Icon(
              Icons.android,
              size: size,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            );
          }
          return Image.memory(
            bytes,
            gaplessPlayback: true,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => Icon(
          Icons.android,
          size: size,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
