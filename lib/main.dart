import 'package:flutter/material.dart';

void main() => runApp(const _PlaceholderApp());

class _PlaceholderApp extends StatelessWidget {
  const _PlaceholderApp();
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: Scaffold(body: SizedBox.shrink()));
}
