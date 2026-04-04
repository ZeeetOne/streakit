import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';
import 'package:streakit/features/habits/providers/streak_provider.dart';

part 'stats_provider.g.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class DailyCompletionRate {
  final DateTime date;
  final int completed;
  final int scheduled;

  const DailyCompletionRate({
    required this.date,
    required this.completed,
    required this.scheduled,
  });

  double get ratio => scheduled == 0 ? 0.0 : completed / scheduled;
}

class HabitStreakSummary {
  final Habit habit;
  final int currentStreak;
  final int longestStreak;

  const HabitStreakSummary({
    required this.habit,
    required this.currentStreak,
    required this.longestStreak,
  });
}

class StatsState {
  final List<DailyCompletionRate> weeklyData;
  final List<HabitStreakSummary> topStreaks;
  final double overallCompletionRate;
  final int totalCompletionsThisWeek;
  final int totalCompletionsLastWeek;

  const StatsState({
    required this.weeklyData,
    required this.topStreaks,
    required this.overallCompletionRate,
    required this.totalCompletionsThisWeek,
    required this.totalCompletionsLastWeek,
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool _isScheduledForDay(Habit habit, DateTime day) {
  switch (habit.frequency) {
    case 'daily':
      return true;
    case 'weekdays':
      return day.weekday >= 1 && day.weekday <= 5;
    case 'custom':
      if (habit.customDays == null) return false;
      final List<dynamic> days = jsonDecode(habit.customDays!);
      return days.cast<int>().contains(day.weekday);
    default:
      return true;
  }
}

List<DateTime> _weekDays(DateTime anchorMonday) {
  return List.generate(
    7,
    (i) => DateTime(
      anchorMonday.year,
      anchorMonday.month,
      anchorMonday.day + i,
    ),
  );
}

DateTime _mondayOf(DateTime date) {
  return _dateOnly(date.subtract(Duration(days: date.weekday - 1)));
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

@riverpod
class StatsNotifier extends _$StatsNotifier {
  @override
  Stream<StatsState> build() async* {
    final dao = ref.watch(habitsDaoProvider);

    final habitsStream = dao.watchAllHabits();
    final completionsStream = dao.watchAllCompletions();

    await for (final _ in _merge2(habitsStream, completionsStream)) {
      final habits = await dao.watchAllHabits().first;
      final allCompletions = await dao.watchAllCompletions().first;

      yield _buildStats(habits, allCompletions);
    }
  }

  StatsState _buildStats(
    List<Habit> habits,
    List<HabitCompletion> allCompletions,
  ) {
    final now = _dateOnly(DateTime.now());

    // Build completion lookup: habitId -> Set<DateTime (date-only)>
    final Map<int, Set<DateTime>> completionsByHabit = {};
    for (final c in allCompletions) {
      completionsByHabit
          .putIfAbsent(c.habitId, () => {})
          .add(_dateOnly(c.completedDate));
    }

    // Current week (Mon-Sun)
    final thisMonday = _mondayOf(now);
    final thisWeekDays = _weekDays(thisMonday);

    // Last week (Mon-Sun)
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    final lastWeekDays = _weekDays(lastMonday);

    // Build DailyCompletionRate for each day of the current week
    final weeklyData = thisWeekDays.map((day) {
      int scheduledCount = 0;
      int completedCount = 0;
      for (final habit in habits) {
        if (_isScheduledForDay(habit, day)) {
          scheduledCount++;
          final completions = completionsByHabit[habit.id];
          if (completions != null && completions.contains(day)) {
            completedCount++;
          }
        }
      }
      return DailyCompletionRate(
        date: day,
        completed: completedCount,
        scheduled: scheduledCount,
      );
    }).toList();

    // Total completions this week
    final thisWeekSet = thisWeekDays.toSet();
    int totalThisWeek = 0;
    for (final completionSet in completionsByHabit.values) {
      totalThisWeek += completionSet.where(thisWeekSet.contains).length;
    }

    // Total completions last week
    final lastWeekSet = lastWeekDays.toSet();
    int totalLastWeek = 0;
    for (final completionSet in completionsByHabit.values) {
      totalLastWeek += completionSet.where(lastWeekSet.contains).length;
    }

    // Compute top streaks
    final summaries = habits.map((habit) {
      Set<int>? customDays;
      if (habit.frequency == 'custom' && habit.customDays != null) {
        final List<dynamic> parsed = jsonDecode(habit.customDays!);
        customDays = parsed.cast<int>().toSet();
      }
      final dates = (completionsByHabit[habit.id] ?? {}).toList();
      return HabitStreakSummary(
        habit: habit,
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
      );
    }).toList()
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

    final topStreaks = summaries.take(5).toList();

    // Overall completion rate: average of per-habit completion rates
    double overallRate = 0.0;
    if (habits.isNotEmpty) {
      double sum = 0.0;
      for (final habit in habits) {
        Set<int>? customDays;
        if (habit.frequency == 'custom' && habit.customDays != null) {
          final List<dynamic> parsed = jsonDecode(habit.customDays!);
          customDays = parsed.cast<int>().toSet();
        }
        final dates = (completionsByHabit[habit.id] ?? {}).toList();
        sum += calculateCompletionRate(
          habit.createdAt,
          dates,
          habit.frequency,
          customDays: customDays,
        );
      }
      overallRate = sum / habits.length;
    }

    return StatsState(
      weeklyData: weeklyData,
      topStreaks: topStreaks,
      overallCompletionRate: overallRate,
      totalCompletionsThisWeek: totalThisWeek,
      totalCompletionsLastWeek: totalLastWeek,
    );
  }
}

// ---------------------------------------------------------------------------
// Stream merge helper
// ---------------------------------------------------------------------------

Stream<void> _merge2(Stream<dynamic> a, Stream<dynamic> b) async* {
  bool done = false;

  final iterA = StreamIterator(a);
  final iterB = StreamIterator(b);

  var pendingA = iterA.moveNext();
  var pendingB = iterB.moveNext();

  while (!done) {
    final result = await Future.any([
      pendingA.then((v) => _Tagged(0, v)),
      pendingB.then((v) => _Tagged(1, v)),
    ]);

    if (!result.value) {
      done = true;
      break;
    }

    yield null;

    if (result.tag == 0) {
      pendingA = iterA.moveNext();
    } else {
      pendingB = iterB.moveNext();
    }
  }

  await iterA.cancel();
  await iterB.cancel();
}

class _Tagged {
  final int tag;
  final bool value;
  const _Tagged(this.tag, this.value);
}
