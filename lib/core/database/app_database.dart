import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'daos/habits_dao.dart';

part 'app_database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get iconName => text().withDefault(const Constant('check'))();
  TextColumn get colorHex => text().withDefault(const Constant('#4CAF50'))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get customDays => text().nullable()();
  TextColumn get reminderTime => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class HabitCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id,
      onDelete: KeyAction.cascade)();
  DateTimeColumn get completedDate => dateTime()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, completedDate},
      ];
}

@DriftDatabase(tables: [Habits, HabitCompletions], daos: [HabitsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(DriftDatabase(name: 'streakit'));

  @override
  int get schemaVersion => 1;
}
