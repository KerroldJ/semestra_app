import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The page header used across all top-level screens: a small muted eyebrow,
/// a large bold title, and a circular search action on the right.
class AppScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final VoidCallback? onSearch;

  const AppScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onSearch,
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
                  color: AppTheme.inkMuted,
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
      color: isDark ? AppTheme.darkCard : Colors.white,
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
        color: color ?? (isDark ? AppTheme.darkCard : Colors.white),
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
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.inkMuted,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFF0EFF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: fg ?? AppTheme.inkMuted,
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
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkElevated : AppTheme.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppTheme.gold : AppTheme.hairline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: spine,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(padding: padding, child: child),
            ),
          ],
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

/// An uppercase eyebrow label ("NOW", "DUE NEXT", "OVERDUE").
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: color ?? AppTheme.inkMuted,
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
    const labels = ['Low', 'Medium', 'High'];
    final colors = [AppTheme.inkMuted, AppTheme.gold, AppTheme.danger];
    final i = priority.clamp(0, 2);
    return StrokeLabel(text: labels[i], color: colors[i]);
  }
}
