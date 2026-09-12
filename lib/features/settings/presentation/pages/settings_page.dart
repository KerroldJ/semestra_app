import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/database/database_backup_service.dart';
import '../../../auth/domain/username_validator.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../resource/presentation/providers/resource_provider.dart';
import '../providers/settings_provider.dart';

/// Screen 18 — Settings. Account (signed-in-as + sign out), Appearance,
/// Reminders, Semester, and the offline "Your data" story (export / restore).
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _defaultBackupDir;

  @override
  void initState() {
    super.initState();
    _loadDefaultBackupDir();
  }

  Future<void> _loadDefaultBackupDir() async {
    final dir = await DatabaseBackupService.getDefaultBackupDirectory();
    if (mounted) {
      setState(() => _defaultBackupDir = dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final profile = ref.watch(authNotifierProvider).profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentBackupPath = settings.backupDirectoryPath?.isNotEmpty == true
        ? settings.backupDirectoryPath!
        : (_defaultBackupDir ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Custom back button without a Tooltip. The default AppBar back button
        // carries a "Back" tooltip whose overlay calls localToGlobal on the
        // button; because this route animates in via a SlideTransition
        // (RenderFractionalTranslation), that target can be unsized mid-frame
        // and the tooltip overlay asserts. Dropping the tooltip avoids it.
        leading: IconButton(
          icon: const BackButtonIcon(),
          onPressed: () => context.pop(),
        ),
      ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChoiceTile(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    value: AppTheme.optionFor(settings.themeMode).label,
                    onTap: () => context.push('/settings/themes'),
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

                  // Save Location Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E2822)
                          : const Color(0xFFF4F7F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isDark ? Colors.white12 : const Color(0xFFE2E9E4),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _customizeBackupPath(currentBackupPath),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF224433)
                                      : const Color(0xFFDEF5E9),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(
                                  Icons.folder_outlined,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFF5EE59A)
                                      : const Color(0xFF0A7D43),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Save location',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0D3B2C),
                                          ),
                                        ),
                                        if (settings.backupDirectoryPath !=
                                                null &&
                                            settings.backupDirectoryPath!
                                                .isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF16A34A)
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Custom',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentBackupPath.isNotEmpty
                                          ? currentBackupPath
                                          : 'Tap to customize save folder...',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF6B8074),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF8B9E94),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export backup file'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _importBackup,
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Import backup file'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Semestra · offline-first',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Version 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF8B9E94),
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

  // ---- Actions ----

  Future<void> _customizeBackupPath(String currentPath) async {
    final controller = TextEditingController(text: currentPath);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF224433)
                    : const Color(0xFFDEF5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF5EE59A) : const Color(0xFF0A7D43),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Save Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the directory path where backup files will be saved, or select a folder from your device.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Folder Path',
                hintText: '/storage/emulated/0/Download',
                suffixIcon: IconButton(
                  tooltip: 'Select folder',
                  icon: const Icon(Icons.folder_open_rounded),
                  onPressed: () async {
                    try {
                      final picked = await FilePicker.getDirectoryPath();
                      if (picked != null && picked.isNotEmpty) {
                        controller.text = picked;
                      }
                    } catch (_) {}
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(settingsNotifierProvider.notifier)
                  .setBackupDirectoryPath(null);
              Navigator.of(ctx).pop();
              AppToast.success('Reset to default backup folder');
            },
            child: const Text('Reset default'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPath = controller.text.trim();
              if (newPath.isNotEmpty) {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setBackupDirectoryPath(newPath);
                AppToast.success('Save path updated');
              } else {
                ref
                    .read(settingsNotifierProvider.notifier)
                    .setBackupDirectoryPath(null);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
      final customPath =
          ref.read(settingsNotifierProvider).backupDirectoryPath;
      final path = await DatabaseBackupService.exportBackup(
          customDirectoryPath: customPath);
      AppToast.success('Backup written to: $path');
    } catch (e) {
      AppToast.error('Backup failed: $e');
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      String? jsonStr;
      if (file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          jsonStr = await f.readAsString();
        }
      } else if (file.bytes != null) {
        jsonStr = utf8.decode(file.bytes!);
      }

      if (jsonStr == null || jsonStr.trim().isEmpty) {
        AppToast.error('Could not read the selected backup file.');
        return;
      }

      final success = await DatabaseBackupService.restoreBackupFromJson(jsonStr);
      if (!mounted) return;
      if (success) {
        AppToast.success('Backup restored successfully!');
        ref.invalidate(settingsNotifierProvider);
        ref.invalidate(authNotifierProvider);
        ref.invalidate(semesterNotifierProvider);
        ref.invalidate(subjectNotifierProvider);
        ref.invalidate(scheduleNotifierProvider);
        ref.invalidate(itemNotifierProvider);
        ref.invalidate(resourceNotifierProvider);
      } else {
        AppToast.error('Could not parse that backup. Check the file.');
      }
    } catch (e) {
      AppToast.error('Import failed: $e');
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
              color: isDark ? Theme.of(context).cardColor : AppTheme.elevated,
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

