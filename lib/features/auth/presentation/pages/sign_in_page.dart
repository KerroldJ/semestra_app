import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../auth_provider.dart';

/// Screen 02 — create your account with Google. Identity-only; falls back to a
/// clear "not configured" hint when OAuth client ids haven't been set up.
class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    final notConfigured = !auth.signInConfigured;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          children: [
            const SizedBox(height: 8),
            Text('Create your account',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              'Sign in with your Google account. Semestra never asks for a '
              'password and keeps no password of its own.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.inkMuted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),

            if (auth.message != null && !notConfigured) ...[
              _MessageBar(text: auth.message!),
              const SizedBox(height: 14),
            ],

            // Continue with Google.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: auth.busy
                    ? null
                    : () => ref.read(authNotifierProvider.notifier).signIn(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (auth.busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const _GoogleGlyph(),
                    const SizedBox(width: 12),
                    Text(auth.busy ? 'Signing in…' : 'Continue with Google'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (notConfigured) ...[
              const _NotConfiguredHint(),
              const SizedBox(height: 14),
            ],

            // Identity-only reassurance card.
            const _InfoCard(
              icon: Icons.verified_user_outlined,
              text: 'The account only identifies you. Your subjects, notes and '
                  'assignments stay on this device unless you turn sync on '
                  'later.',
            ),
            const SizedBox(height: 22),

            Center(
              child: Text.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall,
                  children: const [
                    TextSpan(text: 'By continuing you agree to the '),
                    TextSpan(
                        text: 'terms',
                        style: TextStyle(
                            color: AppTheme.goldDeep,
                            fontWeight: FontWeight.w600)),
                    TextSpan(text: ' and the '),
                    TextSpan(
                        text: 'privacy notice',
                        style: TextStyle(
                            color: AppTheme.goldDeep,
                            fontWeight: FontWeight.w600)),
                    TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small stroke-only "G" standing in for the Google mark (keeps the gold
/// stroke aesthetic without shipping a brand asset).
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.hairline, width: 1.4),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.ink,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.inkMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _NotConfiguredHint extends StatelessWidget {
  const _NotConfiguredHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 18, color: AppTheme.goldDeep),
              const SizedBox(width: 8),
              Text('Sign-in not configured',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Google OAuth client IDs haven’t been added to this build yet. '
            'See docs/GOOGLE_OAUTH_SETUP.md to finish setup, then rebuild.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MessageBar extends StatelessWidget {
  final String text;
  const _MessageBar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.danger.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
