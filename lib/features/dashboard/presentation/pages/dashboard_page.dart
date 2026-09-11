import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final settings = ref.watch(settingsNotifierProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];

    final subjectsById = {for (final s in subjects) s.id: s};
    final today = now.weekday;

    final todayClasses = schedules
        .where((s) => s.dayOfWeek == today && s.scheduleType != ScheduleType.study)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Next upcoming class today.
    ScheduleEntity? nextUp;
    int nextUpMinutes = 0;
    for (final s in todayClasses) {
      final t = Fmt.parseHHmm(s.startTime);
      if (t == null) continue;
      final start = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      final diff = start.difference(now).inMinutes;
      if (diff >= 0) {
        nextUp = s;
        nextUpMinutes = diff;
        break;
      }
    }

    final open = items.where((i) =>
        i.type != ItemType.note && !i.isCompleted && i.dueDate != null);
    final startOfToday = DateTime(now.year, now.month, now.day);
    final dueThisWeek = open.where((i) {
      final d = i.dueDate!;
      final diff = DateTime(d.year, d.month, d.day).difference(startOfToday).inDays;
      return diff >= 0 && diff <= 7;
    }).length;
    final overdue = open.where((i) {
      final d = i.dueDate!;
      return DateTime(d.year, d.month, d.day).isBefore(startOfToday);
    }).length;

    final deadlines = open.toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            AppScreenHeader(
              eyebrow: DateFormat('EEEE, MMM d').format(now),
              title: 'Dashboard',
              onSearch: () {},
            ),
            const SizedBox(height: 20),
            _Greeting(name: settings.userName),
            const SizedBox(height: 18),
            _NextUpCard(
              schedule: nextUp,
              subject: nextUp == null ? null : subjectsById[nextUp.subjectId],
              minutes: nextUpMinutes,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${todayClasses.length}',
                    label: 'classes today',
                    color: AppTheme.statPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    value: '$dueThisWeek',
                    label: 'due this week',
                    color: AppTheme.statOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    value: '$overdue',
                    label: 'overdue',
                    color: AppTheme.statRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SectionHeader(
              title: "Today's classes",
              actionLabel: 'View all',
              onAction: () => context.go('/planner'),
            ),
            const SizedBox(height: 12),
            if (todayClasses.isEmpty)
              const _EmptyHint(text: 'No classes scheduled today.')
            else
              ...todayClasses.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClassRow(
                        schedule: s, subject: subjectsById[s.subjectId]),
                  )),
            const SizedBox(height: 22),
            SectionHeader(
              title: 'Upcoming deadlines',
              actionLabel: 'View all',
              onAction: () => context.go('/planner'),
            ),
            const SizedBox(height: 12),
            if (deadlines.isEmpty)
              const _EmptyHint(text: 'Nothing due — you are all caught up.')
            else
              ...deadlines.take(3).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DeadlineRow(
                        item: i, subject: subjectsById[i.subjectId]),
                  )),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good morning,'
        : hour < 18
            ? 'Good afternoon,'
            : 'Good evening,';
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D5CE0), Color(0xFF5B57E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            AppTheme.initials(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greet, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ],
    );
  }
}

class _NextUpCard extends StatelessWidget {
  final ScheduleEntity? schedule;
  final SubjectEntity? subject;
  final int minutes;

  const _NextUpCard({
    required this.schedule,
    required this.subject,
    required this.minutes,
  });

  String get _eyebrow {
    if (schedule == null) return 'NOTHING NEXT';
    if (minutes <= 0) return 'NEXT UP · NOW';
    if (minutes < 60) return 'NEXT UP · IN $minutes MIN';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return 'NEXT UP · IN ${h}H${m > 0 ? ' ${m}M' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _eyebrow,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            schedule == null
                ? 'No more classes today'
                : (subject?.name ?? 'Class'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            schedule == null
                ? 'Enjoy the rest of your day.'
                : [
                    if (schedule!.classroom.isNotEmpty) schedule!.classroom,
                    if (schedule!.instructor.isNotEmpty) schedule!.instructor,
                  ].join(' · '),
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  final ScheduleEntity schedule;
  final SubjectEntity? subject;
  const _ClassRow({required this.schedule, required this.subject});

  @override
  Widget build(BuildContext context) {
    final color = subject != null ? Color(subject!.colorValue) : AppTheme.primary;
    final (time, period) = Fmt.time12Parts(schedule.startTime);
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: Theme.of(context).textTheme.titleMedium),
                Text(period, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject?.name ?? 'Class',
                    style: Theme.of(context).textTheme.titleMedium),
                if (schedule.classroom.isNotEmpty)
                  Text(schedule.classroom,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final ItemEntity item;
  final SubjectEntity? subject;
  const _DeadlineRow({required this.item, required this.subject});

  @override
  Widget build(BuildContext context) {
    final color = subject != null ? Color(subject!.colorValue) : AppTheme.statRed;
    final now = DateTime.now();
    final overdue = item.dueDate != null &&
        DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day)
            .isBefore(DateTime(now.year, now.month, now.day));
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.soft(color, 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.type == ItemType.assignment
                  ? Icons.assignment_outlined
                  : Icons.check_box_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                if (subject != null)
                  Text(subject!.name,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (item.dueDate != null)
            Pill(
              text: Fmt.dueLabel(item.dueDate!),
              bg: AppTheme.soft(
                  overdue
                      ? AppTheme.statRed
                      : (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : AppTheme.inkMuted),
                  0.12),
              fg: overdue
                  ? AppTheme.statRed
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : AppTheme.inkMuted),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : AppTheme.inkFaint,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
