import 'package:flutter/material.dart';

class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Habit Detail')),
    );
  }
}
