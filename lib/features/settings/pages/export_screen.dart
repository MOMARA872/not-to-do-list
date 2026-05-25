import 'package:flutter/material.dart';

// TODO(06-04): body lands in export plan
/// Placeholder Settings → Export screen.
/// Full export implementation lands in Phase 6 Plan 06-04.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export data'), centerTitle: false),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
