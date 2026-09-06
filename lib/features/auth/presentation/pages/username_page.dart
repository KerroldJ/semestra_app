import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/username_validator.dart';
import '../auth_provider.dart';

/// Screen 03 — choose a username. Availability + counter, suggestion chips and
/// a live validation checklist. Validated locally (shape only; uniqueness is
/// out of scope for the offline MVP).
class UsernamePage extends ConsumerStatefulWidget {
  const UsernamePage({super.key});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends ConsumerState<UsernamePage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<String> _suggestions = const [];
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authNotifierProvider).profile;
    final name = profile?.displayName ?? '';
    final email = profile?.email ?? '';
    _suggestions = _buildSuggestions(name, email);

    final seed = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll(RegExp(r'^[^a-z]+'), '');
    if (seed.isNotEmpty) _controller.text = seed;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply(String value) {
    _controller.text = value;
    _controller.selection =
        TextSelection.collapsed(offset: value.length);
    setState(() => _touched = true);
  }

  void _continue() {
    setState(() => _touched = true);
    final value = _controller.text.trim();
    if (!UsernameValidator.isValid(value)) return;
    ref.read(authNotifierProvider.notifier).setUsername(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(authNotifierProvider).profile;
    final value = _controller.text.trim();
    final lengthOk = UsernameValidator.lengthOk(value);
    final charsetOk = UsernameValidator.charsetOk(value);
    final valid = lengthOk && charsetOk;
    final showError = _touched && value.isNotEmpty && !valid;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
          children: [
            // Signed-in banner.
            if (profile != null)
              Row(
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Signed in as ${profile.email}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            const SizedBox(height: 22),
            Text('Pick a username',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              'This is how Semestra greets you, and how classmates find you if '
              'you ever share a subject.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.inkMuted,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 26),

            // Field label.
            Text('Username',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.inkMuted,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              focusNode: _focus,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (!_touched) setState(() => _touched = true);
              },
              onSubmitted: (_) => _continue(),
              decoration: InputDecoration(
                prefixText: '@ ',
                prefixStyle: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.inkMuted,
                  fontSize: 15.5,
                ),
                hintText: 'username',
                suffixIcon: valid
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.success, size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: 8),

            // Availability + counter.
            Row(
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
                  Text('Available',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.success))
                else
                  const SizedBox.shrink(),
                Text(
                  '${value.length} / ${UsernameValidator.maxLength}',
                  style: theme.textTheme.bodySmall?.merge(AppTheme.tnum),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Suggestions.
            if (_suggestions.isNotEmpty) ...[
              Text('OR TAKE ONE OF THESE',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.9,
                    color: AppTheme.inkMuted,
                  )),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _suggestions
                    .map((s) => _SuggestionChip(
                          label: '@$s',
                          onTap: () => _apply(s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 22),
              const Divider(height: 1, color: AppTheme.hairline),
              const SizedBox(height: 18),
            ],

            // Validation checklist.
            _Check(ok: lengthOk, text: '3 to 20 characters'),
            const SizedBox(height: 8),
            _Check(
                ok: charsetOk,
                text: 'Letters, numbers, full stops and underscores'),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: valid ? _continue : null,
                child: const Text('Continue to setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _buildSuggestions(String displayName, String email) {
    final local = email
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]'), '');
    final parts = displayName
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceAll(RegExp(r'[^a-z0-9]'), ''))
        .where((p) => p.isNotEmpty)
        .toList();
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.last : '';
    final yy = (DateTime.now().year % 100).toString();

    final candidates = <String>[
      if (first.isNotEmpty && last.isNotEmpty) '$first.${last[0]}',
      if (last.isNotEmpty) '$last$yy',
      if (first.isNotEmpty) '${first}studies',
      if (local.isNotEmpty) local,
    ];
    final seen = <String>{};
    return candidates
        .where((c) => UsernameValidator.isValid(c) && seen.add(c))
        .take(3)
        .toList();
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppTheme.ink,
          ),
        ),
      ),
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
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: ok ? AppTheme.success : AppTheme.inkFaint,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ok ? AppTheme.ink : AppTheme.inkMuted,
                ),
          ),
        ),
      ],
    );
  }
}
