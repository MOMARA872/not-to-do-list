import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:not_to_do_list/domain/providers/block_list_repo_provider.dart';

/// Surface 6 — UI-SPEC LIST-02. Free-text habit entry: required name +
/// optional 500-char reason. Habits are kind=1 with packageName=null.
class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _nameError;
  int _reasonLength = 0;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      final len = _reasonController.text.length;
      if (len != _reasonLength) {
        setState(() => _reasonLength = len);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = "Name can't be empty.");
      return;
    }
    final repo = ref.read(blockListRepoProvider);
    await repo.add(
      kind: 1,
      displayName: name,
      reasonNote: _reasonController.text,
    );
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCounter = _reasonLength >= 400;
    final isAtCap = _reasonLength == 500;

    return Scaffold(
      appBar: AppBar(title: const Text('Add habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Habit name',
                hintText: 'e.g. Checking news, Online shopping',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: 500,
              // Hide the M3 default counter; we render our own that hides
              // until length >= 400 (UI-SPEC §Surface 6).
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
                hintText: 'Optional. This shows on your reflection screen.',
              ),
            ),
            if (showCounter)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$_reasonLength/500',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isAtCap
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save habit'),
            ),
          ],
        ),
      ),
    );
  }
}
