import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_shell.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/username_page.dart';

// Primary tab pages
import '../../features/today/presentation/pages/today_page.dart';
import '../../features/item/presentation/pages/planner_page.dart';
import '../../features/subject/presentation/pages/subjects_tab_page.dart';
import '../../features/item/presentation/pages/notes_tab_page.dart';

// Secondary / management pages (pushed)
import '../../features/item/domain/entities/item_entity.dart';
import '../../features/item/presentation/pages/assignments_page.dart';
import '../../features/item/presentation/pages/assignment_editor_page.dart';
import '../../features/item/presentation/pages/note_editor_page.dart';
import '../../features/semester/presentation/pages/semester_page.dart';
import '../../features/semester/presentation/pages/semester_overview_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges a Riverpod [StateNotifier] to go_router's [Listenable] so the gate
/// re-evaluates its redirect whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authNotifierProvider,
      (prev, next) {
        if (prev?.status != next.status) {
          notifyListeners();
        }
      },
      fireImmediately: false,
    );
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// Auth-aware app router. Built as a provider so it can watch auth state.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;

      const splash = '/splash';
      const username = '/onboarding/username';

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == splash ? null : splash;
        case AuthStatus.needsUsername:
          return loc == username ? null : username;
        case AuthStatus.ready:
          // Kick users out of the splash / username screen once ready.
          if (loc == splash || loc == username || loc == '/' || loc.isEmpty) {
            return '/today';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/today'),
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(
          path: '/onboarding/username',
          builder: (_, __) => const UsernamePage()),

      // Main shell (5 tabs).
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => NavigationShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            pageBuilder: (_, __) => const NoTransitionPage(child: TodayPage()),
          ),
          GoRoute(
            path: '/planner',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: PlannerPage()),
          ),
          GoRoute(
            path: '/semesters',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SemesterPage()),
          ),
          GoRoute(
            path: '/subjects',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: SubjectsTabPage()),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: NotesTabPage()),
          ),
          // Legacy redirects.
          GoRoute(path: '/semester', redirect: (_, __) => '/semesters'),
          GoRoute(path: '/dashboard', redirect: (_, __) => '/today'),
          GoRoute(path: '/workspace', redirect: (_, __) => '/subjects'),
          GoRoute(path: '/progress', redirect: (_, __) => '/semesters'),
          GoRoute(path: '/profile', redirect: (_, __) => '/settings'),
        ],
      ),

      // Pushed pages (full-screen, above the shell).
      GoRoute(
        path: '/assignments',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AssignmentsPage(),
      ),
      GoRoute(
        path: '/assignments/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            AssignmentEditorPage(item: state.extra as ItemEntity?),
      ),
      GoRoute(
        path: '/notes/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            NoteEditorPage(note: state.extra as ItemEntity?),
      ),
      GoRoute(
        path: '/semester/overview',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SemesterOverviewPage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SettingsPage(),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(begin: begin, end: end).animate(curve),
              child: child,
            );
          },
        ),
      ),
    ],
  );
});
