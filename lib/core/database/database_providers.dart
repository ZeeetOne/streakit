import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/core/database/app_database.dart';
import 'daos/habits_dao.dart';

part 'database_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}

@riverpod
HabitsDao habitsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.habitsDao;
}
