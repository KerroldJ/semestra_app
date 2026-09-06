import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_shell.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/username_page.dart';
import '../../features/auth/presentation/pages/onboarding_subjects_page.dart';
import '../../features/auth/presentation/pages/onboarding_schedule_page.dart';

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
import '../../features/subject/presentation/pages/subject_detail_page.dart';
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
      (_, __) => notifyListeners(),
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
      const welcome = '/welcome';
      const signIn = '/sign-in';
      const username = '/onboarding/username';
      const subjects = '/onboarding/subjects';
      const schedule = '/onboarding/schedule';

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == splash ? null : splash;
        case AuthStatus.signedOut:
          // Allow the welcome + sign-in screens.
          if (loc == welcome || loc == signIn) return null;
          return welcome;
        case AuthStatus.needsUsername:
          return loc == username ? null : username;
        case AuthStatus.needsSetup:
          // Allow both onboarding data steps.
          if (loc == subjects || loc == schedule) return null;
          return subjects;
        case AuthStatus.ready:
          // Kick users out of the auth/onboarding funnel once ready.
          if (loc == splash ||
              loc == welcome ||
              loc == signIn ||
              loc == username ||
              loc == subjects ||
              loc == schedule) {
            return '/today';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInPage()),
      GoRoute(
          path: '/onboarding/username',
          builder: (_, __) => const UsernamePage()),
      GoRoute(
          path: '/onboarding/subjects',
          builder: (_, __) => const OnboardingSubjectsPage()),
      GoRoute(
          path: '/onboarding/schedule',
          builder: (_, __) => const OnboardingSchedulePage()),

      // Main shell (4 tabs + compose ring).
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
          GoRoute(path: '/dashboard', redirect: (_, __) => '/today'),
          GoRoute(path: '/workspace', redirect: (_, __) => '/subjects'),
          GoRoute(path: '/progress', redirect: (_, __) => '/semester'),
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
        path: '/subjects/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            SubjectDetailPage(subjectId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/semester',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SemesterOverviewPage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const SettingsPage(),
      ),
    ],
  );
});
