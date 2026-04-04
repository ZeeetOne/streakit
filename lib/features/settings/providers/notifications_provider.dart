import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/notifications/notification_service.dart';

part 'notifications_provider.g.dart';

@Riverpod(keepAlive: true)
class NotificationsEnabled extends _$NotificationsEnabled {
  static const _key = 'notifications_enabled';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true; // enabled by default
  }

  Future<void> setEnabled(bool value, List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    state = AsyncData(value);

    if (!value) {
      // Cancel all notifications
      for (final habit in habits) {
        await NotificationService.instance.cancelHabitReminder(habit.id);
      }
    } else {
      // Re-schedule habits that have a reminderTime
      for (final habit in habits) {
        if (habit.reminderTime != null) {
          final parts = habit.reminderTime!.split(':');
          final time = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          Set<int>? customDays;
          if (habit.frequency == 'custom' && habit.customDays != null) {
            final List<dynamic> parsed = jsonDecode(habit.customDays!);
            customDays = parsed.cast<int>().toSet();
          }
          await NotificationService.instance.scheduleHabitReminder(
            habitId: habit.id,
            habitName: habit.name,
            time: time,
            frequency: habit.frequency,
            customDays: customDays,
          );
        }
      }
    }
  }
}
