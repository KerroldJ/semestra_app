import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subject_provider.dart';

/// Screen 13 — Subjects. Card list with per-subject counts + next due date.
class SubjectsTabPage extends ConsumerWidget {
  const SubjectsTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];

    final active = semesters.isEmpty
        ? null
        : semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);
    final visible = active == null
        ? subjects
        : subjects.where((s) => s.semesterId == active.id).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(active?.name ?? 'Subjects'),
                    const SizedBox(height: 4),
                    Text('Subjects',
                        style:
                            theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (visible.isEmpty)
              _EmptySubjects(hasSemester: active != null)
            else
              ...visible.map((s) {
                final subjectItems =
                    items.where((i) => i.subjectId == s.id).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectCard(
                    subject: s,
                    items: subjectItems,
                    onTap: () => context.push('/subjects/${s.id}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectEntity subject;
  final List<ItemEntity> items;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.subject,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spine = AppTheme.spineFor(subject.colorValue);
    final notes = items.where((i) => i.type == ItemType.note).length;
    final tasks = items
        .where((i) => i.type != ItemType.note && !i.isCompleted)
        .length;

    final openDated = items
        .where((i) => i.type != ItemType.note && !i.isCompleted && i.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final nextDue = openDated.isEmpty ? null : openDated.first.dueDate;

    return SpineCard(
      spine: spine,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (subject.code.isNotEmpty) ...[
                Text(subject.code,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppTheme.goldDeep)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(subject.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.inkFaint, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(icon: Icons.sticky_note_2_outlined, label: '$notes notes'),
              const SizedBox(width: 18),
              _Meta(icon: Icons.check_circle_outline_rounded, label: '$tasks open'),
              const Spacer(),
              if (nextDue != null)
                Text('Next · ${Fmt.dueLabel(nextDue)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.merge(AppTheme.tnum)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.inkFaint),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  final bool hasSemester;
  const _EmptySubjects({required this.hasSemester});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book_outlined,
              size: 30, color: AppTheme.inkFaint),
          const SizedBox(height: 12),
          Text(
            hasSemester
                ? 'No subjects in this semester yet.'
                : 'Create a semester to add subjects.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
