import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:semestra_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/schedule/domain/entities/schedule_entity.dart';
import 'package:semestra_app/features/subject/domain/entities/subject_entity.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  static const _brandGreen = Color(0xFF08B86F);
  static const _deepGreen = Color(0xFF087B4C);
  static const _ink = Color(0xFF142033);
  static const _muted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  int _selectedDayOfWeek() => _selectedDate.weekday;

  List<DateTime> _visibleDates() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month);
    final start = first.subtract(Duration(days: first.weekday - 1));
    return List.generate(42, (index) => start.add(Duration(days: index)));
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      final today = DateTime.now();
      final daysInMonth = DateUtils.getDaysInMonth(
        _focusedMonth.year,
        _focusedMonth.month,
      );
      final nextDay =
          _selectedDate.month == today.month && _selectedDate.year == today.year
          ? today.day
          : _selectedDate.day.clamp(1, daysInMonth);
      _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        nextDay,
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF9),
      body: SafeArea(
        bottom: false,
        child: subjectState.when(
          data: (subjects) {
            return scheduleState.when(
              data: (schedules) {
                final selectedSchedules =
                    schedules
                        .where((s) => s.dayOfWeek == _selectedDayOfWeek())
                        .toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime));
                final scheduledWeekdays = schedules
                    .map((s) => s.dayOfWeek)
                    .toSet();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  children: [
                    _CalendarHero(),
                    const SizedBox(height: 0),
                    _MonthCard(
                      focusedMonth: _focusedMonth,
                      selectedDate: _selectedDate,
                      today: todayDate,
                      visibleDates: _visibleDates(),
                      scheduledWeekdays: scheduledWeekdays,
                      onPrevious: () => _moveMonth(-1),
                      onNext: () => _moveMonth(1),
                      onSelect: (date) {
                        setState(() {
                          _selectedDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          _focusedMonth = DateTime(date.year, date.month);
                        });
                      },
                      isSameDay: _isSameDay,
                    ),
                    const SizedBox(height: 16),
                    _SelectedDayCard(
                      selectedDate: _selectedDate,
                      isToday: _isSameDay(_selectedDate, todayDate),
                      schedules: selectedSchedules,
                      subjects: subjects,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading schedule: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading subjects: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddScheduleDialog(context, ref, _selectedDayOfWeek());
        },
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    int dayOfWeek,
  ) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    String selectedSubjectId = subjects.first.id;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 30);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Timetable Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map<DropdownMenuItem<String>>((sub) {
                        return DropdownMenuItem<String>(
                          value: sub.id,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedSubjectId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) setState(() => startTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) setState(() => endTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final startString =
                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endString =
                        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    ref
                        .read(scheduleNotifierProvider.notifier)
                        .addSchedule(
                          subjectId: selectedSubjectId,
                          dayOfWeek: dayOfWeek,
                          startTime: startString,
                          endTime: endString,
                          classroom: '',
                          instructor: '',
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CalendarHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF23A365).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/CalendarBG.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            right: -42,
            bottom: -34,
            width: 260,
            child: Image.asset(
              'assets/images/Calendar.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 24,
            top: 22,
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on track',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF1B8755),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calendar',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF0D3B2C),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Plan today. A better tomorrow.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF3B6756),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final List<DateTime> visibleDates;
  final Set<int> scheduledWeekdays;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime, DateTime) isSameDay;

  const _MonthCard({
    required this.focusedMonth,
    required this.selectedDate,
    required this.today,
    required this.visibleDates,
    required this.scheduledWeekdays,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
    required this.isSameDay,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(focusedMonth),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _SchedulePageState._ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: onPrevious,
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNext,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                _WeekdayLabel('Mon'),
                _WeekdayLabel('Tue'),
                _WeekdayLabel('Wed'),
                _WeekdayLabel('Thu'),
                _WeekdayLabel('Fri'),
                _WeekdayLabel('Sat'),
                _WeekdayLabel('Sun'),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleDates.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 7,
                crossAxisSpacing: 4,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                final date = visibleDates[index];
                final isSelected = isSameDay(date, selectedDate);
                final isToday = isSameDay(date, today);
                final inMonth = date.month == focusedMonth.month;
                final hasSchedule = scheduledWeekdays.contains(date.weekday);

                return _CalendarDay(
                  date: date,
                  inMonth: inMonth,
                  isSelected: isSelected,
                  isToday: isToday,
                  hasSchedule: hasSchedule,
                  onTap: () => onSelect(date),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: _SchedulePageState._ink, size: 22),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;

  const _WeekdayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _SchedulePageState._muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final bool isSelected;
  final bool isToday;
  final bool hasSchedule;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.date,
    required this.inMonth,
    required this.isSelected,
    required this.isToday,
    required this.hasSchedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? Colors.white
        : inMonth
        ? _SchedulePageState._ink
        : _SchedulePageState._muted.withValues(alpha: 0.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? _SchedulePageState._brandGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isToday && !isSelected
              ? Border.all(
                  color: _SchedulePageState._brandGreen.withValues(alpha: 0.55),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasSchedule
                    ? (isSelected
                          ? Colors.white
                          : _SchedulePageState._brandGreen)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final List<ScheduleEntity> schedules;
  final List<SubjectEntity> subjects;

  const _SelectedDayCard({
    required this.selectedDate,
    required this.isToday,
    required this.schedules,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMMM d').format(selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _SchedulePageState._ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FBF0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Today',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _SchedulePageState._deepGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            schedules.isEmpty
                ? 'No events scheduled'
                : '${schedules.length} ${schedules.length == 1 ? 'event' : 'events'} scheduled',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _SchedulePageState._muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (schedules.isEmpty)
            const _EmptyCalendarDay()
          else
            ...schedules.map((schedule) {
              final matches = subjects
                  .where((subject) => subject.id == schedule.subjectId)
                  .toList();
              final subject = matches.isNotEmpty ? matches.first : null;

              return _ScheduleTile(
                schedule: schedule,
                subjectName: subject?.name ?? 'Class',
                subjectCode: subject?.code ?? 'Schedule',
                classroom: subject?.classroom ?? schedule.classroom,
                instructor: subject?.instructor ?? schedule.instructor,
              );
            }),
        ],
      ),
    );
  }
}

class _EmptyCalendarDay extends StatelessWidget {
  const _EmptyCalendarDay();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FCF7),
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/CalendarBG.png'),
          fit: BoxFit.cover,
          opacity: 0.18,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 104,
            child: Image.asset(
              'assets/images/Calendar.png',
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing planned for this day',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _SchedulePageState._ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Take a rest, plan ahead, or add something new.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _SchedulePageState._muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends ConsumerWidget {
  final ScheduleEntity schedule;
  final String subjectName;
  final String subjectCode;
  final String classroom;
  final String instructor;

  const _ScheduleTile({
    required this.schedule,
    required this.subjectName,
    required this.subjectCode,
    required this.classroom,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeString = '${schedule.startTime} - ${schedule.endTime}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeString,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$subjectCode: $subjectName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (classroom.isNotEmpty) ...[
                      const Icon(
                        Icons.room_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(classroom, style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 16),
                    ],
                    if (instructor.isNotEmpty) ...[
                      const Icon(
                        Icons.person_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(instructor, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showEditScheduleDialog(context, ref),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    String selectedSubjectId = schedule.subjectId;
    TimeOfDay startTime;
    TimeOfDay endTime;

    try {
      final startParts = schedule.startTime.split(':');
      startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
    } catch (_) {
      startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    try {
      final endParts = schedule.endTime.split(':');
      endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    } catch (_) {
      endTime = const TimeOfDay(hour: 10, minute: 30);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Timetable Schedule'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map<DropdownMenuItem<String>>((sub) {
                        return DropdownMenuItem<String>(
                          value: sub.id,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedSubjectId = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(startTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (picked != null) setState(() => startTime = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(endTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (picked != null) setState(() => endTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final startString =
                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endString =
                        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    final updatedSchedule = schedule.copyWith(
                      subjectId: selectedSubjectId,
                      startTime: startString,
                      endTime: endString,
                      updatedAt: DateTime.now(),
                    );

                    ref
                        .read(scheduleNotifierProvider.notifier)
                        .editSchedule(updatedSchedule);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Class Schedule?'),
          content: const Text(
            'Are you sure you want to delete this class time slot?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref
                    .read(scheduleNotifierProvider.notifier)
                    .deleteSchedule(schedule.id);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
