import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';

/// Top-level `WidgetsBindingObserver` that triggers
/// [permissionHealthProvider] re-evaluation on every
/// `AppLifecycleState.resumed`. Mounted ONCE at the
/// `MaterialApp.router` level so a single observer drives all
/// home-tier surfaces (T-2-03 + T-2-06 mitigations).
///
/// Pitfall D pairing: `addObserver(this)` in `initState` is matched by
/// `removeObserver(this)` in `dispose`.
class HealthLifecycleObserver extends ConsumerStatefulWidget {
  const HealthLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<HealthLifecycleObserver> createState() =>
      _HealthLifecycleObserverState();
}

class _HealthLifecycleObserverState
    extends ConsumerState<HealthLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Idempotent — RESEARCH §Pitfall F: spurious resumes on the lock
      // screen are harmless; refresh() simply re-reads the 3 permission
      // signals and updates state.
      unawaited(ref.read(permissionHealthProvider.notifier).refresh());
      // D-10: re-publish the block-list snapshot to the AccessibilityService's
      // in-memory map. Cheap (one Pigeon round-trip + one LocalBroadcast).
      unawaited(ref.read(blockListRepoProvider).republishCurrent());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
