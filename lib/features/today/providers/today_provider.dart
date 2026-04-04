import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';
import 'package:streakit/features/habits/providers/streak_provider.dart';

part 'today_provider.g.dart';

// ---------------------------------------------------------------------------
// State classes
// ---------------------------------------------------------------------------

class HabitWithStatus {
  final Habit habit;
  final bool isCompleted;
  final int currentStreak;

  const HabitWithStatus({
    required this.habit,
    required this.isCompleted,
    this.currentStreak = 0,
  });
}

class TodayState {
  final List<HabitWithStatus> scheduled;
  final int completedCount;
  final int totalCount;

  const TodayState({
    required this.scheduled,
    required this.completedCount,
    required this.totalCount,
  });

  List<HabitWithStatus> get incomplete =>
      scheduled.where((h) => !h.isCompleted).toList();

  List<HabitWithStatus> get completed =>
      scheduled.where((h) => h.isCompleted).toList();
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

@riverpod
class TodayNotifier extends _$TodayNotifier {
  @override
  Stream<TodayState> build() async* {
    final dao = ref.watch(habitsDaoProvider);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final habitsStream = dao.watchAllHabits();
    final completionsStream = dao.watchCompletionsForDate(todayOnly);
    final allCompletionsStream = dao.watchAllCompletions();

    await for (final _ in _merge3(habitsStream, completionsStream, allCompletionsStream)) {
      final state = _buildState(
        await dao.watchAllHabits().first,
        await dao.watchCompletionsForDate(todayOnly).first,
        await dao.watchAllCompletions().first,
        today,
      );
      yield state;
    }
  }

  TodayState _buildState(
    List<Habit> allHabits,
    List<HabitCompletion> todayCompletions,
    List<HabitCompletion> allCompletions,
    DateTime today,
  ) {
    final completedIds = todayCompletions.map((c) => c.habitId).toSet();
    final weekday = today.weekday; // 1=Mon, 7=Sun

    // Filter habits scheduled for today
    final scheduled = allHabits.where((h) {
      switch (h.frequency) {
        case 'daily':
          return true;
        case 'weekdays':
          return weekday >= 1 && weekday <= 5;
        case 'custom':
          if (h.customDays == null) return false;
          final List<dynamic> days = jsonDecode(h.customDays!);
          return days.cast<int>().contains(weekday);
        default:
          return true;
      }
    }).toList();

    // Build a lookup: habitId -> list of completion dates (all time)
    final Map<int, List<DateTime>> completionsByHabit = {};
    for (final c in allCompletions) {
      completionsByHabit.putIfAbsent(c.habitId, () => []).add(c.completedDate);
    }

    // Sort: incomplete first (by sortOrder), then completed (by sortOrder)
    final incomplete = scheduled
        .where((h) => !completedIds.contains(h.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final completed = scheduled
        .where((h) => completedIds.contains(h.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    HabitWithStatus toStatus(Habit h, bool isCompleted) {
      Set<int>? customDays;
      if (h.frequency == 'custom' && h.customDays != null) {
        final List<dynamic> parsed = jsonDecode(h.customDays!);
        customDays = parsed.cast<int>().toSet();
      }
      final dates = completionsByHabit[h.id] ?? [];
      final streak = calculateCurrentStreak(
        dates,
        h.frequency,
        customDays: customDays,
      );
      return HabitWithStatus(habit: h, isCompleted: isCompleted, currentStreak: streak);
    }

    final sortedScheduled = [
      ...incomplete.map((h) => toStatus(h, false)),
      ...completed.map((h) => toStatus(h, true)),
    ];

    return TodayState(
      scheduled: sortedScheduled,
      completedCount: completed.length,
      totalCount: scheduled.length,
    );
  }

  Future<void> toggleCompletion(int habitId, bool currentlyCompleted) async {
    final dao = ref.read(habitsDaoProvider);
    final today = DateTime.now();
    if (currentlyCompleted) {
      await dao.deleteCompletion(habitId, today);
    } else {
      await dao.insertCompletion(habitId, today);
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Collect incomplete habits in their current display order
    final incompleteIds = currentState.scheduled
        .where((h) => !h.isCompleted)
        .map((h) => h.habit.id)
        .toList();

    if (oldIndex >= incompleteIds.length || newIndex > incompleteIds.length) {
      return;
    }

    // Flutter's ReorderableListView semantics: adjust newIndex when moving down
    if (newIndex > oldIndex) newIndex--;

    final id = incompleteIds.removeAt(oldIndex);
    incompleteIds.insert(newIndex, id);

    final dao = ref.read(habitsDaoProvider);
    await dao.reorderHabits(incompleteIds);
  }
}

// ---------------------------------------------------------------------------
// Stream merge helpers — emit whenever any stream emits
// ---------------------------------------------------------------------------

Stream<void> _merge3(
  Stream<dynamic> a,
  Stream<dynamic> b,
  Stream<dynamic> c,
) async* {
  bool done = false;

  final iterA = StreamIterator(a);
  final iterB = StreamIterator(b);
  final iterC = StreamIterator(c);

  Future<bool> nextA() => iterA.moveNext();
  Future<bool> nextB() => iterB.moveNext();
  Future<bool> nextC() => iterC.moveNext();

  var pendingA = nextA();
  var pendingB = nextB();
  var pendingC = nextC();

  while (!done) {
    final result = await Future.any([
      pendingA.then((v) => _Tagged(0, v)),
      pendingB.then((v) => _Tagged(1, v)),
      pendingC.then((v) => _Tagged(2, v)),
    ]);

    if (!result.value) {
      done = true;
      break;
    }

    yield null;

    if (result.tag == 0) {
      pendingA = nextA();
    } else if (result.tag == 1) {
      pendingB = nextB();
    } else {
      pendingC = nextC();
    }
  }

  await iterA.cancel();
  await iterB.cancel();
  await iterC.cancel();
}

class _Tagged {
  final int tag;
  final bool value;
  const _Tagged(this.tag, this.value);
}
