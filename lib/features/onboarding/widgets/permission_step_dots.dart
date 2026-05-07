import 'package:flutter/material.dart';

/// 3-dot step indicator for the permission funnel (Surface 3).
/// Active dot uses `ColorScheme.primary`; inactive uses `outlineVariant`.
class PermissionStepDots extends StatelessWidget {
  const PermissionStepDots({
    required this.currentStep,
    super.key,
    this.totalSteps = 3,
  });

  /// 1-indexed step (1, 2, or 3).
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(totalSteps, (i) {
        final stepNum = i + 1;
        final isActive = stepNum == currentStep;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Semantics(
            label: 'Step $stepNum of $totalSteps',
            value: isActive ? 'current step' : null,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? cs.primary : cs.outlineVariant,
              ),
            ),
          ),
        );
      }),
    );
  }
}
