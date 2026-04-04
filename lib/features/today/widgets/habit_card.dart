import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:streakit/core/utils/color_utils.dart';
import 'package:streakit/features/today/providers/today_provider.dart';
import 'package:streakit/shared/constants/habit_icons.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habitWithStatus,
    required this.onToggle,
  });

  final HabitWithStatus habitWithStatus;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final habit = habitWithStatus.habit;
    final isCompleted = habitWithStatus.isCompleted;
    final streak = habitWithStatus.currentStreak;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final habitColor = hexToColor(habit.colorHex);
    final iconData = habitIconOptions[habit.iconName] ?? Icons.check;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/habits/${habit.id}'),
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: Row(
            children: [
              // Left color bar
              Container(
                width: 5,
                height: 72,
                decoration: BoxDecoration(
                  color: habitColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: habitColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: habitColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Name + streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      habit.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? colorScheme.onSurface.withAlpha(128)
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$streak day streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Complete button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _CompleteButton(
                  isCompleted: isCompleted,
                  habitColor: habitColor,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    onToggle();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.isCompleted,
    required this.habitColor,
    required this.onTap,
  });

  final bool isCompleted;
  final Color habitColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? habitColor : Colors.transparent,
          border: Border.all(
            color: isCompleted ? habitColor : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );

    // Animate scale bounce when toggling to completed
    return button
        .animate(key: ValueKey(isCompleted))
        .scale(
          duration: 200.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
        );
  }
}
