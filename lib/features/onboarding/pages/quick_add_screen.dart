import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/repositories/block_list_repository.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';

/// Surface 2 (LIST-07, ONBD-02) — quick-add curated 5-card picker.
/// CONTEXT.md: ALL 5 unchecked by default — mindful avoidance frame, user
/// opts in. "Continue" CTA works whether 0 or 5 are selected.
class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _Curated {
  const _Curated(this.packageName, this.displayName, this.assetPath);
  final String packageName;
  final String displayName;
  final String assetPath;
}

const List<_Curated> _curated = [
  _Curated('com.instagram.android', 'Instagram', 'assets/logos/instagram.png'),
  _Curated('com.zhiliaoapp.musically', 'TikTok', 'assets/logos/tiktok.png'),
  _Curated('com.twitter.android', 'X', 'assets/logos/x.png'),
  _Curated(
    'com.google.android.youtube',
    'YouTube',
    'assets/logos/youtube.png',
  ),
  _Curated('com.reddit.frontpage', 'Reddit', 'assets/logos/reddit.png'),
];

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  // CONTEXT.md decision: ALL 5 unchecked by default — mindful avoidance frame.
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your starting point'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Tap the ones you want to avoid. You can always change this '
              'later.',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _curated.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final c = _curated[i];
                final isSelected = _selected.contains(c.packageName);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v ?? false) {
                      _selected.add(c.packageName);
                    } else {
                      _selected.remove(c.packageName);
                    }
                  }),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor:
                      isSelected ? cs.primaryContainer : cs.surfaceContainer,
                  secondary: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      c.assetPath,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.android, color: cs.onSurfaceVariant),
                    ),
                  ),
                  title: Text(c.displayName, style: tt.titleMedium),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_selected.isNotEmpty) {
                    final repo = ref.read(blockListRepoProvider);
                    final entries = _curated
                        .where((c) => _selected.contains(c.packageName))
                        .map<BlockListSeed>(
                          (c) => (
                            kind: 0,
                            packageName: c.packageName,
                            displayName: c.displayName,
                          ),
                        )
                        .toList();
                    await repo.insertMany(entries);
                  }
                  if (!context.mounted) return;
                  context.go('/onboarding/permissions/usage-access');
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
