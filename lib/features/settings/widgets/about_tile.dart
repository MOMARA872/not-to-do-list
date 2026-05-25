import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Display-only ListTile that renders app version via package_info_plus.
/// Format: '${version} (${buildNumber})' per Pitfall 7 (no '+' glue).
/// Shows em-dash '—' while PackageInfo resolves.
class AboutTile extends StatelessWidget {
  const AboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (ctx, snap) {
        final subtitle = snap.hasData
            ? '${snap.data!.version} (${snap.data!.buildNumber})'
            : '—';
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About'),
          subtitle: Text(subtitle),
        );
      },
    );
  }
}
