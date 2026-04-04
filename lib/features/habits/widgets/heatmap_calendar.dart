import 'package:flutter/material.dart';

class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.completedDates,
    required this.habitColor,
  });

  final Set<DateTime> completedDates;
  final Color habitColor;

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());

    // Build list of 84 dates: from 83 days ago to today
    final dates = List.generate(
      84,
      (i) => today.subtract(Duration(days: 83 - i)),
    );

    // Normalize completedDates for O(1) lookup
    final completedSet = completedDates.map(_dateOnly).toSet();

    // Group dates into weeks (columns). Each column = 7 days.
    // We pad the first week so that Monday is at index 0 (top).
    // Find the weekday of the first date (1=Mon, 7=Sun).
    final firstDate = dates.first;
    // How many empty slots before firstDate in its week column
    final leadingEmpty = (firstDate.weekday - 1) % 7;

    // Build week columns
    final List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(leadingEmpty, null, growable: true);
    for (final date in dates) {
      currentWeek.add(date);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      // Pad the last week to 7 slots
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    // Build month labels: for each week column, determine if the month changes
    // at the start of that week (compared to previous week)
    final List<String?> monthLabels = [];
    int? prevMonth;
    for (final week in weeks) {
      final firstRealDate = week.whereType<DateTime>().firstOrNull;
      if (firstRealDate != null && firstRealDate.month != prevMonth) {
        monthLabels.add(_monthAbbrev(firstRealDate.month));
        prevMonth = firstRealDate.month;
      } else {
        monthLabels.add(null);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weeks.length, (weekIndex) {
              final label = monthLabels[weekIndex];
              return SizedBox(
                width: 12,
                child: label != null
                    ? Text(
                        label,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      )
                    : const SizedBox.shrink(),
              );
            }),
          ),
          const SizedBox(height: 2),
          // Week columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks.length, (weekIndex) {
              final week = weeks[weekIndex];
              return Column(
                children: List.generate(7, (dayIndex) {
                  final date = week[dayIndex];
                  final isCompleted =
                      date != null && completedSet.contains(date);
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: date == null
                          ? Colors.transparent
                          : isCompleted
                              ? habitColor
                              : habitColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}
