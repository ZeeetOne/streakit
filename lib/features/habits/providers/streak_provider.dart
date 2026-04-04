import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/core/database/database_providers.dart';

part 'streak_provider.g.dart';

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final int totalCompletions;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.totalCompletions,
  });
}

// ---------------------------------------------------------------------------
// Pure streak calculation functions
// ---------------------------------------------------------------------------

/// Returns true if [date] is a scheduled day given [frequency] and [customDays].
bool _isScheduledDay(DateTime date, String frequency, Set<int>? customDays) {
  switch (frequency) {
    case 'daily':
      return true;
    case 'weekdays':
      return date.weekday >= 1 && date.weekday <= 5;
    case 'custom':
      if (customDays == null || customDays.isEmpty) return false;
      return customDays.contains(date.weekday);
    default:
      return true;
  }
}

/// Normalises a [DateTime] to midnight (date-only).
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Calculates the current (active) streak for a habit.
///
/// Walks backwards from today (or yesterday when today is not yet a scheduled
/// completion day that could have already passed) and counts consecutive
/// scheduled days that each have at least one completion.
int calculateCurrentStreak(
  List<DateTime> completionDates,
  String frequency, {
  Set<int>? customDays,
}) {
  if (completionDates.isEmpty) return 0;

  final completionSet =
      completionDates.map(_dateOnly).toSet();

  final today = _dateOnly(DateTime.now());

  // Decide starting point: if today is scheduled and already completed, start
  // from today. If today is scheduled but not yet completed, start from
  // yesterday (streak may still be alive). If today is not scheduled, start
  // from yesterday to find the last scheduled day.
  DateTime cursor;
  if (_isScheduledDay(today, frequency, customDays) &&
      completionSet.contains(today)) {
    cursor = today;
  } else {
    cursor = today.subtract(const Duration(days: 1));
  }

  int streak = 0;
  while (true) {
    if (_isScheduledDay(cursor, frequency, customDays)) {
      if (completionSet.contains(cursor)) {
        streak++;
      } else {
        // Missed a scheduled day — streak is broken.
        break;
      }
    }
    // Move to the previous day. Stop if we've gone before all completions.
    final prev = cursor.subtract(const Duration(days: 1));
    if (prev.isBefore(_dateOnly(completionDates
        .map(_dateOnly)
        .reduce((a, b) => a.isBefore(b) ? a : b)))) {
      break;
    }
    cursor = prev;
  }

  return streak;
}

/// Calculates the longest ever consecutive streak for a habit.
int calculateLongestStreak(
  List<DateTime> completionDates,
  String frequency, {
  Set<int>? customDays,
}) {
  if (completionDates.isEmpty) return 0;

  final completionSet = completionDates.map(_dateOnly).toSet();
  final earliest =
      completionDates.map(_dateOnly).reduce((a, b) => a.isBefore(b) ? a : b);
  final today = _dateOnly(DateTime.now());

  int longest = 0;
  int current = 0;
  DateTime cursor = earliest;

  while (!cursor.isAfter(today)) {
    if (_isScheduledDay(cursor, frequency, customDays)) {
      if (completionSet.contains(cursor)) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  return longest;
}

/// Calculates completion rate = completions / scheduled days since [createdAt].
///
/// Returns a value in [0.0, 1.0].
double calculateCompletionRate(
  DateTime createdAt,
  List<DateTime> completionDates,
  String frequency, {
  Set<int>? customDays,
}) {
  final start = _dateOnly(createdAt);
  final today = _dateOnly(DateTime.now());

  int scheduledDays = 0;
  DateTime cursor = start;
  while (!cursor.isAfter(today)) {
    if (_isScheduledDay(cursor, frequency, customDays)) {
      scheduledDays++;
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  if (scheduledDays == 0) return 0.0;

  // Count completions that fall on or after createdAt and on or before today.
  final validCompletions = completionDates
      .map(_dateOnly)
      .where((d) => !d.isBefore(start) && !d.isAfter(today))
      .toSet(); // deduplicate by date

  return (validCompletions.length / scheduledDays).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

@riverpod
class HabitStreak extends _$HabitStreak {
  @override
  Stream<StreakData> build(int habitId) async* {
    final dao = ref.watch(habitsDaoProvider);
    final habit = await dao.getHabitById(habitId);

    Set<int>? customDays;
    if (habit.frequency == 'custom' && habit.customDays != null) {
      final List<dynamic> parsed = jsonDecode(habit.customDays!);
      customDays = parsed.cast<int>().toSet();
    }

    await for (final completions in dao.watchCompletionsForHabit(habitId)) {
      final dates = completions.map((c) => c.completedDate).toList();
      yield StreakData(
        currentStreak: calculateCurrentStreak(
          dates,
          habit.frequency,
          customDays: customDays,
        ),
        longestStreak: calculateLongestStreak(
          dates,
          habit.frequency,
          customDays: customDays,
        ),
        completionRate: calculateCompletionRate(
          habit.createdAt,
          dates,
          habit.frequency,
          customDays: customDays,
        ),
        totalCompletions: completions.length,
      );
    }
  }
}
