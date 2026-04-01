import 'package:flutter/material.dart';

// TODO: Wire up GoRouter and app theme in subsequent tasks.
class StreaKitApp extends StatelessWidget {
  const StreaKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'StreaKit',
      home: Scaffold(
        body: Center(child: Text('StreaKit')),
      ),
    );
  }
}
