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
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  DateTime _selected = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selected = now;
      _focusedMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final allItems = ref.watch(itemNotifierProvider).value ?? [];
    final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    // Scope the calendar to the active semester only: its subjects, and the
    // schedules / tasks / assignments that belong to those subjects.
    final activeSemesterIds = {
      for (final sem in semesters)
        if (sem.isActive && !sem.isArchived) sem.id,
    };
    final activeSubjectIds = {
      for (final s in subjects)
        if (activeSemesterIds.contains(s.semesterId)) s.id,
    };
    final schedules = allSchedules
        .where((s) => activeSubjectIds.contains(s.subjectId))
        .toList();
    final items = allItems
        .where((i) => i.subjectId != null &&
            activeSubjectIds.contains(i.subjectId))
        .toList();

    final now = DateTime.now();
    final isViewingCurrentMonth =
        _focusedMonth.year == now.year && _focusedMonth.month == now.month;
    final isSelectedToday = _selected.year == now.year &&
        _selected.month == now.month &&
        _selected.day == now.day;

    final events = _eventsForDay(_selected, schedules, items, subjectsById);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            AppScreenHeader(
              eyebrow: DateFormat('MMMM yyyy').format(_focusedMonth),
              title: 'Calendar',
            ),
            const SizedBox(height: 16),
            _CalendarCard(
              focusedMonth: _focusedMonth,
              selected: _selected,
              weekStartsOn: settings.weekStartsOn,
              schedules: schedules,
              items: items,
              onPreviousMonth: _previousMonth,
              onNextMonth: _nextMonth,
              onSelectDate: (d) {
                setState(() {
                  _selected = d;
                  if (d.month != _focusedMonth.month ||
                      d.year != _focusedMonth.year) {
                    _focusedMonth = DateTime(d.year, d.month, 1);
                  }
                });
              },
              onTodayTap: (!isViewingCurrentMonth || !isSelectedToday)
                  ? _goToToday
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(_selected),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        events.isEmpty
                            ? 'No events scheduled'
                            : '${events.length} ${events.length == 1 ? 'event' : 'events'} planned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : AppTheme.inkMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelectedToday)
                  Pill(
                    text: 'Today',
                    bg: AppTheme.soft(AppTheme.brandFill(context), 0.14),
                    fg: AppTheme.accent(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              const _EmptyDay()
            else
              ...events.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TimelineRow(event: e),
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
      final instructor =
          s.instructor.isNotEmpty ? s.instructor : (subject?.instructor ?? '');
      final timeRange =
          '${Fmt.time12(s.startTime)} – ${Fmt.time12(s.endTime)}';
      final subParts = <String>[];
      if (instructor.isNotEmpty) subParts.add(instructor);
      if (s.classroom.isNotEmpty) subParts.add(s.classroom);
      subParts.add(timeRange);

      events.add(_PlannerEvent(
        minutes: mins,
        timeLabel: Fmt.time12(s.startTime),
        category: s.scheduleType.label,
        color: isStudy ? AppTheme.statGreen : color,
        title: subject?.name ?? 'Class',
        subtitle: isStudy
            ? '${subject?.name ?? ''} · ${Fmt.durationMinutes(s.startTime, s.endTime)}m planned'
            : subParts.join(' · '),
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

class _CalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selected;
  final int weekStartsOn;
  final List<ScheduleEntity> schedules;
  final List<ItemEntity> items;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback? onTodayTap;

  const _CalendarCard({
    required this.focusedMonth,
    required this.selected,
    required this.weekStartsOn,
    required this.schedules,
    required this.items,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Weekday abbreviations based on weekStartsOn (1=Mon ... 7=Sun)
    final allWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayLabels = <String>[];
    for (int i = 0; i < 7; i++) {
      final idx = (weekStartsOn - 1 + i) % 7;
      weekdayLabels.add(allWeekdays[idx]);
    }

    // Grid days generation
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadCount = (firstDayOfMonth.weekday - weekStartsOn + 7) % 7;

    final daysInPrevMonth = DateTime(year, month, 0).day;
    final gridDays = <_CalendarDayData>[];

    // Leading days from previous month
    for (int i = leadCount - 1; i >= 0; i--) {
      final day = daysInPrevMonth - i;
      final date = DateTime(year, month - 1, day);
      gridDays.add(_buildDayData(date, isCurrentMonth: false, now: now));
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      gridDays.add(_buildDayData(date, isCurrentMonth: true, now: now));
    }

    // Trailing days to fill 7 columns evenly
    final totalCells = ((gridDays.length + 6) ~/ 7) * 7;
    final trailingCount = totalCells - gridDays.length;
    for (int day = 1; day <= trailingCount; day++) {
      final date = DateTime(year, month + 1, day);
      gridDays.add(_buildDayData(date, isCurrentMonth: false, now: now));
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            onNextMonth();
          } else if (details.primaryVelocity! > 200) {
            onPreviousMonth();
          }
        }
      },
      child: SoftCard(
        padding: const EdgeInsets.all(18),
        radius: 24,
        child: Column(
          children: [
            // Calendar Month Navigation Header
            Row(
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(focusedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                ),
                const Spacer(),
                if (onTodayTap != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onTodayTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.soft(AppTheme.brandFill(context), 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            color: AppTheme.accent(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                _MonthNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPreviousMonth,
                ),
                const SizedBox(width: 4),
                _MonthNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNextMonth,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Weekday Header
            Row(
              children: weekdayLabels.map((lbl) {
                return Expanded(
                  child: Center(
                    child: Text(
                      lbl.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.60)
                            : AppTheme.inkMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridDays.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 6,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, index) {
                final dayData = gridDays[index];
                final isSel = dayData.date.year == selected.year &&
                    dayData.date.month == selected.month &&
                    dayData.date.day == selected.day;

                return _CalendarDayCell(
                  data: dayData,
                  isSelected: isSel,
                  onTap: () => onSelectDate(dayData.date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _CalendarDayData _buildDayData(
    DateTime date, {
    required bool isCurrentMonth,
    required DateTime now,
  }) {
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final hasClass = schedules.any((s) => s.dayOfWeek == date.weekday);
    final hasDeadline = items.any((i) =>
        i.type != ItemType.note &&
        i.dueDate != null &&
        !i.isCompleted &&
        i.dueDate!.year == date.year &&
        i.dueDate!.month == date.month &&
        i.dueDate!.day == date.day);

    return _CalendarDayData(
      date: date,
      isCurrentMonth: isCurrentMonth,
      isToday: isToday,
      hasClass: hasClass,
      hasDeadline: hasDeadline,
    );
  }
}

class _CalendarDayData {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool hasClass;
  final bool hasDeadline;

  const _CalendarDayData({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.hasClass,
    required this.hasDeadline,
  });
}

class _CalendarDayCell extends StatelessWidget {
  final _CalendarDayData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (!data.isCurrentMonth) {
      textColor = isDark ? Colors.white24 : const Color(0x3D0B0F0D);
    } else if (data.isToday) {
      textColor = AppTheme.accent(context);
    } else {
      textColor = isDark ? AppTheme.darkInk : AppTheme.ink;
    }

    BoxDecoration? decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: AppTheme.brandFill(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandFill(context).withValues(alpha: 0.38),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    } else if (data.isToday) {
      decoration = BoxDecoration(
        color: AppTheme.soft(AppTheme.brandFill(context), 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.brandFill(context), width: 1.5),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: decoration,
            alignment: Alignment.center,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${data.date.day}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected || data.isToday
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              _EventIndicatorDots(
                hasClass: data.hasClass,
                hasDeadline: data.hasDeadline,
                isSelected: isSelected,
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventIndicatorDots extends StatelessWidget {
  final bool hasClass;
  final bool hasDeadline;
  final bool isSelected;

  const _EventIndicatorDots({
    required this.hasClass,
    required this.hasDeadline,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasClass && !hasDeadline) {
      return const SizedBox(height: 4);
    }

    return SizedBox(
      height: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasClass)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : AppTheme.brandFill(context),
              ),
            ),
          if (hasClass && hasDeadline) const SizedBox(width: 3),
          if (hasDeadline)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white70 : AppTheme.statRed,
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 22,
            color: isDark ? AppTheme.darkInk : AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _PlannerEvent event;
  const _TimelineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: event.tint != null
            ? AppTheme.soft(event.tint!, 0.08)
            : (isDark ? Theme.of(context).cardColor : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: event.color, width: 4),
        ),
        boxShadow: event.tint != null || isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
          Icon(Icons.event_available_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38
                  : AppTheme.inkFaint,
              size: 28),
          const SizedBox(height: 10),
          Text('Nothing planned for this day',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

