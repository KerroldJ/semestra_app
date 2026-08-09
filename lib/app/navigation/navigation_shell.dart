import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:semestra_app/features/settings/presentation/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';

class NavigationShell extends ConsumerWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final settings = ref.watch(settingsNotifierProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    final destinations = [
      _NavDestination(
        route: '/dashboard',
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        isMainTab: true,
      ),
      _NavDestination(
        route: '/semesters',
        icon: Icons.calendar_month_rounded,
        label: 'Semesters',
        isMainTab: true,
      ),
      _NavDestination(
        route: '/subjects',
        icon: Icons.book_rounded,
        label: 'Subjects',
        isMainTab: true,
      ),
      _NavDestination(
        route: '/schedule',
        icon: Icons.schedule_rounded,
        label: 'Schedule',
        isMainTab: true,
      ),
      _NavDestination(
        route: '/planner',
        icon: Icons.auto_awesome_rounded,
        label: 'Planner',
        isMainTab: true,
      ),
      _NavDestination(
        route: '/settings',
        icon: Icons.settings_rounded,
        label: 'Settings',
        isMainTab: false,
      ),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(destinations: destinations, activeRoute: location),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile layout
    final theme = Theme.of(context);
    final mainDestinations = settings.mainTabRoutes.map((route) {
      return destinations.firstWhere((d) => d.route == route, orElse: () => destinations.first);
    }).toList();
    final activeIndex = mainDestinations.indexWhere((d) => location == d.route);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          destinations.firstWhere((d) => d.route == location, orElse: () => destinations.first).label,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      drawer: _MobileDrawer(destinations: destinations, activeRoute: location),
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D30) : Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(mainDestinations.length, (index) {
              final d = mainDestinations[index];
              final isActive = activeIndex == index || (activeIndex == -1 && index == 0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: GestureDetector(
                    onTap: () => context.go(d.route),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            d.icon,
                            size: 22,
                            color: isActive
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            d.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 16,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final String route;
  final IconData icon;
  final String label;
  final bool isMainTab;

  _NavDestination({
    required this.route,
    required this.icon,
    required this.label,
    required this.isMainTab,
  });
}

class _Sidebar extends StatelessWidget {
  final List<_NavDestination> destinations;
  final String activeRoute;

  const _Sidebar({required this.destinations, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 250,
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 24),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Semestra',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 22,
                      ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final d = destinations[index];
                final isActive = activeRoute == d.route;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go(d.route),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: isActive
                              ? const LinearGradient(colors: AppTheme.primaryGradient)
                              : null,
                          color: !isActive && isActive
                              ? Colors.white10
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              d.icon,
                              color: isActive ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              d.label,
                              style: TextStyle(
                                color: isActive ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  final List<_NavDestination> destinations;
  final String activeRoute;

  const _MobileDrawer({required this.destinations, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Semestra Workspace',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final d = destinations[index];
                  final isActive = activeRoute == d.route;

                  return ListTile(
                    leading: Icon(
                      d.icon,
                      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    title: Text(
                      d.label,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? Theme.of(context).colorScheme.primary : null,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(d.route);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
