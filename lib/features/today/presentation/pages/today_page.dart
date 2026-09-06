import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../item/presentation/item_selectors.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';

/// Screen 06 — Today. Week banner, Now/Later classes, Due next, semester
/// progress. Header links to the Semester overview.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final profile = ref.watch(authNotifierProvider).profile;
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    // Today's non-study classes, sorted by start.
    final todays = schedules
        .where((s) =>
            s.dayOfWeek == now.weekday &&
            s.scheduleType != ScheduleType.study)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nowMinutes = now.hour * 60 + now.minute;
    ScheduleEntity? live;
    final later = <ScheduleEntity>[];
    for (final s in todays) {
      final st = Fmt.parseHHmm(s.startTime);
      final en = Fmt.parseHHmm(s.endTime);
      final startM = st == null ? 0 : st.hour * 60 + st.minute;
      final endM = en == null ? 0 : en.hour * 60 + en.minute;
      if (nowMinutes >= startM && nowMinutes < endM) {
        live = s;
      } else if (startM >= nowMinutes) {
        later.add(s);
      }
    }

    final groups = UrgencyGroups.from(items, now);
    final dueNext = [...groups.overdue, ...groups.thisWeek, ...groups.later];

    // Semester progress (week x of n).
    final active = semesters.isEmpty
        ? null
        : semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
            // Header: week-of banner + Semester link.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Week of ${DateFormat('MMM d').format(_weekStart(now))}'),
                      const SizedBox(height: 4),
                      Text(
                        _greeting(now, profile?.username ?? profile?.displayName),
                        style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                    ],
                  ),
                ),
                _CircleAction(
                  icon: Icons.calendar_month_rounded,
                  onTap: () => context.push('/semester'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Now.
            Eyebrow('Now'),
            const SizedBox(height: 10),
            if (live != null)
              _ClassCard(
                schedule: live,
                subject: subjectsById[live.subjectId],
                highlighted: true,
              )
            else
              _QuietCard(
                icon: Icons.free_breakfast_outlined,
                text: todays.isEmpty
                    ? 'No classes today. A good day to get ahead.'
                    : 'No class right now.',
              ),
            const SizedBox(height: 22),

            // Later today.
            Eyebrow('Later today'),
            const SizedBox(height: 10),
            if (later.isEmpty)
              _QuietCard(
                  icon: Icons.check_circle_outline_rounded,
                  text: 'Nothing else scheduled today.')
            else
              ...later.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClassCard(
                        schedule: s, subject: subjectsById[s.subjectId]),
                  )),
            const SizedBox(height: 22),

            // Due next.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Eyebrow('Due next'),
                if (dueNext.isNotEmpty)
                  GestureDetector(
                    onTap: () => context.push('/assignments'),
                    child: Text('All assignments',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          color: AppTheme.goldDeep,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        )),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (dueNext.isEmpty)
              _QuietCard(
                  icon: Icons.done_all_rounded,
                  text: 'You’re all caught up. Nothing due.')
            else
              ...dueNext.take(3).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DueCard(
                        item: i, subject: subjectsById[i.subjectId], now: now),
                  )),
            const SizedBox(height: 22),

            // Semester progress.
            if (active != null) ...[
              Eyebrow('Semester'),
              const SizedBox(height: 10),
              _SemesterProgressCard(
                name: active.name,
                start: active.startDate,
                end: active.endDate,
                now: now,
                onTap: () => context.push('/semester'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static DateTime _weekStart(DateTime now) {
    final delta = now.weekday - 1; // Monday-based
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: delta));
  }

  static String _greeting(DateTime now, String? name) {
    final n = (name == null || name.isEmpty) ? '' : ', $name';
    final h = now.hour;
    if (h < 12) return 'Good morning$n';
    if (h < 18) return 'Good afternoon$n';
    return 'Good evening$n';
  }
}

class _ClassCard extends StatelessWidget {
  final ScheduleEntity schedule;
  final SubjectEntity? subject;
  final bool highlighted;
  const _ClassCard({
    required this.schedule,
    required this.subject,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : AppTheme.inkFaint;
    return SpineCard(
      spine: spine,
      highlighted: highlighted,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.time12(schedule.startTime),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.merge(AppTheme.tnum)),
              Text(schedule.scheduleType.label,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject?.name ?? 'Class',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (schedule.classroom.isNotEmpty)
                  Text(schedule.classroom,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (highlighted) const StrokeLabel(text: 'Now', color: AppTheme.gold),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  final ItemEntity item;
  final SubjectEntity? subject;
  final DateTime now;
  const _DueCard({required this.item, required this.subject, required this.now});

  @override
  Widget build(BuildContext context) {
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : AppTheme.inkFaint;
    final overdue = item.urgencyFrom(now) == Urgency.overdue;
    return SpineCard(
      spine: spine,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  subject?.name ??
                      (item.type == ItemType.assignment
                          ? 'Assignment'
                          : 'Task'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            Fmt.dueLabel(item.dueDate!),
            style: Theme.of(context).textTheme.bodyMedium?.merge(AppTheme.tnum).copyWith(
                  color: overdue ? AppTheme.danger : AppTheme.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _SemesterProgressCard extends StatelessWidget {
  final String name;
  final DateTime start;
  final DateTime end;
  final DateTime now;
  final VoidCallback onTap;
  const _SemesterProgressCard({
    required this.name,
    required this.start,
    required this.end,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = end.difference(start).inDays;
    final elapsed = now.difference(start).inDays.clamp(0, total <= 0 ? 0 : total);
    final frac = total <= 0 ? 0.0 : elapsed / total;
    final totalWeeks = (total / 7).ceil().clamp(1, 30);
    final currentWeek = (elapsed / 7).floor().clamp(0, totalWeeks) + 1;

    return SpineCard(
      spine: AppTheme.gold,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('Week $currentWeek of $totalWeeks',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.merge(AppTheme.tnum)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(value: frac.toDouble(), color: AppTheme.gold),
          const SizedBox(height: 8),
          Text('${(frac * 100).round()}% through the term',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _QuietCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.inkFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Icon(icon, size: 21, color: AppTheme.ink),
      ),
    );
  }
}
