import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/item_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    final now = DateTime.now();
    final startDay = settings.weekStartsOn; // 1..7
    final delta = (now.weekday - startDay) % 7;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: delta < 0 ? delta + 7 : delta));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final events = _eventsForDay(_selected, schedules, items, subjectsById);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  const AppScreenHeader(eyebrow: 'This week', title: 'Planner'),
                  const SizedBox(height: 18),
                  _WeekStrip(
                    days: weekDays,
                    selected: _selected,
                    onSelect: (d) => setState(() => _selected = d),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selected),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 16),
                  if (events.isEmpty)
                    const _EmptyDay()
                  else
                    ...events.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TimelineRow(event: e),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_PlannerEvent> _eventsForDay(
    DateTime day,
    List<ScheduleEntity> schedules,
    List<ItemEntity> items,
    Map<String, SubjectEntity> subjectsById,
  ) {
    final events = <_PlannerEvent>[];
    final weekday = day.weekday;

    for (final s in schedules.where((s) => s.dayOfWeek == weekday)) {
      final subject = subjectsById[s.subjectId];
      final color = subject != null ? Color(subject.colorValue) : AppTheme.primary;
      final t = Fmt.parseHHmm(s.startTime);
      final mins = t == null ? 0 : t.hour * 60 + t.minute;
      final isStudy = s.scheduleType == ScheduleType.study;
      events.add(_PlannerEvent(
        minutes: mins,
        timeLabel: Fmt.time12(s.startTime),
        category: s.scheduleType.label,
        color: isStudy ? AppTheme.statGreen : color,
        title: subject?.name ?? 'Class',
        subtitle: isStudy
            ? '${subject?.name ?? ''} · ${Fmt.durationMinutes(s.startTime, s.endTime)}m planned'
            : s.classroom,
        tint: isStudy ? AppTheme.statGreen : null,
      ));
    }

    for (final i in items.where((i) =>
        i.type != ItemType.note && i.dueDate != null && !i.isCompleted)) {
      final d = i.dueDate!;
      if (d.year != day.year || d.month != day.month || d.day != day.day) {
        continue;
      }
      final hasTime = d.hour != 0 || d.minute != 0;
      final subject = subjectsById[i.subjectId];
      events.add(_PlannerEvent(
        minutes: hasTime ? d.hour * 60 + d.minute : 17 * 60,
        timeLabel: hasTime ? Fmt.time12('${d.hour}:${d.minute}') : '',
        category: 'DEADLINE',
        color: AppTheme.statRed,
        title: i.title,
        subtitle: subject?.name ?? '',
        tint: AppTheme.statRed,
      ));
    }

    events.sort((a, b) => a.minutes.compareTo(b.minutes));
    return events;
  }
}

class _PlannerEvent {
  final int minutes;
  final String timeLabel;
  final String category;
  final Color color;
  final String title;
  final String subtitle;
  final Color? tint; // background tint (deadline/study)

  _PlannerEvent({
    required this.minutes,
    required this.timeLabel,
    required this.category,
    required this.color,
    required this.title,
    required this.subtitle,
    this.tint,
  });
}

class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _WeekStrip({
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: days.map((d) {
        final isSel = d.year == selected.year &&
            d.month == selected.month &&
            d.day == selected.day;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(d),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSel
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(d).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white70 : AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSel ? Colors.white : AppTheme.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _PlannerEvent event;
  const _TimelineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              event.timeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: event.tint != null
                  ? AppTheme.soft(event.tint!, 0.08)
                  : (isDark ? AppTheme.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: event.color, width: 4),
              ),
              boxShadow: event.tint != null || isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.category,
                  style: TextStyle(
                    color: event.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(event.title,
                    style: Theme.of(context).textTheme.titleMedium),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(event.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded,
              color: AppTheme.inkFaint, size: 28),
          const SizedBox(height: 10),
          Text('Nothing planned for this day',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
