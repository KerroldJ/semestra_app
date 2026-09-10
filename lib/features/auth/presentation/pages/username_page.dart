import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/username_validator.dart';
import '../auth_provider.dart';

/// First launch — pick a username. There is no account and no sign-in; the
/// handle is stored locally and the app is unlocked immediately.
///
/// Responsive: a branded two-panel layout on wide windows (desktop / web /
/// tablet), and a single centered card on phones.
class UsernamePage extends ConsumerStatefulWidget {
  const UsernamePage({super.key});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends ConsumerState<UsernamePage> {
  final _controller = TextEditingController();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _submitting = false;

  Future<void> _continue() async {
    setState(() => _touched = true);
    final value = _controller.text.trim();
    if (_submitting || !UsernameValidator.isValid(value)) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).createUsername(value);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        AppToast.error('Could not save username: $e');
      }
      return;
    }
    // Navigate explicitly rather than waiting on the router's refresh
    // listener — guarantees we leave the onboarding screen once saved.
    if (mounted) context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 860;
          if (wide) {
            return Row(
              children: [
                const Expanded(flex: 6, child: _BrandPanel()),
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: _FormSection(
                          controller: _controller,
                          touched: _touched,
                          submitting: _submitting,
                          onTouched: () => setState(() => _touched = true),
                          onSubmit: _continue,
                          showBrandMark: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _FormSection(
                  controller: _controller,
                  touched: _touched,
                  submitting: _submitting,
                  onTouched: () => setState(() => _touched = true),
                  onSubmit: _continue,
                  showBrandMark: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The dark, branded left panel shown on wide layouts.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.heroGradient,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Wordmark(size: 46, color: Colors.white),
            const SizedBox(height: 20),
            SizedBox(
              width: 340,
              child: Text(
                'Your semester, organized. Classes, tasks and notes — '
                'all in one place, and entirely yours.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: Colors.white.withOpacity(0.66),
                  fontSize: 16,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 44),
            const _Feature(
                icon: Icons.wifi_off_rounded, text: 'Works fully offline'),
            const SizedBox(height: 18),
            const _Feature(
                icon: Icons.lock_outline_rounded,
                text: 'No account or sign-in required'),
            const SizedBox(height: 18),
            const _Feature(
                icon: Icons.phone_iphone_rounded,
                text: 'Your data stays on this device'),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppTheme.brand),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// The username form, shared by both layouts.
class _FormSection extends StatelessWidget {
  final TextEditingController controller;
  final bool touched;
  final bool submitting;
  final VoidCallback onTouched;
  final VoidCallback onSubmit;
  final bool showBrandMark;

  const _FormSection({
    required this.controller,
    required this.touched,
    required this.submitting,
    required this.onTouched,
    required this.onSubmit,
    required this.showBrandMark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = controller.text.trim();
    final lengthOk = UsernameValidator.lengthOk(value);
    final charsetOk = UsernameValidator.charsetOk(value);
    final valid = lengthOk && charsetOk;
    final showError = touched && value.isNotEmpty && !valid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBrandMark) ...[
          const Center(
            child: Wordmark(size: 34, color: AppTheme.brand),
          ),
          const SizedBox(height: 28),
        ],
        Text(
          'Create your username',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 28,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This is how Semestra greets you. You can change it anytime in '
          'Settings.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.inkMuted,
            height: 1.5,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 32),

        Text(
          'USERNAME',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.inkMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            LengthLimitingTextInputFormatter(UsernameValidator.maxLength),
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          onChanged: (_) {
            if (!touched) onTouched();
          },
          onSubmitted: (_) => onSubmit(),
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixText: '@ ',
            prefixStyle: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppTheme.inkMuted,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
            hintText: 'username',
            suffixIcon: valid
                ? const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 22)
                : null,
          ),
        ),
        const SizedBox(height: 8),

        SizedBox(
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showError)
                Flexible(
                  child: Text(
                    UsernameValidator.validate(value) ?? '',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.danger),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else if (valid)
                Row(
                  children: [
                    const Icon(Icons.check_rounded,
                        size: 14, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text('Looks good',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.success)),
                  ],
                )
              else
                const SizedBox.shrink(),
              Text(
                '${value.length} / ${UsernameValidator.maxLength}',
                style: theme.textTheme.bodySmall?.merge(AppTheme.tnum),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        _Check(ok: lengthOk, text: 'Between 3 and 20 characters'),
        const SizedBox(height: 10),
        _Check(
            ok: charsetOk,
            text: 'Letters, numbers, full stops and underscores'),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (valid && !submitting) ? onSubmit : null,
            style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get started'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  final bool ok;
  final String text;
  const _Check({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 18,
          color: ok ? AppTheme.success : AppTheme.inkFaint,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ok ? AppTheme.ink : AppTheme.inkMuted,
                  fontSize: 13.5,
                ),
          ),
        ),
      ],
    );
  }
}
