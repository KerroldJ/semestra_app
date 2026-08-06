import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_shell.dart';

// Pages
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/semester/presentation/pages/semester_page.dart';
import '../../features/subject/presentation/pages/subject_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/assignment/presentation/pages/assignment_page.dart';
import '../../features/note/presentation/pages/note_page.dart';
import '../../features/note/presentation/pages/note_editor_page.dart';
import '../../features/exam/presentation/pages/exam_page.dart';
import '../../features/study_timer/presentation/pages/study_timer_page.dart';
import '../../features/daily_planner/presentation/pages/daily_planner_page.dart';
import '../../features/daily_planner/presentation/pages/task_editor_page.dart';
import '../../features/grade/presentation/pages/grade_page.dart';
import '../../features/budget/presentation/pages/budget_page.dart';
import '../../features/reading/presentation/pages/reading_page.dart';
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
          path: '/assignments',
          pageBuilder: (context, state) => const NoTransitionPage(child: AssignmentPage()),
        ),
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) => const NoTransitionPage(child: NotePage()),
        ),
        GoRoute(
          path: '/exams',
          pageBuilder: (context, state) => const NoTransitionPage(child: ExamPage()),
        ),
        GoRoute(
          path: '/timer',
          pageBuilder: (context, state) => const NoTransitionPage(child: StudyTimerPage()),
        ),
        GoRoute(
          path: '/planner',
          pageBuilder: (context, state) => const NoTransitionPage(child: DailyPlannerPage()),
        ),
        GoRoute(
          path: '/grades',
          pageBuilder: (context, state) => const NoTransitionPage(child: GradePage()),
        ),
        GoRoute(
          path: '/budget',
          pageBuilder: (context, state) => const NoTransitionPage(child: BudgetPage()),
        ),
        GoRoute(
          path: '/readings',
          pageBuilder: (context, state) => const NoTransitionPage(child: ReadingPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
    GoRoute(
      path: '/notes/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NoteEditorPage(),
    ),
    GoRoute(
      path: '/planner/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TaskEditorPage(),
    ),
  ],
);
