import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/core/utils/dontkillmyapp_url.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';
import 'package:not_to_do_list/features/health/permission_health_provider.dart';
import 'package:not_to_do_list/features/onboarding/providers/onboarding_complete_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Surface 11 — subdued amber banner that appears at the top of Home
/// when [PermissionHealth.allHealthy] is false. Tapping the banner
/// resets [onboardingCompleteProvider] (so the BatteryOpt step's
/// `_completeOnboarding` re-fires after the user fixes the issue —
/// T-2-10 mitigation) and routes to the FIRST failing permission step
/// in priority order: usage-access > accessibility > battery-opt.
class HealthCheckBanner extends ConsumerStatefulWidget {
  const HealthCheckBanner({required this.health, super.key});

  final PermissionHealth health;

  @override
  ConsumerState<HealthCheckBanner> createState() => _HealthCheckBannerState();
}

class _HealthCheckBannerState extends ConsumerState<HealthCheckBanner> {
  bool _expanded = false;

  // UI-SPEC Surface 11: fixed amber tokens, NOT M3 ColorScheme seed.
  static const Color _amberBgLight = Color(0xFFFFF3CD);
  static const Color _amberFgLight = Color(0xFF856404);
  static const Color _amberBgDark = Color(0xFF3D2E00);
  static const Color _amberFgDark = Color(0xFFFFD966);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _amberBgDark : _amberBgLight;
    final fg = isDark ? _amberFgDark : _amberFgLight;
    return Material(
      color: bg,
      child: InkWell(
        onTap: _tapToFix,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tracking is offline — tap to fix',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: fg,
                    ),
                    tooltip: "What's wrong?",
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                if (!widget.health.usageAccess)
                  _detail(
                    'Usage Access is off — screen-time tracking is paused.',
                    fg,
                  ),
                if (!widget.health.accessibilityService)
                  _detail(
                    'Accessibility Service is off — app blocking is paused.',
                    fg,
                  ),
                if (!widget.health.batteryOptExempt)
                  _detail(
                    'Battery optimization is on — '
                    'tracking may stop overnight.',
                    fg,
                  ),
                _OemLink(fg: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String text, Color fg) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
        ),
      );

  Future<void> _tapToFix() async {
    // Reset onboardingComplete so the BatteryOpt step's
    // _completeOnboarding re-fires when the user reaches the end of the
    // funnel again (ONBD-05, T-2-10).
    await ref.read(onboardingCompleteProvider.notifier).reset();
    if (!mounted) return;
    // Route to FIRST failing step in priority order.
    final h = widget.health;
    if (!h.usageAccess) {
      context.go('/onboarding/permissions/usage-access');
    } else if (!h.accessibilityService) {
      context.go('/onboarding/permissions/accessibility');
    } else if (!h.batteryOptExempt) {
      context.go('/onboarding/permissions/battery-opt');
    } else if (h.fingerprintChanged) {
      // OS update flagged — re-walk from the top.
      context.go('/onboarding/permissions/usage-access');
    }
  }
}

class _OemLink extends ConsumerWidget {
  const _OemLink({required this.fg});

  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve manufacturer asynchronously; if not in known set, render
    // nothing. T-2-04 mitigation: dontkillmyappUrl is map-keyed; the
    // manufacturer string is never interpolated into the URL host.
    return FutureBuilder<String>(
      future: ref.read(permissionStatusApiProvider).currentManufacturer(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final url = dontkillmyappUrl(snap.data!.toLowerCase());
        if (url == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: TextButton.icon(
            icon: Icon(Icons.open_in_new, size: 14, color: fg),
            style: TextButton.styleFrom(foregroundColor: fg),
            label: const Text('Step-by-step guide for your phone'),
            onPressed: () => launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        );
      },
    );
  }
}
