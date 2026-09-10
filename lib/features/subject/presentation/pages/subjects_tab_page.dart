import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/quick_add_sheet.dart' show showEditSubjectSheet;
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../semester/domain/entities/semester_entity.dart';
import '../../../semester/presentation/pages/semester_page.dart' show showSemesterSheet;
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subject_provider.dart';

/// Screen 13 — Subjects Tab. Allows viewing, switching, and adding semesters
/// and subjects under those semesters.
class SubjectsTabPage extends ConsumerStatefulWidget {
  const SubjectsTabPage({super.key});

  @override
  ConsumerState<SubjectsTabPage> createState() => _SubjectsTabPageState();
}

class _SubjectsTabPageState extends ConsumerState<SubjectsTabPage> {
  String? _selectedSemesterId;

  void _confirmDeleteSubject(
    BuildContext context,
    SubjectEntity subject,
    List<ScheduleEntity> subjectSchedules,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete ${subject.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(subjectNotifierProvider.notifier).deleteSubject(subject.id);
              for (final sch in subjectSchedules) {
                ref.read(scheduleNotifierProvider.notifier).deleteSchedule(sch.id);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.statRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];

    SemesterEntity? activeSemester;
    if (semesters.isNotEmpty) {
      if (_selectedSemesterId != null &&
          semesters.any((s) => s.id == _selectedSemesterId)) {
        activeSemester =
            semesters.firstWhere((s) => s.id == _selectedSemesterId);
      } else {
        activeSemester =
            semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);
        _selectedSemesterId = activeSemester.id;
      }
    } else {
      activeSemester = null;
      _selectedSemesterId = null;
    }

    final visibleSubjects = activeSemester == null
        ? <SubjectEntity>[]
        : subjects.where((s) => s.semesterId == activeSemester!.id).toList();

    final totalUnits =
        visibleSubjects.fold<double>(0.0, (acc, s) => acc + s.units);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeSemester?.name ?? 'Academic Terms',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Subjects',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (semesters.isEmpty)
              _EmptyNoSemester(onCreateSemester: () => showSemesterSheet(context))
            else if (visibleSubjects.isEmpty)
              _EmptyNoSubjects(
                semesterName: activeSemester!.name,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${visibleSubjects.length} ${visibleSubjects.length == 1 ? 'subject' : 'subjects'} · ${totalUnits.toStringAsFixed(totalUnits.truncateToDouble() == totalUnits ? 0 : 1)} units',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkMuted,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/semester/overview'),
                      child: const Text(
                        'Semester Overview',
                        style: TextStyle(
                          color: AppTheme.brandDeep,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...visibleSubjects.map((s) {
                final subjectItems =
                    items.where((i) => i.subjectId == s.id).toList();
                final subjectSchedules =
                    schedules.where((sch) => sch.subjectId == s.id).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectCard(
                    subject: s,
                    items: subjectItems,
                    schedules: subjectSchedules,
                    onEdit: () => showEditSubjectSheet(
                      context,
                      subject: s,
                      schedules: subjectSchedules,
                    ),
                    onDelete: () =>
                        _confirmDeleteSubject(context, s, subjectSchedules),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectEntity subject;
  final List<ItemEntity> items;
  final List<ScheduleEntity> schedules;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SubjectCard({
    required this.subject,
    required this.items,
    required this.schedules,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final spine = AppTheme.spineFor(subject.colorValue);
    final notes = items.where((i) => i.type == ItemType.note).length;
    final tasks = items
        .where((i) => i.type != ItemType.note && !i.isCompleted)
        .length;

    final openDated = items
        .where((i) =>
            i.type != ItemType.note && !i.isCompleted && i.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final nextDue = openDated.isEmpty ? null : openDated.first.dueDate;

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final daysStr = sortedSchedules
        .map((s) => dayNames[s.dayOfWeek])
        .toSet()
        .join(', ');
    final timeStr = sortedSchedules.isNotEmpty
        ? '${Fmt.time12(sortedSchedules.first.startTime)} – ${Fmt.time12(sortedSchedules.first.endTime)}'
        : '';

    return SpineCard(
      spine: spine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (subject.code.isNotEmpty) ...[
                Text(subject.code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.brandDeep, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(subject.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (subject.units > 0)
                Pill(
                  text: '${subject.units} u',
                  bg: AppTheme.soft(spine, 0.12),
                  fg: spine,
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_rounded,
                        color: AppTheme.inkFaint, size: 19),
                  ),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        color: AppTheme.inkFaint, size: 20),
                  ),
                ),
              ],
            ],
          ),
          if (daysStr.isNotEmpty || subject.classroom.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (daysStr.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.soft(spine, 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: spine),
                        const SizedBox(width: 4),
                        Text(
                          daysStr,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: spine,
                          ),
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '· $timeStr',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: spine,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (subject.classroom.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkElevated
                          : AppTheme.hairline.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.room_outlined,
                            size: 12, color: AppTheme.inkMuted),
                        const SizedBox(width: 4),
                        Text(
                          subject.classroom,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _Meta(icon: Icons.sticky_note_2_outlined, label: '$notes notes'),
              const SizedBox(width: 18),
              _Meta(
                  icon: Icons.check_circle_outline_rounded, label: '$tasks open'),
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

class _EmptyNoSemester extends StatelessWidget {
  final VoidCallback onCreateSemester;
  const _EmptyNoSemester({required this.onCreateSemester});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.soft(AppTheme.brand, 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 28, color: AppTheme.brandDeep),
          ),
          const SizedBox(height: 16),
          Text(
            'No Semester Created',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create an academic semester (e.g. Fall 2026) to add and organize your subjects under it.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateSemester,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Semester'),
          ),
        ],
      ),
    );
  }
}

class _EmptyNoSubjects extends StatelessWidget {
  final String semesterName;
  const _EmptyNoSubjects({required this.semesterName});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.soft(AppTheme.brand, 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 28, color: AppTheme.brandDeep),
          ),
          const SizedBox(height: 16),
          Text(
            'No Subjects in $semesterName',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your classes, lectures, or labs under this semester to begin tracking assignments, notes, and study times.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

