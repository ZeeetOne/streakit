import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';

/// Watches all completions for a specific habit.
final habitCompletionsProvider =
    StreamProvider.autoDispose.family<List<HabitCompletion>, int>(
  (ref, habitId) {
    final dao = ref.watch(habitsDaoProvider);
    return dao.watchCompletionsForHabit(habitId);
  },
);
