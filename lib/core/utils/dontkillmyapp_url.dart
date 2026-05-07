/// Maps lowercased `Build.MANUFACTURER` to the dontkillmyapp.com per-OEM
/// page slug. Returns null if the manufacturer is not in the recognized
/// aggressive-vendor set, in which case the UI shows generic guidance only
/// (UI-SPEC Surface 11; REL-03).
///
/// The map is compile-time const and the host is hard-coded to `https://`.
/// Callers MUST lowercase the manufacturer string before calling — the
/// Pigeon-side `currentManufacturer()` already does this on the Kotlin side
/// (see `PermissionStatusApiImpl.kt`), but tests should pass lowercased
/// strings to mirror that behavior (T-2-04 mitigation).
const Map<String, String> _oemSlugs = {
  'xiaomi': 'xiaomi',
  'huawei': 'huawei',
  'samsung': 'samsung',
  'oppo': 'oppo',
  'vivo': 'vivo',
  'oneplus': 'oneplus',
};

String? dontkillmyappUrl(String manufacturerLower) {
  final slug = _oemSlugs[manufacturerLower];
  return slug == null ? null : 'https://dontkillmyapp.com/$slug';
}
