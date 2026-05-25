import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Settings → Privacy Policy screen (SETT-05).
/// Renders the bundled docs/PRIVACY.md asset via flutter_markdown_plus.
/// Final privacy policy copy lands in Plan 06-08.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: false),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('docs/PRIVACY.md'),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(data: snap.data!);
        },
      ),
    );
  }
}
