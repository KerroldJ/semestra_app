import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../providers/semester_provider.dart';
import 'semester_page.dart' show showSemesterSheet;

/// Screen 17 — Semester overview. A week-blocks spine, three headline figures
/// (subjects / current week / progress) and per-subject completion. The
/// settings action in the app bar opens Settings (screen 18).
class SemesterOverviewPage extends ConsumerWidget {
  const SemesterOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];

    final active = semesters.isEmpty
        ? null
        : semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: active == null
          ? const _NoSemester()
          : _Body(
              semesterName: active.name,
              start: active.startDate,
              end: active.endDate,
              now: now,
              subjects: subjects
                  .where((s) => s.semesterId == active.id)
                  .toList(),
              items: items,
            ),
    );
  }
}

class _Body extends StatelessWidget {
  final String semesterName;
  final DateTime start;
  final DateTime end;
  final DateTime now;
  final List<SubjectEntity> subjects;
  final List<ItemEntity> items;

  const _Body({
    required this.semesterName,
    required this.start,
    required this.end,
    required this.now,
    required this.subjects,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = end.difference(start).inDays;
    final elapsedDays =
        now.difference(start).inDays.clamp(0, totalDays <= 0 ? 0 : totalDays);
    final totalWeeks = totalDays <= 0 ? 1 : (totalDays / 7).ceil().clamp(1, 20);
    final currentWeek =
        (elapsedDays / 7).floor().clamp(0, totalWeeks - 1) + 1;
    final frac = totalDays <= 0 ? 0.0 : elapsedDays / totalDays;

    final work = items.where((i) => i.type != ItemType.note).toList();
    final done = work.where((i) => i.isCompleted).length;
    final completion = work.isEmpty ? 0.0 : done / work.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      children: [
        Text(semesterName,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Text(
          '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Three headline figures.
        Row(
          children: [
            Expanded(
              child: StatTile(
                  value: '${subjects.length}',
                  label: 'Subjects',
                  color: AppTheme.goldDeep),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                  value: '$currentWeek/$totalWeeks',
                  label: 'Week',
                  color: AppTheme.gold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                  value: '${(completion * 100).round()}%',
                  label: 'Done',
                  color: AppTheme.success),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Week-blocks spine.
        Eyebrow('Term progress'),
        const SizedBox(height: 12),
        _WeekBlocks(total: totalWeeks, current: currentWeek),
        const SizedBox(height: 12),
        Text('${(frac * 100).round()}% through the term',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),

        // Per-subject completion.
        Eyebrow('By subject'),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hairline),
            ),
            child: Center(
              child: Text('No subjects in this semester yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          )
        else
          ...subjects.map((s) {
            final subjectWork = items
                .where((i) => i.subjectId == s.id && i.type != ItemType.note)
                .toList();
            final d = subjectWork.where((i) => i.isCompleted).length;
            final f = subjectWork.isEmpty ? 0.0 : d / subjectWork.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SpineCard(
                spine: AppTheme.spineFor(s.colorValue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(s.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('$d/${subjectWork.length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.merge(AppTheme.tnum)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ProgressBar(
                        value: f, color: AppTheme.spineFor(s.colorValue)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _WeekBlocks extends StatelessWidget {
  final int total;
  final int current; // 1-based
  const _WeekBlocks({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(total, (i) {
        final weekNo = i + 1;
        final past = weekNo < current;
        final isCurrent = weekNo == current;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppTheme.soft(AppTheme.brand, 0.2)
                : (past ? AppTheme.soft(AppTheme.brand, 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isCurrent
                ? Border.all(color: isDark ? AppTheme.brand : AppTheme.goldDeep, width: 1.5)
                : null,
          ),
          child: Text(
            '$weekNo',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isCurrent
                  ? (isDark ? AppTheme.brand : AppTheme.goldDeep)
                  : (past
                      ? (isDark ? AppTheme.brand : AppTheme.goldDeep)
                      : (isDark ? Colors.white38 : AppTheme.inkFaint)),
            ),
          ),
        );
      }),
    );
  }
}

class _NoSemester extends StatelessWidget {
  const _NoSemester();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded,
                size: 36, color: AppTheme.inkFaint),
            Icon(Icons.calendar_month_rounded,
                size: 36,
                color: isDark ? Colors.white38 : AppTheme.inkFaint),
            const SizedBox(height: 14),
            Text('No active semester',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Create a semester to track your term progress and per-subject completion.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => showSemesterSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Semester'),
            ),
          ],
        ),
      ),
    );
  }
}

