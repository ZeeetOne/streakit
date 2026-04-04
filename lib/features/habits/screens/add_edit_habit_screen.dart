import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';
import 'package:streakit/core/utils/color_utils.dart';
import 'package:streakit/features/habits/providers/habit_form_provider.dart';
import 'package:streakit/shared/constants/habit_icons.dart';

// ---------------------------------------------------------------------------
// Color catalogue — 12 preset hex values
// ---------------------------------------------------------------------------

const _colorOptions = <Color>[
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFF44336),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFFE91E63),
  Color(0xFF8BC34A),
  Color(0xFFFF5722),
  Color(0xFF607D8B),
  Color(0xFF3F51B5),
  Color(0xFF009688),
];

// ---------------------------------------------------------------------------
// Frequency constants
// ---------------------------------------------------------------------------

const _freqDaily = 'daily';
const _freqWeekdays = 'weekdays';
const _freqCustom = 'custom';

const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AddEditHabitScreen extends ConsumerStatefulWidget {
  const AddEditHabitScreen({super.key, this.habitId});

  final int? habitId;

  @override
  ConsumerState<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends ConsumerState<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Form state
  String _selectedIcon = 'check';
  Color _selectedColor = _colorOptions.first;
  String _frequency = _freqDaily;
  // Custom days: 1 = Monday … 7 = Sunday
  final Set<int> _customDays = {};
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  bool _initialized = false;
  bool _saving = false;

  bool get _isEdit => widget.habitId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Pre-fill fields from an existing habit
  void _initFromHabit(Habit habit) {
    _nameCtrl.text = habit.name;
    _descCtrl.text = habit.description ?? '';
    _selectedIcon = habit.iconName;
    _selectedColor = hexToColor(habit.colorHex);
    _frequency = habit.frequency;
    if (habit.customDays != null) {
      final List<dynamic> days = jsonDecode(habit.customDays!);
      _customDays.addAll(days.cast<int>());
    }
    if (habit.reminderTime != null) {
      final parts = habit.reminderTime!.split(':');
      _reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      _reminderEnabled = true;
    }
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final colorHex = colorToHex(_selectedColor);
    final customDaysJson =
        _frequency == _freqCustom && _customDays.isNotEmpty
            ? jsonEncode(_customDays.toList()..sort())
            : null;
    final reminderStr = _reminderEnabled && _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:'
              '${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final dao = ref.read(habitsDaoProvider);

    try {
      if (_isEdit) {
        await dao.updateHabit(
          HabitsCompanion(
            id: Value(widget.habitId!),
            name: Value(name),
            description:
                desc.isEmpty ? const Value(null) : Value(desc),
            iconName: Value(_selectedIcon),
            colorHex: Value(colorHex),
            frequency: Value(_frequency),
            customDays: Value(customDaysJson),
            reminderTime: Value(reminderStr),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await dao.insertHabit(
          HabitsCompanion.insert(
            name: name,
            description:
                desc.isEmpty ? const Value.absent() : Value(desc),
            iconName: Value(_selectedIcon),
            colorHex: Value(colorHex),
            frequency: Value(_frequency),
            customDays: Value(customDaysJson),
            reminderTime: Value(reminderStr),
          ),
        );
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // -------------------------------------------------------------------------
  // Reminder time picker
  // -------------------------------------------------------------------------

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // When editing, watch the provider so we can pre-fill once loaded.
    if (_isEdit) {
      final asyncHabit = ref.watch(habitFormProvider(widget.habitId));
      return asyncHabit.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Habit')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Habit')),
          body: Center(child: Text('Error: $e')),
        ),
        data: (habit) {
          if (habit != null && !_initialized) {
            _initialized = true;
            // Schedule state update outside build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _initFromHabit(habit));
            });
          }
          return _buildScaffold(context);
        },
      );
    }

    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Habit' : 'New Habit'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ----------------------------------------------------------------
            // Name
            // ----------------------------------------------------------------
            Text('Name', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. Morning run',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Description
            // ----------------------------------------------------------------
            Text('Description (optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Add a short note…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Icon picker
            // ----------------------------------------------------------------
            Text('Icon', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _IconPicker(
              selected: _selectedIcon,
              onSelected: (name) => setState(() => _selectedIcon = name),
              accentColor: _selectedColor,
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Color picker
            // ----------------------------------------------------------------
            Text('Color', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _selectedColor,
              onSelected: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Frequency
            // ----------------------------------------------------------------
            Text('Frequency', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _FrequencySelector(
              frequency: _frequency,
              customDays: _customDays,
              onFrequencyChanged: (f) => setState(() => _frequency = f),
              onCustomDaysChanged: (days) =>
                  setState(() {
                    _customDays
                      ..clear()
                      ..addAll(days);
                  }),
            ),
            const SizedBox(height: 12),

            // ----------------------------------------------------------------
            // Reminder
            // ----------------------------------------------------------------
            Text('Reminder', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                Switch(
                  value: _reminderEnabled,
                  onChanged: (v) => setState(() => _reminderEnabled = v),
                ),
                const SizedBox(width: 8),
                const Text('Daily reminder'),
              ],
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _reminderTime != null
                      ? _reminderTime!.format(context)
                      : 'Select time',
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ----------------------------------------------------------------
            // Save button
            // ----------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Update Habit' : 'Create Habit'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Icon Picker
// ===========================================================================

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: habitIconOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final entry = habitIconOptions.entries.elementAt(i);
          final isSelected = entry.key == selected;
          return GestureDetector(
            onTap: () => onSelected(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade400,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                entry.value,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// Color Picker
// ===========================================================================

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map((c) {
        final isSelected = c.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withAlpha(153), blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ===========================================================================
// Frequency Selector
// ===========================================================================

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.frequency,
    required this.customDays,
    required this.onFrequencyChanged,
    required this.onCustomDaysChanged,
  });

  final String frequency;
  final Set<int> customDays;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<Set<int>> onCustomDaysChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: _freqDaily, label: Text('Daily')),
            ButtonSegment(value: _freqWeekdays, label: Text('Weekdays')),
            ButtonSegment(value: _freqCustom, label: Text('Custom')),
          ],
          selected: {frequency},
          onSelectionChanged: (set) => onFrequencyChanged(set.first),
          showSelectedIcon: false,
        ),
        if (frequency == _freqCustom) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final dayNum = i + 1; // 1=Mon … 7=Sun
              final active = customDays.contains(dayNum);
              return FilterChip(
                label: Text(_dayLabels[i]),
                selected: active,
                onSelected: (v) {
                  final updated = Set<int>.from(customDays);
                  if (v) {
                    updated.add(dayNum);
                  } else {
                    updated.remove(dayNum);
                  }
                  onCustomDaysChanged(updated);
                },
              );
            }),
          ),
        ],
      ],
    );
  }
}
