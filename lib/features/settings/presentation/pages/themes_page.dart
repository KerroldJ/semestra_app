import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

/// Full-screen theme gallery reached from Settings → Appearance → Theme.
/// Lays out every theme in [AppTheme.themeOptions] as a two-column grid of
/// cards, each with a live mini-preview, and applies the selection instantly.
class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedKey = ref.watch(settingsNotifierProvider).themeMode;
    final selected = AppTheme.optionFor(selectedKey);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Pick a look for Semestra. Your choice is saved on this device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.70,
                children: [
                  for (final option in AppTheme.themeOptions)
                    _ThemeCard(
                      option: option,
                      selected: option.key == selected.key,
                      onTap: () => ref
                          .read(settingsNotifierProvider.notifier)
                          .setThemeMode(option.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable theme card laid out vertically for the grid: a mini app-screen
/// preview on top, then the name / description and a selection indicator.
/// Selected cards gain a brand-green outline.
class _ThemeCard extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppTheme.hairlineBorder(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniPreview(option: option),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.label,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? accent : AppTheme.textFaint(context),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                option.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              _StatusChip(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool selected;
  const _StatusChip({required this.selected});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    if (!selected) {
      return Text(
        'Tap to apply',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textFaint(context)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.soft(AppTheme.brand, 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Active',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

/// A small mock of an app screen rendered entirely in the option's palette:
/// a status row, a brand hero card, and two list rows. Gives an at-a-glance
/// sense of the theme without applying it.
class _MiniPreview extends StatelessWidget {
  final AppThemeOption option;
  const _MiniPreview({required this.option});

  @override
  Widget build(BuildContext context) {
    final ink = option.previewInk;
    return Container(
      width: double.infinity,
      height: 112,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: option.previewBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faux title row with a small icon so the icon tint is visible.
          Row(
            children: [
              _bar(width: 34, height: 6, color: ink.withValues(alpha: 0.85)),
              const Spacer(),
              Icon(Icons.circle, size: 8, color: ink),
            ],
          ),
          const SizedBox(height: 8),
          // Accent hero card (reflects the theme's accent color).
          Container(
            height: 28,
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  option.previewAccent,
                  Color.lerp(option.previewAccent, Colors.black, 0.35)!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(width: 30, height: 4, color: Colors.white),
                const SizedBox(height: 4),
                _bar(
                    width: 20,
                    height: 4,
                    color: Colors.white.withValues(alpha: 0.7)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _previewCardRow(ink),
          const SizedBox(height: 6),
          _previewCardRow(ink),
        ],
      ),
    );
  }

  Widget _previewCardRow(Color ink) {
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: option.previewCard,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: ink),
          const SizedBox(width: 5),
          _bar(width: 30, height: 4, color: ink.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _bar(
      {required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
