import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_cursor_provider.dart';
import 'package:not_to_do_list/features/onboarding/widgets/oem_fallback_panel.dart';
import 'package:not_to_do_list/features/onboarding/widgets/rationale_screen.dart';

/// Surface 3 Step 2 (ONBD-02, ONBD-03, PLAY-06) — Accessibility rationale +
/// onResume auto-advance. The body region carries the PLAY-06 prominent
/// disclosure; the 5 verbatim phrases (`docs/play-declaration.md §4`) MUST
/// remain byte-identical — `prominent_disclosure_test.dart` greps this file.
class AccessibilityStep extends ConsumerStatefulWidget {
  const AccessibilityStep({super.key});

  @override
  ConsumerState<AccessibilityStep> createState() => _AccessibilityStepState();
}

class _AccessibilityStepState extends ConsumerState<AccessibilityStep>
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
    final granted = await api.isAccessibilityServiceEnabled();
    if (!mounted) return;
    if (granted) {
      await ref.read(onboardingCursorProvider.notifier).set(3);
      if (!mounted) return;
      context.go('/onboarding/permissions/battery-opt');
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
      await api.openAccessibilitySettings();
    } on Object {
      final mfr = await api.currentManufacturer();
      if (!mounted) return;
      setState(() {
        _manufacturer = mfr.toLowerCase();
        _showOemFallback = true;
      });
    }
  }

  Future<void> _skip() async {
    await ref.read(onboardingCursorProvider.notifier).set(3);
    if (!mounted) return;
    context.go('/onboarding/permissions/battery-opt');
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return RationaleScreen(
      headline: 'Pause before you open blocked apps',
      // PLAY-06 prominent disclosure — 3 paragraphs containing the 5 verbatim
      // phrases enforced by prominent_disclosure_test.dart:
      //   1. "package name"
      //   2. "only when a window-state-changed event fires"
      //   3. "never reads your screen"
      //   4. "never sends anything off your device"
      //   5. "disable this at any time"
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Not To-Do List needs to read the package name of the app you've "
            'just opened — only when a window-state-changed event fires — '
            'so it can show your reflection screen when you open something '
            'on your list.',
            style: tt.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'The service listens only to foreground app changes. It never '
            'reads your screen, never types on your behalf, and never sends '
            'anything off your device.',
            style: tt.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'You remain in full control: dismiss the reflection screen, '
            'choose "Use anyway," or wait for the cooldown. You can disable '
            'this at any time from Android Settings.',
            style: tt.bodyLarge,
          ),
        ],
      ),
      screenshotAsset: 'assets/onboarding/accessibility_step.png',
      primaryCtaLabel: 'I understand — open Settings',
      onPrimaryCta: _openSettings,
      onSkip: _skip,
      footerNote: "Without this, the app can't pause blocked-app launches. "
          'You can fix it later from home.',
      stepIndex: 2,
      belowBody: _showOemFallback
          ? OemFallbackPanel(manufacturerLower: _manufacturer)
          : null,
    );
  }
}
