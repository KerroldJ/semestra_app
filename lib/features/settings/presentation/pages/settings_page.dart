import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../../../core/database/database_backup_service.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final theme = Theme.of(context);
    final restoreController = TextEditingController();

    final availableOptions = [
      {'route': '/dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard_rounded},
      {'route': '/semesters', 'label': 'Semesters', 'icon': Icons.calendar_month_rounded},
      {'route': '/subjects', 'label': 'Subjects', 'icon': Icons.book_rounded},
      {'route': '/schedule', 'label': 'Schedule', 'icon': Icons.schedule_rounded},
      {'route': '/notes', 'label': 'Notes', 'icon': Icons.edit_note_rounded},
      {'route': '/planner', 'label': 'Planner', 'icon': Icons.task_alt_rounded},
      {'route': '/timer', 'label': 'Study Timer', 'icon': Icons.timer_rounded},
      {'route': '/assignments', 'label': 'Assignments', 'icon': Icons.assignment_rounded},
      {'route': '/exams', 'label': 'Assessments', 'icon': Icons.quiz_rounded},
      {'route': '/grades', 'label': 'Grades', 'icon': Icons.analytics_rounded},
      {'route': '/budget', 'label': 'Budget', 'icon': Icons.account_balance_wallet_rounded},
      {'route': '/readings', 'label': 'Readings', 'icon': Icons.menu_book_rounded},
    ];

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Theme Settings Card
          _buildSectionHeader(context, 'Aesthetics & Theme'),
          Card(
            child: ListTile(
              leading: Icon(
                settings.themeMode == 'dark' ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Dark Mode Theme'),
              subtitle: Text(settings.themeMode == 'dark' ? 'Sleek OLED colors' : 'Clean paper theme'),
              trailing: Switch(
                value: settings.themeMode == 'dark',
                onChanged: (_) {
                  ref.read(settingsNotifierProvider.notifier).toggleThemeMode();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Floating Menu Layout Card
          _buildSectionHeader(context, 'Floating Menu Layout'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(5, (index) {
                  final currentRoute = settings.mainTabRoutes.length > index
                      ? settings.mainTabRoutes[index]
                      : ['/dashboard', '/semesters', '/subjects', '/schedule', '/notes'][index];

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentRoute,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            items: availableOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt['route'] as String,
                                child: Row(
                                  children: [
                                    Icon(opt['icon'] as IconData, size: 20, color: theme.colorScheme.primary),
                                    const SizedBox(width: 12),
                                    Text(
                                      opt['label'] as String,
                                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                final newRoutes = List<String>.from(settings.mainTabRoutes);
                                while (newRoutes.length < 5) {
                                  newRoutes.add('');
                                }
                                newRoutes[index] = val;

                                // Self-correcting swap logic to avoid duplicates
                                final existingIndex = settings.mainTabRoutes.indexOf(val);
                                if (existingIndex != -1 && existingIndex != index) {
                                  newRoutes[existingIndex] = currentRoute;
                                }

                                ref.read(settingsNotifierProvider.notifier).updateMainTabRoutes(newRoutes);
                              }
                            },
                          ),
                        ),
                      ),
                      if (index < 4) const Divider(height: 1),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Pomodoro settings card
          _buildSectionHeader(context, 'Study Timer Config'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSliderTile(
                    title: 'Focus Duration',
                    value: settings.pomodoroFocusDuration,
                    min: 5,
                    max: 60,
                    label: '${settings.pomodoroFocusDuration} min',
                    onChanged: (val) {
                      ref.read(settingsNotifierProvider.notifier).updatePomodoroFocus(val.toInt());
                    },
                  ),
                  const Divider(),
                  _buildSliderTile(
                    title: 'Short Break Duration',
                    value: settings.pomodoroShortBreak,
                    min: 1,
                    max: 20,
                    label: '${settings.pomodoroShortBreak} min',
                    onChanged: (val) {
                      ref.read(settingsNotifierProvider.notifier).updatePomodoroShortBreak(val.toInt());
                    },
                  ),
                  const Divider(),
                  _buildSliderTile(
                    title: 'Long Break Duration',
                    value: settings.pomodoroLongBreak,
                    min: 5,
                    max: 30,
                    label: '${settings.pomodoroLongBreak} min',
                    onChanged: (val) {
                      ref.read(settingsNotifierProvider.notifier).updatePomodoroLongBreak(val.toInt());
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Offline Database backup settings
          _buildSectionHeader(context, 'Offline Backup & Sync'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backup operations are entirely local to your device, preserving your data privacy.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final path = await DatabaseBackupService.exportBackup();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Backup written to: $path')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to backup: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Export File'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Restore from JSON Backup String:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: restoreController,
                    decoration: const InputDecoration(
                      hintText: 'Paste backup JSON here...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: () async {
                      final jsonStr = restoreController.text.trim();
                      if (jsonStr.isNotEmpty) {
                        final success = await DatabaseBackupService.restoreBackupFromJson(jsonStr);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Database restored successfully! Restart app to load.')),
                          );
                          restoreController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to parse backup JSON. Please verify copy.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Restore Data'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 4),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required int value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }


}
