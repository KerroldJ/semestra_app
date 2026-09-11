import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The page header used across top-level screens: a small muted eyebrow,
/// a large bold title, and an optional trailing action or search on the right.
class AppScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final VoidCallback? onSearch;
  final Widget? trailing;
  final bool showSearch;

  const AppScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onSearch,
    this.trailing,
    this.showSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.65)
                      : AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
              ),
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (showSearch || onSearch != null)
          _CircleButton(icon: Icons.search_rounded, onTap: onSearch),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 22, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

/// Section title with an optional trailing text action ("View all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontSize: 17)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}

/// A white surface card with rounded corners and a soft shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? Theme.of(context).cardColor : Colors.white),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// One of the small "3 classes today" style metric cards.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppTheme.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded initials avatar tinted with a subject/category color.
class InitialsAvatar extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.text,
    required this.color,
    this.size = 46,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.soft(color, 0.16),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// Small pill label ("8 notes", "Active", ...).
class Pill extends StatelessWidget {
  final String text;
  final Color? bg;
  final Color? fg;
  const Pill({super.key, required this.text, this.bg, this.fg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? (isDark ? Theme.of(context).cardColor : const Color(0xFFF0EFF3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg ??
              (isDark ? Colors.white.withValues(alpha: 0.75) : AppTheme.inkMuted),
        ),
      ),
    );
  }
}

/// Thin rounded progress bar.
class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppTheme.soft(color, 0.16),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// A hairline-bordered card fronted by a 2px tonal subject spine — the
/// redesign's core list unit. Gold/tonal, never a big color fill.
class SpineCard extends StatelessWidget {
  final Color spine;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted; // gold outline (e.g. "Now")

  const SpineCard({
    super.key,
    required this.spine,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppTheme.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppTheme.gold
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppTheme.hairline),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: spine,
              ),
              Expanded(
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// The "Semestra" brand wordmark, set in Poppins (the brand display font).
/// A trailing green dot gives it a small logo-mark feel. Use this instead of
/// an icon tile for the app's identity.
class Wordmark extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? dotColor;

  /// Whether to draw the trailing brand-green dot.
  final bool dot;
  final List<Shadow>? shadows;

  const Wordmark({
    super.key,
    this.size = 28,
    this.color,
    this.dotColor,
    this.dot = true,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkInk
            : AppTheme.ink);
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: AppTheme.brandFont,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: c,
          height: 1.0,
          shadows: shadows,
        ),
        children: [
          const TextSpan(text: 'Semestra'),
          if (dot)
            TextSpan(
              text: '.',
              style: TextStyle(color: dotColor ?? AppTheme.brand),
            ),
        ],
      ),
    );
  }
}

/// A Maya-style quick-action tile: a green-tinted rounded icon square above a
/// short label. Used in the home action grid.
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tint ?? AppTheme.brandDeep;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.hairline),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.soft(AppTheme.brand, 0.14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 23, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single stat rendered inside [HeroCard]'s footer row.
class HeroStat {
  final String value;
  final String label;
  const HeroStat(this.value, this.label);
}

/// The wider "standing" cell rendered at the end of [HeroCard]'s footer row —
/// a caption, a bold value, and a mini progress bar.
class HeroStanding {
  final IconData icon;
  final String label;
  final String value;
  final double progress;
  const HeroStanding({
    required this.value,
    required this.progress,
    this.label = 'Academic Standing',
    this.icon = Icons.insights_rounded,
  });
}

/// The dark "spotlight" hero card at the top of the home screen — the Maya
/// balance-card analog. Greeting + a headline stat on the green→black
/// [AppTheme.heroGradient], a soft brand glow for depth, and an optional inline
/// stats row and/or progress footer.
class HeroCard extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String headline;
  final String? initials;
  final List<HeroStat> stats;
  final HeroStanding? standing;

  /// When set, the greeting becomes a tappable row with a trailing chevron
  /// (e.g. to open Settings).
  final VoidCallback? onGreetingTap;

  /// Optional progress footer (0..1) with a caption, e.g. semester progress.
  final double? progress;
  final String? progressLabel;

  const HeroCard({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.headline,
    this.initials,
    this.stats = const [],
    this.standing,
    this.onGreetingTap,
    this.progress,
    this.progressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppTheme.text(context);
    final muted = AppTheme.textMuted(context);
    final border = AppTheme.hairlineBorder(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Soft brand glow, top-right — a touch of green for depth.
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.brand.withOpacity(isDark ? 0.18 : 0.10),
                      AppTheme.brand.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Greeting(
                              text: greeting,
                              onTap: onGreetingTap,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (initials != null)
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.brand,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.brand.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            initials!,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    headline,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: textColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (stats.isNotEmpty || standing != null) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.only(top: 18),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: border)),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _footerCells(context),
                        ),
                      ),
                    ),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppTheme.soft(AppTheme.brand, 0.16),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.brand),
                      ),
                    ),
                    if (progressLabel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        progressLabel!,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _footerCells(BuildContext context) {
    final cells = <Widget>[];
    void divider() => cells.add(Container(
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AppTheme.hairlineBorder(context),
        ));
    for (final s in stats) {
      if (cells.isNotEmpty) divider();
      cells.add(Expanded(flex: 2, child: _StatCell(stat: s)));
    }
    if (standing != null) {
      if (cells.isNotEmpty) divider();
      cells.add(Expanded(flex: 5, child: _StandingCell(standing: standing!)));
    }
    return cells;
  }
}

class _StandingCell extends StatelessWidget {
  final HeroStanding standing;
  const _StandingCell({required this.standing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(standing.icon, size: 13, color: AppTheme.accent(context)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                standing.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.textMuted(context),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          standing.value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.text(context),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: standing.progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppTheme.soft(AppTheme.brand, 0.16),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brand),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Greeting({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTheme.fontFamily,
      color: AppTheme.text(context),
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    if (onTap == null) {
      return Text(text,
          style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(text,
                style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded,
              size: 22, color: AppTheme.accent(context)),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final HeroStat stat;
  const _StatCell({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.value,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.text(context),
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: AppTheme.textMuted(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// An uppercase eyebrow label ("NOW", "DUE NEXT", "OVERDUE").
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: color ??
            (isDark ? Colors.white.withValues(alpha: 0.65) : AppTheme.inkMuted),
      ),
    );
  }
}

/// A stroked (outline-only) label — used for priority and status so gold /
/// accent color stays a stroke, never a fill.
class StrokeLabel extends StatelessWidget {
  final String text;
  final Color color;
  const StrokeLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

/// Priority (0/1/2) as a stroked label with sensible tones.
class PriorityLabel extends StatelessWidget {
  final int priority;
  const PriorityLabel(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const labels = ['Low', 'Medium', 'High'];
    final colors = [
      isDark ? Colors.white.withValues(alpha: 0.65) : AppTheme.inkMuted,
      AppTheme.gold,
      AppTheme.danger,
    ];
    final i = priority.clamp(0, 2);
    return StrokeLabel(text: labels[i], color: colors[i]);
  }
}
