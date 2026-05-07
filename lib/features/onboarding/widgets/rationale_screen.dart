import 'package:flutter/material.dart';
import 'package:not_to_do_list/features/onboarding/widgets/permission_step_dots.dart';

/// Shared shell for the 3 permission funnel steps (Surface 3).
/// UI-SPEC component tree: AppBar(title + Skip) → step dots → screenshot →
/// optional [afterScreenshot] → body → optional [belowBody] → primary CTA →
/// footer note.
class RationaleScreen extends StatelessWidget {
  const RationaleScreen({
    required this.headline,
    required this.body,
    required this.screenshotAsset,
    required this.primaryCtaLabel,
    required this.onPrimaryCta,
    required this.onSkip,
    required this.footerNote,
    required this.stepIndex,
    super.key,
    this.afterScreenshot,
    this.belowBody,
  });

  final String headline;

  /// Body region — bodyLarge text or a Column of paragraphs (PLAY-06 case).
  final Widget body;

  /// Screenshot asset path, e.g. `assets/onboarding/usage_access_step.png`.
  final String screenshotAsset;
  final String primaryCtaLabel;
  final VoidCallback onPrimaryCta;
  final VoidCallback onSkip;
  final String footerNote;

  /// 1, 2, or 3 — feeds [PermissionStepDots].
  final int stepIndex;

  final Widget? afterScreenshot;

  /// OEM fallback panel slot — injected reactively by step screens.
  final Widget? belowBody;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(headline, style: tt.headlineSmall),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PermissionStepDots(currentStep: stepIndex),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                screenshotAsset,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: cs.surfaceContainer,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: cs.outlineVariant,
                  ),
                ),
              ),
            ),
            if (afterScreenshot != null) ...[
              const SizedBox(height: 16),
              afterScreenshot!,
            ],
            const SizedBox(height: 24),
            DefaultTextStyle.merge(
              style: tt.bodyLarge!.copyWith(color: cs.onSurface),
              child: body,
            ),
            if (belowBody != null) ...[
              const SizedBox(height: 16),
              belowBody!,
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryCta,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(primaryCtaLabel),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              footerNote,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
