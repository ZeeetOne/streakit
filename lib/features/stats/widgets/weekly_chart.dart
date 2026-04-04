import 'package:flutter/material.dart';
import 'package:streakit/core/theme/app_colors.dart';
import 'package:streakit/features/stats/providers/stats_provider.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.days});

  final List<DailyCompletionRate> days;

  static const double _maxBarHeight = 120.0;
  static const double _barWidth = 32.0;
  static const double _barGap = 6.0;

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primary = AppColors.primary;
    final dimColor = primary.withAlpha(80);
    final bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (i) {
        final day = days[i];
        final ratio = day.ratio.clamp(0.0, 1.0);
        final isToday = _isSameDay(day.date, now);
        final barHeight = (_maxBarHeight * ratio).clamp(0.0, _maxBarHeight);
        final barColor = isToday ? primary : dimColor;
        final label = i < _dayLabels.length ? _dayLabels[i] : '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _barGap / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _barWidth,
                height: _maxBarHeight,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Background bar
                    Container(
                      width: _barWidth,
                      height: _maxBarHeight,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Filled bar
                    if (barHeight > 0)
                      Container(
                        width: _barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isToday
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
