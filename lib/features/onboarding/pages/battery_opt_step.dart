import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:not_to_do_list/features/onboarding/widgets/oem_fallback_panel.dart';
import 'package:not_to_do_list/features/onboarding/widgets/rationale_screen.dart';

/// Surface 3 Step 3 (ONBD-02, ONBD-03) — Battery-opt exemption + funnel
/// completion. On grant OR explicit skip, we mark onboarding complete AND
/// persist `Build.FINGERPRINT` so the home health-banner doesn't trip
/// `fingerprintChanged=true` on first cold launch (Plan 02-05 contract).
class BatteryOptStep extends ConsumerStatefulWidget {
  const BatteryOptStep({super.key});

  @override
  ConsumerState<BatteryOptStep> createState() => _BatteryOptStepState();
}

class _BatteryOptStepState extends ConsumerState<BatteryOptStep>
    with WidgetsBindingObserver {
  bool _showOemFallback = false;
  String _manufacturer = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final granted = await api.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    if (granted) {
      await _completeOnboarding();
      return;
    }
    if (fromResume) {
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
      await api.openBatteryOptSettings();
    } on Object {
      final mfr = await api.currentManufacturer();
      if (!mounted) return;
      setState(() {
        _manufacturer = mfr.toLowerCase();
        _showOemFallback = true;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    // Plan 02-05 contract: persist fingerprint baseline before marking
    // complete so the health banner won't immediately trip on cold launch.
    await ref
        .read(permissionHealthProvider.notifier)
        .persistCurrentFingerprint();
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
    if (!mounted) return;
    context.go('/');
  }

  // Skip on the final step still marks complete — funnel is 1-tap-skippable
  // per CONTEXT.md. The home health-banner will surface the missing perms.
  Future<void> _skip() => _completeOnboarding();

  @override
  Widget build(BuildContext context) {
    return RationaleScreen(
      headline: 'Keep tracking running overnight',
      body: const Text(
        'Some phones stop background apps to save battery. Tell your phone '
        "to let Not To-Do List run so your tracking doesn't go dark while "
        'you sleep.',
      ),
      screenshotAsset: 'assets/onboarding/battery_opt_step.png',
      primaryCtaLabel: 'Open Settings',
      onPrimaryCta: _openSettings,
      onSkip: _skip,
      footerNote: 'Without this, tracking may stop overnight on some '
          'devices. You can fix it later from home.',
      stepIndex: 3,
      belowBody: _showOemFallback
          ? OemFallbackPanel(manufacturerLower: _manufacturer)
          : null,
    );
  }
}
