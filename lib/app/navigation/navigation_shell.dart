import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/compose_sheet.dart';

final ValueNotifier<bool> fabHiddenNotifier = ValueNotifier<bool>(false);

/// The app shell with a **floating island** bottom nav that hovers above the
/// content, with Semester in the middle, plus a floating compose button on the lower right:
///   Home · Planner · Semester · Subjects · Notes
class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  static const _navItems = [
    _NavItem('/today', Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem('/planner', Icons.calendar_month_outlined,
        Icons.calendar_month_rounded, 'Calendar'),
    _NavItem('/semesters', Icons.school_outlined,
        Icons.school_rounded, 'Semester'),
    _NavItem('/subjects', Icons.menu_book_outlined, Icons.menu_book_rounded,
        'Subjects'),
    _NavItem('/notes', Icons.sticky_note_2_outlined,
        Icons.sticky_note_2_rounded, 'Notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: fabHiddenNotifier,
      builder: (context, isFabHidden, _) {
        return Scaffold(
          // Let the body flow behind the floating bar.
          extendBody: true,
          body: child,
          floatingActionButton: isFabHidden
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FloatingActionButton(
                    onPressed: () => showComposeSheet(context),
                    backgroundColor: AppTheme.brand,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : AppTheme.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (final t in _navItems)
                      Expanded(child: _Tab(item: t, location: location)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
    final isSemester = item.route == '/semesters';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isSemester) {
      final circleBg = active
          ? AppTheme.brand
          : (isDark
              ? AppTheme.soft(AppTheme.brand, 0.22)
              : AppTheme.soft(AppTheme.brand, 0.14));
      final iconColor = active ? Colors.white : AppTheme.brandDeep;
      final textColor = active
          ? AppTheme.brandDeep
          : (isDark ? AppTheme.brand : AppTheme.brandDeep);

      return InkResponse(
        onTap: () => context.go(item.route),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 38,
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: circleBg,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppTheme.brand.withValues(alpha: 0.36),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    active ? item.activeIcon : item.icon,
                    size: 21,
                    color: iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    final color = active ? AppTheme.brandDeep : AppTheme.inkFaint;
    return InkResponse(
      onTap: () => context.go(item.route),
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 38,
            child: Center(
              child: Icon(
                active ? item.activeIcon : item.icon,
                size: 22,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
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
