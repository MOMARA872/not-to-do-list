import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do_list/domain/providers/database_provider.dart';
import 'package:not_to_do_list/domain/providers/file_save_port_provider.dart';
import 'package:not_to_do_list/features/settings/services/export_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings → Export screen (SETT-01).
///
/// Single ListTile "Export all data" that triggers a Storage Access Framework
/// pick and writes a ZIP archive (5 CSVs + data.json). SnackBar feedback:
/// - success → 'Export saved'
/// - user cancel (null return) → silent, no SnackBar
/// - I/O error → 'Export failed. Check available storage and try again.'
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export data'), centerTitle: false),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Export all data'),
            subtitle: const Text(
              'ZIP includes all entries, streaks, pause events, and check-ins',
            ),
            onTap: () => _onExport(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _onExport(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final saver = ref.read(fileSavePortProvider);
      final pi = await PackageInfo.fromPlatform();
      final controller = ExportController(db, pi, saver);
      final path = await controller.exportAll();
      if (!context.mounted) return;
      if (path == null) return; // user cancelled — silent per Pitfall 3
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export saved')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Export failed. Check available storage and try again.',
          ),
        ),
      );
    }
  }
}
