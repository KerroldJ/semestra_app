import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/compose_sheet.dart';

/// The 4-tab shell with a center compose ring:
///   Today · Planner · [ compose ] · Subjects · Notes
class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  static const _left = [
    _NavItem('/today', Icons.today_outlined, Icons.today_rounded, 'Today'),
    _NavItem('/planner', Icons.calendar_view_week_outlined,
        Icons.calendar_view_week_rounded, 'Planner'),
  ];
  static const _right = [
    _NavItem('/subjects', Icons.menu_book_outlined, Icons.menu_book_rounded,
        'Subjects'),
    _NavItem('/notes', Icons.sticky_note_2_outlined,
        Icons.sticky_note_2_rounded, 'Notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkElevated : AppTheme.elevated,
          border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : AppTheme.hairline),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final t in _left)
                  Expanded(child: _Tab(item: t, location: location)),
                _ComposeRing(onTap: () => showComposeSheet(context)),
                for (final t in _right)
                  Expanded(child: _Tab(item: t, location: location)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final _NavItem item;
  final String location;
  const _Tab({required this.item, required this.location});

  @override
  Widget build(BuildContext context) {
    final active = location.startsWith(item.route);
    final color = active ? AppTheme.goldDeep : AppTheme.inkFaint;
    return InkWell(
      onTap: () => context.go(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(active ? item.activeIcon : item.icon, size: 23, color: color),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// The gold outlined compose ring at the center of the bar.
class _ComposeRing extends StatelessWidget {
  final VoidCallback onTap;
  const _ComposeRing({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Center(
        child: InkResponse(
          onTap: onTap,
          radius: 34,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.gold, width: 2),
            ),
            child: const Icon(Icons.add_rounded,
                size: 26, color: AppTheme.goldDeep),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
}
