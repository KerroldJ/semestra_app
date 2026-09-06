import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subject_provider.dart';

/// Screen 14 — Subject detail. Overview / Notes / Tasks / Info tabs.
class SubjectDetailPage extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailPage({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    SubjectEntity? subject;
    for (final s in subjects) {
      if (s.id == subjectId) {
        subject = s;
        break;
      }
    }

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Subject not found.')),
      );
    }

    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];

    final subjectItems = items.where((i) => i.subjectId == subjectId).toList();
    final notes =
        subjectItems.where((i) => i.type == ItemType.note).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final tasks =
        subjectItems.where((i) => i.type != ItemType.note).toList()
          ..sort((a, b) {
            final ad = a.dueDate, bd = b.dueDate;
            if (ad == null && bd == null) return 0;
            if (ad == null) return 1;
            if (bd == null) return -1;
            return ad.compareTo(bd);
          });
    final subjectSchedules =
        schedules.where((s) => s.subjectId == subjectId).toList()
          ..sort((a, b) => a.dayOfWeek != b.dayOfWeek
              ? a.dayOfWeek.compareTo(b.dayOfWeek)
              : a.startTime.compareTo(b.startTime));

    final spine = AppTheme.spineFor(subject.colorValue);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (subject.code.isNotEmpty)
                Text(subject.code,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppTheme.goldDeep)),
              Text(subject.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.ink,
            unselectedLabelColor: AppTheme.inkMuted,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Notes'),
              Tab(text: 'Tasks'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
                subject: subject,
                notes: notes,
                tasks: tasks,
                spine: spine),
            _NotesTab(notes: notes, spine: spine),
            _TasksTab(
              tasks: tasks,
              spine: spine,
              onToggle: (i) =>
                  ref.read(itemNotifierProvider.notifier).toggleTaskCompletion(i),
            ),
            _InfoTab(subject: subject, schedules: subjectSchedules),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SubjectEntity subject;
  final List<ItemEntity> notes;
  final List<ItemEntity> tasks;
  final Color spine;
  const _OverviewTab({
    required this.subject,
    required this.notes,
    required this.tasks,
    required this.spine,
  });

  @override
  Widget build(BuildContext context) {
    final open = tasks.where((t) => !t.isCompleted).toList();
    final done = tasks.length - open.length;
    final completion = tasks.isEmpty ? 0.0 : done / tasks.length;
    final openDated = open.where((t) => t.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final nextDue = openDated.isEmpty ? null : openDated.first.dueDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                  value: '${notes.length}',
                  label: 'Notes',
                  color: AppTheme.goldDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                  value: '${open.length}',
                  label: 'Open tasks',
                  color: AppTheme.gold),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Eyebrow('Completion'),
        const SizedBox(height: 10),
        SpineCard(
          spine: spine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$done of ${tasks.length} done',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('${(completion * 100).round()}%',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.merge(AppTheme.tnum)),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(value: completion, color: spine),
            ],
          ),
        ),
        if (nextDue != null) ...[
          const SizedBox(height: 18),
          Eyebrow('Next due'),
          const SizedBox(height: 10),
          SpineCard(
            spine: spine,
            child: Row(
              children: [
                Expanded(
                  child: Text(openDated.first.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(Fmt.dueLabel(nextDue),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.merge(AppTheme.tnum)
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NotesTab extends StatelessWidget {
  final List<ItemEntity> notes;
  final Color spine;
  const _NotesTab({required this.notes, required this.spine});

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return const _TabEmpty(
          icon: Icons.sticky_note_2_outlined, text: 'No notes for this subject yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final n = notes[i];
        return SpineCard(
          spine: spine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (n.content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(n.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  final List<ItemEntity> tasks;
  final Color spine;
  final void Function(ItemEntity) onToggle;
  const _TasksTab(
      {required this.tasks, required this.spine, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const _TabEmpty(
          icon: Icons.check_circle_outline_rounded,
          text: 'No tasks or assignments here yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final t = tasks[i];
        return SpineCard(
          spine: spine,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onToggle(t),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    t.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color:
                        t.isCompleted ? AppTheme.success : AppTheme.inkFaint,
                  ),
                ),
              ),
              Expanded(
                child: Text(t.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: t.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: t.isCompleted ? AppTheme.inkMuted : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (t.dueDate != null)
                Text(Fmt.dueLabel(t.dueDate!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.merge(AppTheme.tnum)),
            ],
          ),
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final SubjectEntity subject;
  final List<ScheduleEntity> schedules;
  const _InfoTab({required this.subject, required this.schedules});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Instructor',
            value: subject.instructor.isEmpty ? '—' : subject.instructor),
        _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Classroom',
            value: subject.classroom.isEmpty ? '—' : subject.classroom),
        _InfoRow(
            icon: Icons.school_outlined,
            label: 'Units',
            value: '${subject.units}'),
        const SizedBox(height: 18),
        Eyebrow('Schedule'),
        const SizedBox(height: 10),
        if (schedules.isEmpty)
          const _TabEmpty(
              icon: Icons.schedule_rounded,
              text: 'No class times set for this subject.',
              embedded: true)
        else
          ...schedules.map((s) {
            final day = (s.dayOfWeek >= 1 && s.dayOfWeek <= 7)
                ? Fmt.weekdayAbbr[s.dayOfWeek - 1]
                : '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SpineCard(
                spine: AppTheme.spineFor(subject.colorValue),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(day,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppTheme.goldDeep)),
                    ),
                    Expanded(
                      child: Text(
                        '${Fmt.time12(s.startTime)} – ${Fmt.time12(s.endTime)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.merge(AppTheme.tnum),
                      ),
                    ),
                    if (s.classroom.isNotEmpty)
                      Text(s.classroom,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppTheme.inkMuted),
        title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(value,
            style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _TabEmpty extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool embedded;
  const _TabEmpty(
      {required this.icon, required this.text, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 30, color: AppTheme.inkFaint),
        const SizedBox(height: 12),
        Text(text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
    if (embedded) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: body,
      );
    }
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: body));
  }
}
