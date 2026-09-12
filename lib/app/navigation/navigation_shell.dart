import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
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
          body: NotificationListener<UserScrollNotification>(
            onNotification: (n) {
              // Hide the nav island + compose button while scrolling down,
              // reveal them when scrolling back up.
              if (n.direction == ScrollDirection.reverse) {
                fabHiddenNotifier.value = true;
              } else if (n.direction == ScrollDirection.forward) {
                fabHiddenNotifier.value = false;
              }
              return false;
            },
            child: child,
          ),
          floatingActionButton: AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            offset: isFabHidden ? const Offset(0, 2.4) : Offset.zero,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: isFabHidden ? 0 : 1,
              child: IgnorePointer(
                ignoring: isFabHidden,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: () => showComposeSheet(context),
                    backgroundColor: AppTheme.brandFill(context),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: SafeArea(
            top: false,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: isFabHidden ? const Offset(0, 1.6) : Offset.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 66,
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
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
    final isTokyo = AppTheme.isTokyo(context);

    if (isSemester) {
      final textColor = AppTheme.accent(context);

      return InkResponse(
        onTap: () {
          fabHiddenNotifier.value = false;
          context.go(item.route);
        },
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isTokyo
                          ? const [Color(0xFFF43645), Color(0xFFC1121F)]
                          : active
                              ? const [Color(0xFF00FF85), Color(0xFF00A854)]
                              : const [Color(0xFF0FD679), Color(0xFF00B55A)],
                    ),
                    border: Border.all(
                      color: isDark
                          ? (active ? Colors.white : Colors.white.withValues(alpha: 0.20))
                          : (active ? AppTheme.brandDeep : Colors.white),
                      width: active ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isTokyo ? AppTheme.tokyoAccent : AppTheme.brand)
                            .withValues(alpha: active ? 0.50 : 0.35),
                        blurRadius: active ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    active ? item.activeIcon : item.icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      );
    }

    final color = active
        ? AppTheme.accent(context)
        : (isDark ? Colors.white.withOpacity(0.55) : AppTheme.inkFaint);
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
