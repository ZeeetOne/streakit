import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit Reminders';
  static const _channelDescription = 'Daily reminders for your habits';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);
  }

  Future<bool?> requestPermissions() async {
    return _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ---------------------------------------------------------------------------
  // Schedule a habit reminder
  // ---------------------------------------------------------------------------

  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitName,
    required TimeOfDay time,
    required String frequency,
    Set<int>? customDays,
  }) async {
    await cancelHabitReminder(habitId);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    switch (frequency) {
      case 'daily':
        await _plugin.zonedSchedule(
          id: habitId * 10,
          title: 'Time to build your streak! 🔥',
          body: habitName,
          scheduledDate: _nextInstanceOfTime(time, null),
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );

      case 'weekdays':
        // Mon=1 .. Fri=5 (DateTime weekday convention)
        for (int day = 1; day <= 5; day++) {
          await _plugin.zonedSchedule(
            id: habitId * 10 + day,
            title: 'Time to build your streak! 🔥',
            body: habitName,
            scheduledDate: _nextInstanceOfTime(time, day),
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }

      case 'custom':
        if (customDays == null || customDays.isEmpty) return;
        for (final day in customDays) {
          await _plugin.zonedSchedule(
            id: habitId * 10 + day,
            title: 'Time to build your streak! 🔥',
            body: habitName,
            scheduledDate: _nextInstanceOfTime(time, day),
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel all notifications for a habit
  // ---------------------------------------------------------------------------

  Future<void> cancelHabitReminder(int habitId) async {
    for (int i = 0; i <= 6; i++) {
      await _plugin.cancel(id: habitId * 10 + i);
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: next TZDateTime for a given time (and optional day-of-week)
  // dayOfWeek: 1=Mon..7=Sun (matches DateTime weekday convention)
  // ---------------------------------------------------------------------------

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time, int? dayOfWeek) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (dayOfWeek == null) {
      // Daily: push to tomorrow if the time has already passed today
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    // Specific day-of-week: advance until we land on the right weekday
    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
