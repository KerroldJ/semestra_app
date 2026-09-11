import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

/// Full-screen theme gallery reached from Settings → Appearance → Theme.
/// Lists every theme in [AppTheme.themeOptions] with a live mini-preview and
/// applies the selection instantly.
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Pick a look for Semestra. Your choice is saved on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            for (final option in AppTheme.themeOptions) ...[
              _ThemeRow(
                option: option,
                selected: option.key == selected.key,
                onTap: () => ref
                    .read(settingsNotifierProvider.notifier)
                    .setThemeMode(option.key),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

/// A selectable theme card: a mini app-screen preview, the name / description,
/// and a selection indicator. Selected cards gain a brand-green outline.
class _ThemeRow extends StatelessWidget {
  final AppThemeOption option;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeRow({
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : AppTheme.hairlineBorder(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _MiniPreview(option: option),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    _StatusChip(selected: selected),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? accent : AppTheme.textFaint(context),
                size: 24,
              ),
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
      width: 92,
      height: 118,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: option.previewBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faux title row.
          _bar(width: 40, height: 6, color: ink.withValues(alpha: 0.85)),
          const SizedBox(height: 8),
          // Brand hero card.
          Container(
            height: 30,
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.brand, AppTheme.brandDeep],
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
      alignment: Alignment.centerLeft,
      child: _bar(width: 34, height: 4, color: ink.withValues(alpha: 0.6)),
    );
  }

  Widget _bar({required double width, required double height, required Color color}) {
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
