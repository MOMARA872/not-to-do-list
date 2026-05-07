import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_cursor_provider.dart';
import 'package:not_to_do_list/features/onboarding/widgets/oem_fallback_panel.dart';
import 'package:not_to_do_list/features/onboarding/widgets/rationale_screen.dart';

/// Surface 3 Step 1 (ONBD-02, ONBD-03) — Usage Access rationale + onResume
/// auto-advance. RESEARCH §Pitfall D: addObserver/removeObserver MUST pair.
class UsageAccessStep extends ConsumerStatefulWidget {
  const UsageAccessStep({super.key});

  @override
  ConsumerState<UsageAccessStep> createState() => _UsageAccessStepState();
}

class _UsageAccessStepState extends ConsumerState<UsageAccessStep>
    with WidgetsBindingObserver {
  bool _showOemFallback = false;
  String _manufacturer = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // RESEARCH lines 393-466: re-check on mount; if already granted, skip.
    unawaited(_checkAndMaybeAdvance());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkAndMaybeAdvance(fromResume: true));
    }
  }

  Future<void> _checkAndMaybeAdvance({bool fromResume = false}) async {
    final api = ref.read(permissionStatusApiProvider);
    final granted = await api.isUsageAccessGranted();
    if (!mounted) return;
    if (granted) {
      await ref.read(onboardingCursorProvider.notifier).set(2);
      if (!mounted) return;
      context.go('/onboarding/permissions/accessibility');
      return;
    }
    if (fromResume) {
      // User came back without granting — surface OEM-specific guidance.
      final mfr = await api.currentManufacturer();
      if (!mounted) return;
      setState(() {
        _manufacturer = mfr.toLowerCase();
        _showOemFallback = true;
      });
    }
  }

  Future<void> _openSettings() async {
    final api = ref.read(permissionStatusApiProvider);
    try {
      await api.openUsageAccessSettings();
    } on Object {
      // Standard intent didn't resolve. Show OEM fallback immediately.
      final mfr = await api.currentManufacturer();
      if (!mounted) return;
      setState(() {
        _manufacturer = mfr.toLowerCase();
        _showOemFallback = true;
      });
    }
  }

  Future<void> _skip() async {
    await ref.read(onboardingCursorProvider.notifier).set(2);
    if (!mounted) return;
    context.go('/onboarding/permissions/accessibility');
  }

  @override
  Widget build(BuildContext context) {
    return RationaleScreen(
      headline: 'See which apps you actually use',
      body: const Text(
        'Not To-Do List needs Usage Access to show how much time you spend '
        'in each app. Your data never leaves your device.',
      ),
      screenshotAsset: 'assets/onboarding/usage_access_step.png',
      primaryCtaLabel: 'Open Settings',
      onPrimaryCta: _openSettings,
      onSkip: _skip,
      footerNote: "Without this, screen-time tracking won't work. You can "
          'fix it later from home.',
      stepIndex: 1,
      belowBody: _showOemFallback
          ? OemFallbackPanel(manufacturerLower: _manufacturer)
          : null,
    );
  }
}
