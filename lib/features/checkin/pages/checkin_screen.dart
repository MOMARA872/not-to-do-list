import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/data/database/app_database.dart';
import 'package:not_to_do_list/features/checkin/controllers/checkin_controller.dart';
import 'package:not_to_do_list/features/checkin/providers/checkin_providers.dart';
import 'package:not_to_do_list/features/list/widgets/app_icon.dart';

/// Dedicated daily check-in surface (D-02 / STRK-03).
///
/// Triggered by reminder notification tap (NOTF-03 deep-link) AND the Home
/// screen cold-open when pending entries exist (D-01).
///
/// Lists all block_list entries that are pending today (or already answered
/// with a locked SegmentedButton). A single FilledButton writes all answers
/// in one Drift transaction then re-triggers streak rollover.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  @override
  void initState() {
    super.initState();
    // Reset transient answer state when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkinAnswersProvider.notifier).state = <int, bool>{};
    });
  }

  @override
  Widget build(BuildContext context) {
    // Single listener handles both error SnackBar and post-submit navigation.
    ref.listen<AsyncValue<void>>(checkinControllerProvider, (prev, next) {
      // Surface write error via SnackBar (screen NOT popped - user can retry).
      next.whenOrNull(
        error: (e, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              // UI-SPEC Copywriting Contract -- apostrophe + em dash exact.
              content: Text(_kErrorCopy),
            ),
          );
        },
      );
      // Navigate to Home after successful submit (loading to data transition).
      if (prev?.isLoading == true && next.hasValue && !next.hasError) {
        context.go('/');
      }
    });

    final todayAsync = ref.watch(pendingCheckinsTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily check-in'),
        centerTitle: false,
      ),
      body: todayAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (today) => _CheckinBody(
          pending: today.pending,
          answered: today.answered,
        ),
      ),
    );
  }
}

// UI-SPEC Copywriting Contract -- exact copy (em dash + apostrophe).
// Top-level const avoids inline non-ASCII triggering prefer_single_quotes.
// ignore: lines_longer_than_80_chars
const String _kErrorCopy = "Something went wrong — your check-in wasn't saved. Try again.";

class _CheckinBody extends ConsumerWidget {
  const _CheckinBody({
    required this.pending,
    required this.answered,
  });

  final List<BlockListData> pending;
  final List<({BlockListData entry, DailyCheckin answer})> answered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final answers = ref.watch(checkinAnswersProvider);
    final hasNewAnswers = answers.isNotEmpty;
    // 'All done' path: no pending entries, user has not started new answers.
    final allPreAnswered =
        pending.isEmpty && answered.isNotEmpty && answers.isEmpty;

    // Empty state: no pending AND no answered-today entries.
    if (pending.isEmpty && answered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_circle_outline, size: 48, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              // UI-SPEC Copywriting Contract -- exact copy.
              "You're all caught up",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              // UI-SPEC Copywriting Contract -- exact copy.
              'Check back tomorrow.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    // Determine submit button label and enabled state.
    final buttonLabel = allPreAnswered ? 'All done' : 'Save check-in';
    final buttonEnabled = hasNewAnswers || allPreAnswered;
    final onTap = buttonEnabled
        ? allPreAnswered
            ? () => context.go('/')
            : () => ref.read(checkinControllerProvider.notifier).submit()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 16),
          Text(
            // UI-SPEC Copywriting Contract -- exact copy.
            'How did today go?',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 16),

          // Pending entries (interactive SegmentedButton).
          for (int i = 0; i < pending.length; i++) ...<Widget>[
            _EntryRow(
              entry: pending[i],
              currentAnswer: answers[pending[i].id],
              onAnswerChanged: (value) {
                ref.read(checkinAnswersProvider.notifier).state = <int, bool>{
                  ...answers,
                  pending[i].id: value,
                };
              },
            ),
            if (i < pending.length - 1 || answered.isNotEmpty)
              const Divider(),
          ],

          // Already-answered entries (locked SegmentedButton -- D-01).
          for (int i = 0; i < answered.length; i++) ...<Widget>[
            _EntryRow(
              entry: answered[i].entry,
              currentAnswer: answered[i].answer.avoided,
              onAnswerChanged: null,
            ),
            if (i < answered.length - 1) const Divider(),
          ],

          const SizedBox(height: 24),

          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(buttonLabel),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Single entry row with a leading icon, displayName, and Yes/No
/// SegmentedButton.
///
/// When [onAnswerChanged] is null, the SegmentedButton is locked (disabled),
/// showing the [currentAnswer] as pre-selected (D-01 idempotency).
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  final BlockListData entry;
  final bool? currentAnswer;
  final ValueChanged<bool>? onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final isApp = entry.kind == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          // Leading icon: AppIcon for apps, spa_outlined for habits.
          if (isApp && entry.packageName != null)
            AppIcon(packageName: entry.packageName!, size: 32)
          else
            const Icon(Icons.spa_outlined, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Yes')),
              ButtonSegment<bool>(value: false, label: Text('No')),
            ],
            selected:
                currentAnswer != null ? <bool>{currentAnswer!} : <bool>{},
            emptySelectionAllowed: true,
            onSelectionChanged: onAnswerChanged != null
                ? (sel) {
                    if (sel.isNotEmpty) onAnswerChanged!(sel.first);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
