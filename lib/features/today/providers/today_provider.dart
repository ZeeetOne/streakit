import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';

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

    // Combine the two streams manually by listening to one and re-fetching the other
    final habitsStream = dao.watchAllHabits();
    final completionsStream = dao.watchCompletionsForDate(todayOnly);

    // Use async* with a StreamController approach via nested await for
    List<Habit>? latestHabits;
    List<HabitCompletion>? latestCompletions;

    // We use a broadcast approach by merging both streams
    await for (final _ in _merge(habitsStream, completionsStream)) {
      // On each emission from either stream, get current values
      latestHabits ??= await habitsStream.first;
      latestCompletions ??= await completionsStream.first;

      // Re-read fresh snapshots each time either stream emits
      // The merge fires whenever either stream emits; we yield a new state
      final state = _buildState(
        await dao.watchAllHabits().first,
        await dao.watchCompletionsForDate(todayOnly).first,
        today,
      );
      yield state;
    }
  }

  TodayState _buildState(
    List<Habit> allHabits,
    List<HabitCompletion> completions,
    DateTime today,
  ) {
    final completedIds = completions.map((c) => c.habitId).toSet();
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

    // Sort: incomplete first (by sortOrder), then completed (by sortOrder)
    final incomplete = scheduled
        .where((h) => !completedIds.contains(h.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final completed = scheduled
        .where((h) => completedIds.contains(h.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final sortedScheduled = [
      ...incomplete.map(
        (h) => HabitWithStatus(habit: h, isCompleted: false),
      ),
      ...completed.map(
        (h) => HabitWithStatus(habit: h, isCompleted: true),
      ),
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
}

// ---------------------------------------------------------------------------
// Stream merge helper — emits whenever either stream emits
// ---------------------------------------------------------------------------

Stream<void> _merge(Stream<dynamic> a, Stream<dynamic> b) async* {
  bool done = false;

  final iterA = StreamIterator(a);
  final iterB = StreamIterator(b);

  Future<bool> nextA() => iterA.moveNext();
  Future<bool> nextB() => iterB.moveNext();

  var pendingA = nextA();
  var pendingB = nextB();

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
      pendingA = nextA();
    } else {
      pendingB = nextB();
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
