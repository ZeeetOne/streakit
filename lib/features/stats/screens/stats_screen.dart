import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streakit/core/utils/color_utils.dart';
import 'package:streakit/features/stats/providers/stats_provider.dart';
import 'package:streakit/features/stats/widgets/weekly_chart.dart';
import 'package:streakit/shared/constants/habit_icons.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: false,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load stats: $e'),
          ),
        ),
        data: (stats) => _StatsBody(stats: stats),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final StatsState stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Weekly chart section ──────────────────────────────────────────
        Text(
          'This Week',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: WeeklyChart(days: stats.weeklyData),
          ),
        ),
        const SizedBox(height: 16),

        // ── Comparison card ───────────────────────────────────────────────
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Comparison',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      label: 'This week',
                      value: '${stats.totalCompletionsThisWeek}',
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text('vs'),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Last week',
                      value: '${stats.totalCompletionsLastWeek}',
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _comparisonText(
                    stats.totalCompletionsThisWeek,
                    stats.totalCompletionsLastWeek,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Overall completion rate: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${(stats.overallCompletionRate * 100).round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Top Streaks section ───────────────────────────────────────────
        Text(
          'Top Streaks',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (stats.topStreaks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No habits yet. Add some habits to see streaks!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...stats.topStreaks.map((summary) {
            final habit = summary.habit;
            final iconData =
                habitIconOptions[habit.iconName] ?? habitIconOptions['check']!;
            final habitColor = hexToColor(habit.colorHex);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: habitColor.withAlpha(30),
                  child: Icon(iconData, color: habitColor, size: 20),
                ),
                title: Text(
                  habit.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Best: ${summary.longestStreak} day${summary.longestStreak == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.currentStreak}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: habitColor,
                      ),
                    ),
                    Text(
                      'day streak',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _comparisonText(int thisWeek, int lastWeek) {
    if (lastWeek == 0 && thisWeek == 0) return 'No completions yet this week.';
    if (lastWeek == 0) return 'Great start — $thisWeek completion${thisWeek == 1 ? '' : 's'} this week!';
    final diff = thisWeek - lastWeek;
    if (diff > 0) return '+$diff more than last week. Keep it up!';
    if (diff < 0) return '${diff.abs()} fewer than last week. You can do it!';
    return 'Same as last week — stay consistent!';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
