import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/post_notifications_provider.dart';
import 'package:not_to_do_list/features/streak/storage/streak_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NOTF-06 — Earned POST_NOTIFICATIONS rationale + system-prompt screen.
///
/// Fires ONCE after the user's first block-list entry insertion
/// (BlockListRepository.add → pendingNavRequestProvider trigger → HomeScreen
/// ref.listen → context.go('/onboarding/permissions/notifications')).
///
/// WidgetsBindingObserver resumed re-check (T-05-16 mitigation):
/// Plan 05-04's requestPostNotifications returns PRE-dialog state immediately
/// (non-blocking). This widget detects the POST-dialog grant outcome by
/// re-polling isPostNotificationsGranted when the app resumes from background
/// (the user returning from the Android system permissions dialog).
/// Cross-reference: T-05-16 in Plan 05-04 SUMMARY.md + 05-04 threat register.
class PostNotificationsEarnedStep extends ConsumerStatefulWidget {
  const PostNotificationsEarnedStep({super.key});

  @override
  ConsumerState<PostNotificationsEarnedStep> createState() =>
      _PostNotificationsEarnedStepState();
}

class _PostNotificationsEarnedStepState
    extends ConsumerState<PostNotificationsEarnedStep>
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

  /// T-05-16 mitigation: re-poll on resumed to detect the post-dialog grant.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkIfGrantedAfterResume());
    }
  }

  /// If the user granted the permission in the system dialog and then returned
  /// to the app, advance and write the fire-once flag.
  Future<void> _checkIfGrantedAfterResume() async {
    final api = ref.read(permissionStatusApiProvider);
    final granted = await api.isPostNotificationsGranted();
    if (!mounted) return;
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StreakKeys.earnedPromptShown, true);
      if (!mounted) return;
      unawaited(
        ref.read(postNotificationsGrantedProvider.notifier).refresh(),
      );
      if (!mounted) return;
      context.go('/');
    }
  }

  Future<void> _onContinue() async {
    final api = ref.read(permissionStatusApiProvider);
    await api.requestPostNotifications();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StreakKeys.earnedPromptShown, true);
    if (!mounted) return;
    unawaited(
      ref.read(postNotificationsGrantedProvider.notifier).refresh(),
    );
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily reminder', style: tt.headlineSmall),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            DefaultTextStyle.merge(
              style: tt.bodyLarge!.copyWith(color: cs.onSurface),
              child: const Text(
                // RESEARCH §6 line 621 verbatim body copy (NOTF-06 lock).
                'Get a daily reminder to confirm your not-to-do list. '
                "Without notifications, you'll need to open the app to "
                'record each day.',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onContinue,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
