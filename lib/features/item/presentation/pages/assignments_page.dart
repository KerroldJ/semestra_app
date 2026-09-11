import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../item_selectors.dart';
import '../providers/item_provider.dart';

/// Screens 10–12 — Assignments. All open, dated work (assignments + tasks)
/// grouped by urgency: Overdue / This week / Later. Priority shows as a
/// stroked label; status drives a hairline progress bar. Tapping the leading
/// circle toggles completion.
class AssignmentsPage extends ConsumerWidget {
  const AssignmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    final groups = UrgencyGroups.from(items, now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assignments/edit'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        shape: const CircleBorder(
          side: BorderSide(color: AppTheme.gold, width: 1.6),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.goldDeep),
      ),
      body: SafeArea(
        top: false,
        child: groups.isEmpty
            ? const _EmptyAssignments()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                children: [
                  _Section(
                    label: 'Overdue',
                    labelColor: AppTheme.danger,
                    items: groups.overdue,
                    subjectsById: subjectsById,
                    now: now,
                    ref: ref,
                  ),
                  _Section(
                    label: 'This week',
                    items: groups.thisWeek,
                    subjectsById: subjectsById,
                    now: now,
                    ref: ref,
                  ),
                  _Section(
                    label: 'Later',
                    items: groups.later,
                    subjectsById: subjectsById,
                    now: now,
                    ref: ref,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final List<ItemEntity> items;
  final Map<String, SubjectEntity> subjectsById;
  final DateTime now;
  final WidgetRef ref;

  const _Section({
    required this.label,
    this.labelColor,
    required this.items,
    required this.subjectsById,
    required this.now,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Eyebrow(label, color: labelColor),
            const SizedBox(width: 8),
            Text('${items.length}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.merge(AppTheme.tnum)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssignmentCard(
                item: i,
                subject: subjectsById[i.subjectId],
                now: now,
                onToggle: () => ref
                    .read(itemNotifierProvider.notifier)
                    .toggleTaskCompletion(i),
                onOpen: () => context.push('/assignments/edit', extra: i),
              ),
            )),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final ItemEntity item;
  final SubjectEntity? subject;
  final DateTime now;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  const _AssignmentCard({
    required this.item,
    required this.subject,
    required this.now,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : (isDark ? Colors.white24 : AppTheme.inkFaint);
    final overdue = item.urgencyFrom(now) == Urgency.overdue;
    // status: 0 = not started, 1 = in progress, 2 = done.
    final progress = item.status == 2 ? 1.0 : (item.status == 1 ? 0.5 : 0.0);

    return SpineCard(
      spine: spine,
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(top: 1, right: 12),
              child: Icon(
                item.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: item.isCompleted
                    ? AppTheme.success
                    : (isDark ? Colors.white38 : AppTheme.inkFaint),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: item.isCompleted
                            ? (isDark ? Colors.white38 : AppTheme.inkMuted)
                            : null,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject?.name ??
                            (item.type == ItemType.assignment
                                ? 'Assignment'
                                : 'Task'),
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      Fmt.dueLabel(item.dueDate!),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.merge(AppTheme.tnum)
                          .copyWith(
                            color: overdue
                                ? AppTheme.danger
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : AppTheme.inkMuted),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                if (!item.isCompleted) ...[
                  const SizedBox(height: 10),
                  ProgressBar(
                    value: progress,
                    color: spine,
                    height: 3,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          PriorityLabel(item.priority),
        ],
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded,
                size: 36,
                color: isDark ? Colors.white38 : AppTheme.inkFaint),
            const SizedBox(height: 14),
            Text(
              'Nothing due',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'When you add assignments or tasks with a due date, '
              'they’ll show up here — grouped by how soon they’re due.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
