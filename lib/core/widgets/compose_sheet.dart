import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/item/domain/entities/item_entity.dart';
import '../../features/semester/presentation/pages/semester_page.dart'
    show showSemesterSheet;
import '../../features/semester/presentation/providers/semester_provider.dart';
import '../../features/subject/presentation/providers/subject_provider.dart';
import 'quick_add_sheet.dart'
    show
        showNewNoteSheet,
        showNewWorkItemSheet,
        showNewSubjectSheet;

/// Screen 09 — the compose sheet opened by the center compose ring.
/// Semester is first; items that require a Semester or Subject are disabled
/// when prerequisites have not been created yet.
Future<void> showComposeSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (_) => const _ComposeSheet(),
  );
}

class _ComposeSheet extends ConsumerWidget {
  const _ComposeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkElevated : AppTheme.bg;

    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];

    final hasSemesters = semesters.isNotEmpty;
    final hasSubjects = subjects.isNotEmpty;

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
          border: Border.all(
              color: AppTheme.brand.withValues(alpha: 0.30), width: 1),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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

                // 1. Semester — always first and enabled
                _ComposeOption(
                  icon: Icons.calendar_month_outlined,
                  title: 'Semester',
                  subtitle: 'Create a new academic term',
                  isEnabled: true,
                  onTap: () => openThen(() => showSemesterSheet(context)),
                ),

                // 2. Subject — relies on Semester
                _ComposeOption(
                  icon: Icons.menu_book_outlined,
                  title: 'Subject',
                  subtitle: hasSemesters
                      ? 'Add a course under a semester'
                      : 'Requires a semester first',
                  isEnabled: hasSemesters,
                  onTap: () => openThen(() => showNewSubjectSheet(context)),
                ),

                // 3. Assignment — relies on Semester & Subject
                _ComposeOption(
                  icon: Icons.assignment_outlined,
                  title: 'Assignment',
                  subtitle: !hasSemesters
                      ? 'Requires a semester first'
                      : (!hasSubjects
                          ? 'Requires a subject first'
                          : 'Graded work with a due date'),
                  isEnabled: hasSemesters && hasSubjects,
                  onTap: () => openThen(
                      () => showNewWorkItemSheet(context, ItemType.assignment)),
                ),

                // 4. Task — relies on Semester & Subject
                _ComposeOption(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Task',
                  subtitle: !hasSemesters
                      ? 'Requires a semester first'
                      : (!hasSubjects
                          ? 'Requires a subject first'
                          : 'Something to get done'),
                  isEnabled: hasSemesters && hasSubjects,
                  onTap: () => openThen(
                      () => showNewWorkItemSheet(context, ItemType.task)),
                ),

                // 5. Note — relies on Semester & Subject
                _ComposeOption(
                  icon: Icons.description_outlined,
                  title: 'Note',
                  subtitle: !hasSemesters
                      ? 'Requires a semester first'
                      : (!hasSubjects
                          ? 'Requires a subject first'
                          : 'Capture a quick thought'),
                  isEnabled: hasSemesters && hasSubjects,
                  onTap: () => openThen(() => showNewNoteSheet(context)),
                ),
                const SizedBox(height: 14),
              ],
            ),
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
  final bool isEnabled;

  const _ComposeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isEnabled ? AppTheme.brand : AppTheme.inkFaint.withValues(alpha: 0.3);
    final iconColor = isEnabled ? AppTheme.brandDeep : AppTheme.inkFaint;
    final textColor = isEnabled ? null : AppTheme.inkMuted;
    final subtitleColor = isEnabled ? AppTheme.inkMuted : AppTheme.inkFaint;

    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 1.5),
                  color: isEnabled ? null : AppTheme.soft(AppTheme.inkFaint, 0.06),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Icon(
                isEnabled ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                color: AppTheme.inkFaint,
                size: isEnabled ? 20 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

