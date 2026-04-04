import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:streakit/core/database/database_providers.dart';
import 'package:streakit/features/settings/providers/notifications_provider.dart';
import 'package:streakit/features/settings/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final currentTheme = themeAsync.maybeWhen(
      data: (mode) => mode,
      orElse: () => ThemeMode.system,
    );

    final notificationsAsync = ref.watch(notificationsEnabledProvider);
    final notificationsEnabled = notificationsAsync.maybeWhen(
      data: (enabled) => enabled,
      orElse: () => true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ---- Appearance ----
          _SectionHeader(title: 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(currentTheme)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                ),
              ],
              selected: {currentTheme},
              onSelectionChanged: (selected) {
                ref
                    .read(themeProvider.notifier)
                    .setThemeMode(selected.first);
              },
              showSelectedIcon: false,
            ),
          ),

          // ---- Notifications ----
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Habit Reminders'),
            subtitle: Text(
              notificationsEnabled
                  ? 'Reminders are active'
                  : 'All reminders paused',
            ),
            value: notificationsEnabled,
            onChanged: (value) async {
              final dao = ref.read(habitsDaoProvider);
              final habits = await dao.watchAllHabits().first;
              await ref
                  .read(notificationsEnabledProvider.notifier)
                  .setEnabled(value, habits);
            },
          ),

          // ---- Data ----
          _SectionHeader(title: 'Data'),
          ListTile(
            title: const Text('Export Data'),
            trailing: const Icon(Icons.download),
            onTap: () => _exportData(context, ref),
          ),

          // ---- About ----
          _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(habitsDaoProvider);

    final habits = await dao.watchAllHabits().first;
    final allCompletions = await dao.watchAllCompletions().first;

    // Group completions by habitId
    final completionsByHabit = <int, List<String>>{};
    for (final c in allCompletions) {
      final dateStr =
          '${c.completedDate.year.toString().padLeft(4, '0')}-'
          '${c.completedDate.month.toString().padLeft(2, '0')}-'
          '${c.completedDate.day.toString().padLeft(2, '0')}';
      completionsByHabit.putIfAbsent(c.habitId, () => []).add(dateStr);
    }

    final habitsJson = habits.map((h) {
      return {
        'id': h.id,
        'name': h.name,
        'iconName': h.iconName,
        'colorHex': h.colorHex,
        'frequency': h.frequency,
        'customDays': h.customDays,
        'reminderTime': h.reminderTime,
        'sortOrder': h.sortOrder,
        'isArchived': h.isArchived,
        'createdAt': h.createdAt.toUtc().toIso8601String(),
        'completions': completionsByHabit[h.id] ?? [],
      };
    }).toList();

    final exportData = {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'habits': habitsJson,
    };

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(exportData);

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/streakit_export_$dateStr.json');
    await file.writeAsString(jsonString);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to ${file.path}'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
