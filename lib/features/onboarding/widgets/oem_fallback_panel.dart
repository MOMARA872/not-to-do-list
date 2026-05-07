import 'package:flutter/material.dart';
import 'package:not_to_do_list/core/utils/dontkillmyapp_url.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reactive OEM-specific guidance + dontkillmyapp.com link.
///
/// CONTEXT.md: shown only when (a) the standard Settings intent failed to
/// resolve OR (b) the user returned from Settings without granting AND
/// (c) `Build.MANUFACTURER` lowercased matches a known aggressive-vendor
/// slug. T-2-04 mitigation: the URL host is hard-coded `https://` inside
/// [dontkillmyappUrl]; the manufacturer string is map-resolved (never
/// interpolated into the host).
class OemFallbackPanel extends StatelessWidget {
  const OemFallbackPanel({required this.manufacturerLower, super.key});

  final String manufacturerLower;

  /// Per-OEM instruction copy. Kept in lockstep with [dontkillmyappUrl]'s
  /// recognized-vendor set (Plan 02-05): xiaomi, huawei, samsung, oppo,
  /// realme (alias of oppo), vivo, oneplus.
  static const Map<String, String> _oemInstructions = {
    'xiaomi':
        'On Xiaomi: go to Settings → Apps → Manage apps → Not To-Do List → '
            'Battery saver → No restrictions.',
    'huawei':
        'On Huawei: go to Settings → Battery → App launch → Not To-Do List '
            '→ Manage manually → enable all three toggles.',
    'samsung':
        'On Samsung: go to Settings → Battery → Background usage limits → '
            'Never sleeping apps → add Not To-Do List.',
    'oppo':
        'On Oppo/Realme: go to Settings → Battery → Energy efficient apps '
            '→ Not To-Do List → turn off.',
    'realme':
        'On Oppo/Realme: go to Settings → Battery → Energy efficient apps '
            '→ Not To-Do List → turn off.',
    'vivo':
        'On Vivo: go to Settings → Battery → High background power '
            'consumption → allow Not To-Do List.',
    'oneplus':
        'On OnePlus: go to Settings → Battery → Battery optimization → '
            "Not To-Do List → Don't optimize.",
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final instr = _oemInstructions[manufacturerLower] ??
        "Open your phone's Settings → Battery → Battery optimization "
            '(or similar) and exempt Not To-Do List from restrictions.';
    final url = dontkillmyappUrl(manufacturerLower);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(instr, style: tt.bodyLarge),
          if (url != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Step-by-step guide for your phone'),
            ),
          ],
        ],
      ),
    );
  }
}
