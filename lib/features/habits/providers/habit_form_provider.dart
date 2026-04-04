import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';

/// Fetches a single habit by ID for pre-filling the edit form.
/// Returns null when [id] is null (i.e. "add" mode).
final habitFormProvider =
    FutureProvider.family<Habit?, int?>((ref, id) async {
  if (id == null) return null;
  final dao = ref.watch(habitsDaoProvider);
  return dao.getHabitById(id);
});
