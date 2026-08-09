import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_shell.dart';

// Pages
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/semester/presentation/pages/semester_page.dart';
import '../../features/subject/presentation/pages/subject_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/item/presentation/pages/planner_page.dart';
import '../../features/item/presentation/pages/note_editor_page.dart';
import '../../features/item/presentation/pages/task_editor_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return NavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/semesters',
          pageBuilder: (context, state) => const NoTransitionPage(child: SemesterPage()),
        ),
        GoRoute(
          path: '/subjects',
          pageBuilder: (context, state) => const NoTransitionPage(child: SubjectPage()),
        ),
        GoRoute(
          path: '/schedule',
          pageBuilder: (context, state) => const NoTransitionPage(child: SchedulePage()),
        ),
        GoRoute(
          path: '/planner',
          pageBuilder: (context, state) => const NoTransitionPage(child: PlannerPage()),
        ),
        // Legacy deep-links now resolve to the unified Planner module.
        GoRoute(path: '/notes', redirect: (_, __) => '/planner'),
        GoRoute(path: '/assignments', redirect: (_, __) => '/planner'),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
    GoRoute(
      path: '/planner/note',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NoteEditorPage(),
    ),
    GoRoute(
      path: '/planner/task',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaskEditorPage(),
    ),
  ],
);
