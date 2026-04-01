import 'package:drift/drift.dart';
import '../app_database.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitCompletions])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // --- Habits ---

  Stream<List<Habit>> watchAllHabits() {
    return (select(habits)
          ..where((h) => h.isArchived.equals(false))
          ..orderBy([(h) => OrderingTerm.asc(h.sortOrder)]))
        .watch();
  }

  Future<Habit> getHabitById(int id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingle();
  }

  Future<int> insertHabit(HabitsCompanion habit) {
    return into(habits).insert(habit);
  }

  Future<bool> updateHabit(HabitsCompanion habit) {
    return update(habits).replace(habit);
  }

  Future<int> deleteHabit(int id) {
    return (delete(habits)..where((h) => h.id.equals(id))).go();
  }

  Future<void> reorderHabits(List<int> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(habits)..where((h) => h.id.equals(orderedIds[i])))
            .write(HabitsCompanion(sortOrder: Value(i)));
      }
    });
  }

  // --- Completions ---

  Future<void> insertCompletion(int habitId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await into(habitCompletions).insertOnConflictUpdate(
      HabitCompletionsCompanion.insert(
        habitId: habitId,
        completedDate: dateOnly,
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteCompletion(int habitId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    await (delete(habitCompletions)
          ..where(
            (c) =>
                c.habitId.equals(habitId) & c.completedDate.equals(dateOnly),
          ))
        .go();
  }

  Stream<List<HabitCompletion>> watchCompletionsForHabit(int habitId) {
    return (select(habitCompletions)
          ..where((c) => c.habitId.equals(habitId)))
        .watch();
  }

  Stream<List<HabitCompletion>> watchCompletionsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return (select(habitCompletions)
          ..where((c) => c.completedDate.equals(dateOnly)))
        .watch();
  }
}
