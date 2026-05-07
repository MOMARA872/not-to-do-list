/// Centralized `SharedPreferences` keys for Phase 2 onboarding + health-check
/// state. Single source of truth so the cursor, completion flag, and the
/// fingerprint baseline stay in lockstep across providers + tests.
abstract final class OnboardingKeys {
  /// Resume cursor for the install-time funnel. Stored as int 0..3.
  static const String cursor = 'onboarding_step';

  /// Sticky bool: true once the user has completed the install-time funnel.
  static const String complete = 'onboarding_complete';

  /// Build.FINGERPRINT recorded on first install + after every re-verify.
  /// Used by `PermissionHealthNotifier` to detect OS upgrades (ONBD-07).
  static const String lastKnownFingerprint = 'last_known_fingerprint';
}
