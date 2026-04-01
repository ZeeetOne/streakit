import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:streakit/features/today/screens/today_screen.dart';
import 'package:streakit/features/stats/screens/stats_screen.dart';
import 'package:streakit/features/settings/screens/settings_screen.dart';
import 'package:streakit/features/habits/screens/habit_detail_screen.dart';
import 'package:streakit/features/habits/screens/add_edit_habit_screen.dart';
import 'package:streakit/shared/widgets/app_shell.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/habits/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddEditHabitScreen(),
      ),
      GoRoute(
        path: '/habits/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return HabitDetailScreen(habitId: id);
        },
      ),
      GoRoute(
        path: '/habits/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return AddEditHabitScreen(habitId: id);
        },
      ),
    ],
  );
}
