import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/item/domain/entities/item_entity.dart';
import 'quick_add_sheet.dart'
    show showNewNoteSheet, showNewWorkItemSheet, showNewStudySessionSheet;

/// Screen 09 — the compose sheet opened by the center compose ring.
/// Four choices: Assignment / Task / Note / Study block.
Future<void> showComposeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.28),
    builder: (_) => const _ComposeSheet(),
  );
}

class _ComposeSheet extends StatelessWidget {
  const _ComposeSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkElevated : AppTheme.bg;

    void openThen(void Function() open) {
      Navigator.of(context).pop();
      open();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: AppTheme.gold.withOpacity(0.30), width: 1),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.inkFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
                child: Row(
                  children: [
                    Text('Compose',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              _ComposeOption(
                icon: Icons.assignment_outlined,
                title: 'Assignment',
                subtitle: 'Graded work with a due date',
                onTap: () => openThen(
                    () => showNewWorkItemSheet(context, ItemType.assignment)),
              ),
              _ComposeOption(
                icon: Icons.check_circle_outline_rounded,
                title: 'Task',
                subtitle: 'Something to get done',
                onTap: () =>
                    openThen(() => showNewWorkItemSheet(context, ItemType.task)),
              ),
              _ComposeOption(
                icon: Icons.description_outlined,
                title: 'Note',
                subtitle: 'Capture a quick thought',
                onTap: () => openThen(() => showNewNoteSheet(context)),
              ),
              _ComposeOption(
                icon: Icons.schedule_rounded,
                title: 'Study block',
                subtitle: 'Reserve time on your planner',
                onTap: () => openThen(() => showNewStudySessionSheet(context)),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ComposeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Gold stroke-only ring around the icon.
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 1.5),
              ),
              child: Icon(icon, color: AppTheme.goldDeep, size: 21),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.inkFaint),
          ],
        ),
      ),
    );
  }
}
