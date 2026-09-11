import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/database/database_backup_service.dart';
import '../../../auth/domain/username_validator.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Screen 18 — Settings. Account (signed-in-as + sign out), Appearance,
/// Reminders, Semester, and the offline "Your data" story (export / restore).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _restoreController = TextEditingController();

  @override
  void dispose() {
    _restoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final profile = ref.watch(authNotifierProvider).profile;
    final isDark = settings.themeMode == 'dark';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            // ---- Profile ----
            _Section(
              label: 'Profile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.username.isNotEmpty == true
                        ? '@${profile!.username}'
                        : 'No username yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('Stored on this device',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _editUsername,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit username'),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Appearance ----
            _Section(
              label: 'Appearance',
              child: Column(
                children: [
                  _SwitchTile(
                    icon: isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark mode',
                    subtitle: isDark ? 'Warm dark neutrals' : 'Clean warm paper',
                    value: isDark,
                    onChanged: (_) => ref
                        .read(settingsNotifierProvider.notifier)
                        .toggleThemeMode(),
                  ),
                  const _HairlineDivider(),
                  _ChoiceTile(
                    icon: Icons.format_size_rounded,
                    title: 'Text size',
                    value: _textSizeLabel(settings.textSize),
                    onTap: _pickTextSize,
                  ),
                ],
              ),
            ),

            // ---- Reminders ----
            _Section(
              label: 'Reminders',
              child: _SwitchTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Nudges for upcoming deadlines',
                value: settings.notificationsEnabled,
                onChanged: (v) => ref
                    .read(settingsNotifierProvider.notifier)
                    .toggleNotifications(v),
              ),
            ),

            // ---- Semester ----
            _Section(
              label: 'Semester',
              child: _ChoiceTile(
                icon: Icons.view_week_rounded,
                title: 'Week starts on',
                value: _weekdayLabel(settings.weekStartsOn),
                onTap: _pickWeekStart,
              ),
            ),

            // ---- Your data (offline) ----
            _Section(
              label: 'Your data',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Everything stays on this device. Back up or restore your '
                    'semesters, subjects, notes and tasks as a local file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export backup file'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _HairlineDivider(),
                  const SizedBox(height: 14),
                  Text('Restore from a backup',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _restoreController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Paste backup JSON here…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _restoreBackup,
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Restore data'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text('Semestra · offline-first',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Actions ----

  Future<void> _editUsername() async {
    final current = ref.read(authNotifierProvider).profile?.username ?? '';
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditUsernameDialog(initial: current),
    );
    if (!mounted) return;
    if (newName != null && newName.isNotEmpty && newName != current) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).updateUsername(newName);
      if (!mounted) return;
      AppToast.success('Username updated');
    }
  }

  Future<void> _exportBackup() async {
    try {
      final path = await DatabaseBackupService.exportBackup();
      AppToast.success('Backup written to: $path');
    } catch (e) {
      AppToast.error('Backup failed: $e');
    }
  }

  Future<void> _restoreBackup() async {
    final jsonStr = _restoreController.text.trim();
    if (jsonStr.isEmpty) {
      AppToast.error('Paste a backup first.');
      return;
    }
    final success = await DatabaseBackupService.restoreBackupFromJson(jsonStr);
    if (success) {
      _restoreController.clear();
      AppToast.success('Restored. Restart the app to load your data.');
    } else {
      AppToast.error('Could not parse that backup. Check the copy.');
    }
  }

  Future<void> _pickTextSize() async {
    const options = ['small', 'default', 'large'];
    final picked = await _pickOne(
      title: 'Text size',
      options: options.map((o) => (o, _textSizeLabel(o))).toList(),
      current: ref.read(settingsNotifierProvider).textSize,
    );
    if (picked != null) {
      ref.read(settingsNotifierProvider.notifier).setTextSize(picked);
    }
  }

  Future<void> _pickWeekStart() async {
    final options = [1, 6, 7];
    final picked = await _pickOne(
      title: 'Week starts on',
      options: options.map((d) => (d, _weekdayLabel(d))).toList(),
      current: ref.read(settingsNotifierProvider).weekStartsOn,
    );
    if (picked != null) {
      ref.read(settingsNotifierProvider.notifier).setWeekStartsOn(picked);
    }
  }

  Future<T?> _pickOne<T>({
    required String title,
    required List<(T, String)> options,
    required T current,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...options.map((o) => ListTile(
                  title: Text(o.$2),
                  trailing: o.$1 == current
                      ? const Icon(Icons.check_rounded, color: AppTheme.gold)
                      : null,
                  onTap: () => Navigator.pop(ctx, o.$1),
                )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static String _textSizeLabel(String v) {
    switch (v) {
      case 'small':
        return 'Small';
      case 'large':
        return 'Large';
      default:
        return 'Default';
    }
  }

  static String _weekdayLabel(int d) {
    switch (d) {
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }
}

/// A labelled section: an [Eyebrow]-style label above a hairline-bordered card.
class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkElevated : AppTheme.elevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.hairline,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon,
            size: 22, color: isDark ? Colors.white70 : AppTheme.inkMuted),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppTheme.gold,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 22, color: isDark ? Colors.white70 : AppTheme.inkMuted),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.goldDeep)),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: isDark ? Colors.white38 : AppTheme.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 24,
      color: isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.hairline,
      thickness: 1,
    );
  }
}

class _EditUsernameDialog extends StatefulWidget {
  final String initial;
  const _EditUsernameDialog({required this.initial});

  @override
  State<_EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<_EditUsernameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _controller.text.trim();
    final err = UsernameValidator.validate(v);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit username'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          prefixText: '@ ',
          hintText: 'username',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

