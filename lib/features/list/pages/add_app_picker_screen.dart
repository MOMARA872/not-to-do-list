import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/list/controllers/app_picker_controller.dart';
import 'package:not_to_do_list/features/list/providers/installed_apps_provider.dart';
import 'package:not_to_do_list/features/list/providers/recently_used_apps_provider.dart';
import 'package:not_to_do_list/features/list/widgets/app_icon.dart';
import 'package:not_to_do_list/platform/app_picker_api.g.dart';

/// Curated 5 common offenders for the "Suggested" section. Same package set
/// the onboarding quick-add uses (Plan 02-08); duplicated here to avoid a
/// cross-feature import.
const List<String> _suggestedPackages = <String>[
  'com.instagram.android',
  'com.zhiliaoapp.musically', // TikTok
  'com.twitter.android', // X (formerly Twitter)
  'com.google.android.youtube',
  'com.reddit.frontpage',
];

/// Async snapshot of all currently-blocked package names. Lives next to the
/// picker since this is the only consumer; auto-disposes with the picker.
final FutureProvider<Set<String>> _alreadyAddedPackagesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final repo = ref.watch(blockListRepoProvider);
  final all = await repo.getAll();
  return all
      .where((e) => e.kind == 0 && e.packageName != null)
      .map((e) => e.packageName!)
      .toSet();
});

/// Async snapshot of `PermissionStatusApi.isUsageAccessGranted()`. Used by
/// the picker to decide whether to surface the "Recently used" section's
/// inline grant prompt vs. the actual list (T-2-03 mitigation).
final FutureProvider<bool> _usageAccessGrantedProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(permissionStatusApiProvider).isUsageAccessGranted();
});

class AddAppPickerScreen extends ConsumerStatefulWidget {
  const AddAppPickerScreen({super.key});

  @override
  ConsumerState<AddAppPickerScreen> createState() => _AddAppPickerScreenState();
}

class _AddAppPickerScreenState extends ConsumerState<AddAppPickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectApp(InstalledApp app) async {
    final repo = ref.read(blockListRepoProvider);
    await repo.add(
      kind: 0,
      packageName: app.packageName,
      displayName: app.displayName,
    );
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final pickerState = ref.watch(appPickerControllerProvider);
    final installedAsync = ref.watch(installedAppsProvider);
    final alreadyAddedAsync = ref.watch(_alreadyAddedPackagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add app'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search apps...',
              leading: const Icon(Icons.search),
              onChanged: (q) =>
                  ref.read(appPickerControllerProvider.notifier).setQuery(q),
            ),
          ),
        ),
      ),
      body: installedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load apps: $e')),
        data: (allInstalled) {
          final alreadyAdded = alreadyAddedAsync.value ?? <String>{};
          return _buildBody(
            context: context,
            allInstalled: allInstalled,
            alreadyAdded: alreadyAdded,
            pickerState: pickerState,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required List<InstalledApp> allInstalled,
    required Set<String> alreadyAdded,
    required AppPickerState pickerState,
  }) {
    final query = pickerState.query;

    bool matchesQuery(String displayName) {
      if (query.isEmpty) return true;
      return displayName.toLowerCase().contains(query);
    }

    // Pre-build a quick-lookup map for displayName by package, used by the
    // Recently Used section (which only carries package + foreground secs).
    final byPackage = <String, InstalledApp>{
      for (final a in allInstalled) a.packageName: a,
    };

    // Suggested = curated five not-yet-added.
    final suggested = <InstalledApp>[];
    for (final pkg in _suggestedPackages) {
      final app = byPackage[pkg];
      if (app != null &&
          !alreadyAdded.contains(pkg) &&
          matchesQuery(app.displayName)) {
        suggested.add(app);
      }
    }

    // All apps = all installed minus the system-app filter, minus
    // already-added handled inline (greyed-out, not removed).
    final all = allInstalled.where((a) {
      if (!matchesQuery(a.displayName)) return false;
      if (pickerState.showSystemApps) return true;
      // Default: hide entries that are system AND lack a launcher intent.
      return !(a.isSystemApp && !a.hasLauncherIntent);
    }).toList()
      ..sort(
        (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
      );

    return ListView(
      children: <Widget>[
        if (suggested.isNotEmpty) ...[
          const _SectionHeader('Suggested'),
          for (final app in suggested)
            _AppPickerTile(
              app: app,
              alreadyAdded: false,
              onTap: () => _selectApp(app),
            ),
        ],
        _RecentlyUsedSection(
          byPackage: byPackage,
          alreadyAdded: alreadyAdded,
          query: query,
          onSelectApp: _selectApp,
        ),
        if (all.isNotEmpty) ...[
          const _SectionHeader('All apps'),
          for (final app in all)
            _AppPickerTile(
              app: app,
              alreadyAdded: alreadyAdded.contains(app.packageName),
              onTap: alreadyAdded.contains(app.packageName)
                  ? null
                  : () => _selectApp(app),
            ),
        ],
        // Show-all toggle as a ListTile at the bottom of "All apps".
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(
            pickerState.showSystemApps
                ? 'Hide system apps'
                : 'Show all apps',
          ),
          onTap: () =>
              ref.read(appPickerControllerProvider.notifier).toggleShowAll(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _AppPickerTile extends StatelessWidget {
  const _AppPickerTile({
    required this.app,
    required this.alreadyAdded,
    required this.onTap,
  });

  final InstalledApp app;
  final bool alreadyAdded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: AppIcon(packageName: app.packageName),
      title: Text(app.displayName),
      subtitle: alreadyAdded
          ? Text(
              'Already added',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          : null,
      enabled: !alreadyAdded,
      tileColor: alreadyAdded ? scheme.surfaceContainerHighest : null,
      onTap: onTap,
    );
  }
}

class _RecentlyUsedSection extends ConsumerWidget {
  const _RecentlyUsedSection({
    required this.byPackage,
    required this.alreadyAdded,
    required this.query,
    required this.onSelectApp,
  });

  final Map<String, InstalledApp> byPackage;
  final Set<String> alreadyAdded;
  final String query;
  final ValueChanged<InstalledApp> onSelectApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageGrantedAsync = ref.watch(_usageAccessGrantedProvider);
    final usageGranted = usageGrantedAsync.value ?? false;

    if (!usageGranted) {
      // Surface the inline grant prompt — T-2-03 mitigation; the underlying
      // recentlyUsedApps Pigeon call would silently return [] otherwise.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader('Recently used'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Grant Usage Access to see recently used apps',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => ref
                      .read(permissionStatusApiProvider)
                      .openUsageAccessSettings(),
                  child: const Text('Grant access'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final recentAsync = ref.watch(recentlyUsedAppsProvider(7));
    final recents = recentAsync.value ?? const <RecentApp>[];

    final visibleApps = <InstalledApp>[];
    for (final r in recents) {
      final app = byPackage[r.packageName];
      if (app == null) continue;
      if (!app.displayName.toLowerCase().contains(query)) continue;
      visibleApps.add(app);
    }

    if (visibleApps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeader('Recently used'),
        for (final app in visibleApps)
          _AppPickerTile(
            app: app,
            alreadyAdded: alreadyAdded.contains(app.packageName),
            onTap: alreadyAdded.contains(app.packageName)
                ? null
                : () => onSelectApp(app),
          ),
      ],
    );
  }
}
