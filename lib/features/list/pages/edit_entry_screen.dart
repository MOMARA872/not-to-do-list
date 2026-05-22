import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/features/list/controllers/edit_entry_controller.dart';
import 'package:not_to_do_list/features/list/widgets/block_mode_segmented.dart';
import 'package:not_to_do_list/features/list/widgets/schedule_editor.dart';
import 'package:not_to_do_list/features/streak/widgets/streak_history_section.dart';

/// Surface 7 — UI-SPEC LIST-04, LIST-05, LIST-08, LIST-09. Single full-page
/// editor for one block_list row: name + reason + (apps-only) block mode +
/// schedule + bottom-of-page destructive delete.
class EditEntryScreen extends ConsumerStatefulWidget {
  const EditEntryScreen({required this.id, super.key});

  final int id;

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _nameError;
  bool _hydrated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _hydrateFrom(EditEntryDraft draft) {
    if (_hydrated) return;
    _hydrated = true;
    _nameController.text = draft.displayName;
    _reasonController.text = draft.reasonNote;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = "Name can't be empty.");
      return;
    }
    final notifier = ref.read(editEntryControllerProvider(widget.id).notifier);
    try {
      notifier
        ..setName(name)
        ..setReason(_reasonController.text);
      await notifier.save();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong — changes weren't saved. Try again.",
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _delete() async {
    final notifier = ref.read(editEntryControllerProvider(widget.id).notifier);
    try {
      await notifier.delete();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Something went wrong — changes weren't saved. Try again.",
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final asyncDraft = ref.watch(editEntryControllerProvider(widget.id));

    return asyncDraft.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Could not load entry: $e')),
      ),
      data: (draft) {
        _hydrateFrom(draft);
        return _EditEntryView(
          draft: draft,
          nameController: _nameController,
          reasonController: _reasonController,
          nameError: _nameError,
          clearNameError: () {
            if (_nameError != null) {
              setState(() => _nameError = null);
            }
          },
          onBlockModeChanged: (mode) => ref
              .read(editEntryControllerProvider(widget.id).notifier)
              .setBlockMode(mode),
          onScheduleChanged: (s, e, m) => ref
              .read(editEntryControllerProvider(widget.id).notifier)
              .setSchedule(start: s, end: e, mask: m),
          onSave: _save,
          onDelete: _delete,
        );
      },
    );
  }
}

class _EditEntryView extends StatelessWidget {
  const _EditEntryView({
    required this.draft,
    required this.nameController,
    required this.reasonController,
    required this.nameError,
    required this.clearNameError,
    required this.onBlockModeChanged,
    required this.onScheduleChanged,
    required this.onSave,
    required this.onDelete,
  });

  final EditEntryDraft draft;
  final TextEditingController nameController;
  final TextEditingController reasonController;
  final String? nameError;
  final VoidCallback clearNameError;
  final ValueChanged<String> onBlockModeChanged;
  final void Function(int? start, int? end, int? mask) onScheduleChanged;
  final Future<void> Function() onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(draft.isApp ? 'Edit app' : 'Edit habit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Name',
                errorText: nameError,
              ),
              onChanged: (_) => clearNameError(),
            ),
            const SizedBox(height: 16),
            _ReasonField(controller: reasonController),
            const SizedBox(height: 24),
            if (draft.isApp) ...<Widget>[
              BlockModeSegmented(
                value: draft.blockMode,
                onChanged: onBlockModeChanged,
              ),
              const SizedBox(height: 24),
            ],
            ScheduleEditor(
              startMinutes: draft.scheduleStartMinutes,
              endMinutes: draft.scheduleEndMinutes,
              weekdayMask: draft.scheduleWeekdayMask,
              onChanged: onScheduleChanged,
            ),
            StreakHistorySection(entryId: draft.id),
            FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save changes'),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Delete entry'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ReasonField extends StatefulWidget {
  const _ReasonField({required this.controller});

  final TextEditingController controller;

  @override
  State<_ReasonField> createState() => _ReasonFieldState();
}

class _ReasonFieldState extends State<_ReasonField> {
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final len = widget.controller.text.length;
    if (len != _length) {
      setState(() => _length = len);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCounter = _length >= 400;
    final isAtCap = _length == 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: widget.controller,
          maxLines: 4,
          maxLength: 500,
          buildCounter: (
            context, {
            required currentLength,
            required isFocused,
            required maxLength,
          }) =>
              null,
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(500),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Why are you avoiding this?',
          ),
        ),
        if (showCounter)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$_length/500',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isAtCap
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
