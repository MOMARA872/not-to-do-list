import 'package:flutter/material.dart';

class EmptyHomeScreen extends StatelessWidget {
  const EmptyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not To-Do List')),
      body: const Center(child: Text('Your not-to-do list is empty.')),
    );
  }
}
