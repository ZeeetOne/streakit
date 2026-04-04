import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streakit/core/utils/color_utils.dart';
import 'package:streakit/features/habits/providers/habit_completions_provider.dart';
import 'package:streakit/features/habits/providers/habit_form_provider.dart';
import 'package:streakit/features/habits/providers/streak_provider.dart';
import 'package:streakit/features/habits/widgets/heatmap_calendar.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitFormProvider(habitId));
    final streakAsync = ref.watch(habitStreakProvider(habitId));
    final completionsAsync = ref.watch(habitCompletionsProvider(habitId));

    return habitAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (habit) {
        if (habit == null) {
          return const Scaffold(
            body: Center(child: Text('Habit not found')),
          );
        }

        final habitColor = hexToColor(habit.colorHex);

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit habit',
                onPressed: () => context.push('/habits/${habit.id}/edit'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero section — current streak
              _HeroSection(
                streakAsync: streakAsync,
                habitColor: habitColor,
              ),

              const SizedBox(height: 16),

              // Stats row
              _StatsRow(streakAsync: streakAsync),

              const SizedBox(height: 24),

              // Heatmap calendar
              Text(
                'Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              completionsAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error loading completions: $e'),
                data: (completions) {
                  final completedDates = completions
                      .map((c) => c.completedDate)
                      .toSet();
                  return HeatmapCalendar(
                    completedDates: completedDates,
                    habitColor: habitColor,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hero section
// ---------------------------------------------------------------------------

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.streakAsync,
    required this.habitColor,
  });

  final AsyncValue<StreakData> streakAsync;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '🔥',
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 8),
                streakAsync.when(
                  loading: () => const _BigNumber(value: '--'),
                  error: (_, __) => const _BigNumber(value: '0'),
                  data: (streak) =>
                      _BigNumber(value: '${streak.currentStreak}'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Current Streak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            Text(
              'days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.streakAsync});

  final AsyncValue<StreakData> streakAsync;

  @override
  Widget build(BuildContext context) {
    return streakAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) => Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Longest Streak',
              value: '${streak.longestStreak}',
              unit: 'days',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Total Completions',
              value: '${streak.totalCompletions}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'Completion Rate',
              value: '${(streak.completionRate * 100).round()}',
              unit: '%',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
