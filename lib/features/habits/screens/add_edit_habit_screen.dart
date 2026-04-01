import 'package:flutter/material.dart';

class AddEditHabitScreen extends StatelessWidget {
  const AddEditHabitScreen({super.key, this.habitId});

  final int? habitId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Add / Edit Habit')),
    );
  }
}
