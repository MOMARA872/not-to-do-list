import 'package:flutter/material.dart';

// TODO(06-06): body lands in privacy plan
/// Placeholder Settings → Privacy Policy screen.
/// Full privacy screen implementation lands in Phase 6 Plan 06-06.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: false),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
