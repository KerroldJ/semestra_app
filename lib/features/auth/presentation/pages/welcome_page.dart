import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Screen 01 — welcome. Term eyebrow, brand, the offline pitch, three feature
/// rows and the entry into sign-in.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
                children: [
                  Text(
                    _termLabel(DateTime.now()),
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AppTheme.goldDeep,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Semestra',
                      style:
                          theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
                  const SizedBox(height: 14),
                  Text(
                    'Your subjects, classes, assignments and notes for one '
                    'semester — held in one place and kept on this device. '
                    'Semestra opens and answers instantly, signal or not.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.inkMuted,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Divider(height: 1, color: AppTheme.hairline),
                  const _Feature(
                    icon: Icons.cloud_off_rounded,
                    title: 'Offline by default',
                    subtitle: 'Nothing waits on a network. Ever.',
                  ),
                  const Divider(height: 1, color: AppTheme.hairline),
                  const _Feature(
                    icon: Icons.calendar_view_week_rounded,
                    title: 'One semester at a time',
                    subtitle: 'Subjects, timetable, deadlines, progress.',
                  ),
                  const Divider(height: 1, color: AppTheme.hairline),
                  const _Feature(
                    icon: Icons.vpn_key_outlined,
                    title: 'Sign in once',
                    subtitle: 'With the Google account you already have.',
                  ),
                  const Divider(height: 1, color: AppTheme.hairline),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Create an account'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: AppTheme.goldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _termLabel(DateTime now) {
    final m = now.month;
    final season = (m >= 3 && m <= 5)
        ? 'SPRING'
        : (m >= 6 && m <= 8)
            ? 'SUMMER'
            : (m >= 9 && m <= 11)
                ? 'AUTUMN'
                : 'WINTER';
    return '$season ${now.year}';
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppTheme.goldDeep),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
