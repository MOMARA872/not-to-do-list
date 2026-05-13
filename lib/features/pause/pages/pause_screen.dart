import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/features/pause/providers/pause_providers.dart';
import 'package:not_to_do_list/features/pause/widgets/app_name_hero.dart';
import 'package:not_to_do_list/features/pause/widgets/cooldown_chip_row.dart';
import 'package:not_to_do_list/features/pause/widgets/cooldown_progress_bar.dart';
import 'package:not_to_do_list/features/pause/widgets/done_confirmation_card.dart';
import 'package:not_to_do_list/features/pause/widgets/reason_hero.dart';

/// The Flutter UI half of the wedge (D-01..D-08).
///
/// Accepts route parameters directly. Plan 04-08 wires the GoRouter route
/// `/pause/:entryId` and creates PauseScreen from GoRouterState params.
///
/// Layout (D-01..D-08):
///   - LinearProgressIndicator (top edge, pinned via Stack)
///   - ReasonHero OR AppNameHero (depending on reasonNote)
///   - CooldownChipRow
///   - "X:XX remaining" caption (inside CooldownProgressBar)
///   - Cancel (FilledButton) + Use anyway (TextButton, soft only)
class PauseScreen extends ConsumerWidget {
  const PauseScreen({
    required this.entryId,
    required this.packageName,
    required this.blockMode,
    required this.triggeredAt,
    super.key,
  });

  final int entryId;
  final String packageName;
  final String blockMode;
  final DateTime triggeredAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (
      entryId: entryId,
      packageName: packageName,
      blockMode: blockMode,
      triggeredAt: triggeredAt,
      onClose: SystemNavigator.pop,
    );

    final session = ref.watch(pauseControllerProvider(args));
    final entryAsync = ref.watch(blockListEntryProvider(entryId));

    // Show DoneConfirmationCard full-screen when isComplete.
    if (session.isComplete) {
      return const Scaffold(body: DoneConfirmationCard());
    }

    return Scaffold(
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) {
          // Defensive: entry was deleted between Intent build and screen mount.
          // Fail-closed — pop back to launcher without writing a row.
          unawaited(SystemNavigator.pop());
          return const SizedBox.shrink();
        },
        data: (entry) {
          final reasonNote = entry?.reasonNote ?? '';
          final displayName = entry?.displayName ?? packageName;

          final controller = ref.read(pauseControllerProvider(args).notifier);

          return Stack(
            children: <Widget>[
              // Progress bar pinned to top (D-05).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CooldownProgressBar(
                  totalSeconds: session.cooldownChosenSeconds,
                  remainingMs: session.remainingMs,
                ),
              ),

              // Main content — padded below the progress bar.
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: <Widget>[
                      const Spacer(),

                      // Hero (D-02 or D-03).
                      if (reasonNote.isNotEmpty)
                        ReasonHero(reasonText: reasonNote)
                      else
                        AppNameHero(displayName: displayName),

                      const Spacer(),

                      // Cooldown chip row (D-04).
                      CooldownChipRow(
                        selectedSeconds: session.cooldownChosenSeconds,
                        onChanged: controller.startCooldown,
                      ),

                      const SizedBox(height: 8),

                      // Caption rendered inside CooldownProgressBar (D-05).
                      // The top-pinned bar handles the LinearProgressIndicator;
                      // the caption is shown below the chip row.
                      if (session.cooldownChosenSeconds != null)
                        Text(
                          _formatRemaining(session.remainingMs ?? 0),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),

                      const SizedBox(height: 24),

                      // Button row (D-06).
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          FilledButton(
                            onPressed: controller.cancel,
                            child: const Text('Cancel'),
                          ),
                          // Use anyway: OMITTED for hard entries (PAUS-09).
                          if (blockMode == 'soft') ...<Widget>[
                            const SizedBox(width: 16),
                            TextButton(
                              // CD-02: enabled IMMEDIATELY (no cooldown gate).
                              onPressed: controller.useAnyway,
                              child: const Text('Use anyway'),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatRemaining(int ms) {
    final totalSec = (ms / 1000).ceil();
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} remaining';
  }
}
