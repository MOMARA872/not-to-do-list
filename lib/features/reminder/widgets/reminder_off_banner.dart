import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/permission_status_api_provider.dart';

/// NOTF-07 in-app banner: shown when POST_NOTIFICATIONS is not granted.
///
/// Copies the amber-token shell from `HealthCheckBanner` verbatim.
/// No expand toggle — reminder-off has a single action path.
/// Tap behavior (three-state, UI-SPEC §Interaction Contracts):
///   - permanently_denied → openAppNotificationSettings (Pigeon)
///   - otherwise         → context.go('/onboarding/permissions/notifications')
///
/// No dismiss button per threat model T-05-28.
class ReminderOffBanner extends ConsumerWidget {
  const ReminderOffBanner({super.key});

  // Amber tokens — copy from HealthCheckBanner verbatim.
  static const Color _amberBgLight = Color(0xFFFFF3CD);
  static const Color _amberFgLight = Color(0xFF856404);
  static const Color _amberBgDark = Color(0xFF3D2E00);
  static const Color _amberFgDark = Color(0xFFFFD966);

  Future<void> _tapToFix(BuildContext context, WidgetRef ref) async {
    final api = ref.read(permissionStatusApiProvider);
    final rationaleState = await api.postNotificationsRationaleState();
    if (!context.mounted) return;
    if (rationaleState == 'permanently_denied') {
      await api.openAppNotificationSettings();
    } else {
      context.go('/onboarding/permissions/notifications');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _amberBgDark : _amberBgLight;
    final fg = isDark ? _amberFgDark : _amberFgLight;

    return Material(
      color: bg,
      child: InkWell(
        onTap: () => _tapToFix(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.notifications_off_outlined, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reminder is off — tap to fix',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
