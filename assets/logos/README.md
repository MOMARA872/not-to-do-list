# Quick-add curated logos

These 5 PNGs are **PLACEHOLDERS**. They are referenced by
`lib/features/onboarding/pages/quick_add_screen.dart`.

Two strategies for production:

1. **Recommended (per RESEARCH §Open Pattern Risks #5):** delete these
   placeholders and modify `quick_add_screen.dart` to fetch each app's
   icon at runtime via `PackageManager.getApplicationIcon` if installed,
   falling back to `Icons.android` glyph if not. This avoids any
   trademark exposure.

2. **Alternate:** source officially-licensed brand assets and replace
   each PNG. Requires legal review of brand-asset usage terms.

Phase 2 ships option 1 in spirit (the `Image.asset` `errorBuilder` falls
back to `Icons.android`), but the asset slots are reserved so a future
plan can swap in real logos without code changes.

Phase 2 placeholder format: 1×1 transparent PNG.

Tracked replacement task: Phase 6 PLAY-08 closed-track submission.
