import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/schedule/domain/entities/schedule_entity.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    final currentDay = DateTime.now().weekday; // 1 (Mon) to 7 (Sun)
    final initialIndex = (currentDay == 7 ? 0 : currentDay).clamp(0, 6);
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getDayNumForIndex(int index) {
    return index == 0 ? 7 : index;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.colorScheme.primary,
          ),
          Expanded(
            child: subjectState.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Please add at least one Subject in the Subject Registry before building your schedule.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }

                return scheduleState.when(
                  data: (schedules) => TabBarView(
                    controller: _tabController,
                    children: List.generate(7, (index) {
                      final dayNum = _getDayNumForIndex(index);
                      final daySchedules = schedules.where((s) => s.dayOfWeek == dayNum).toList();

                      // Sort schedules chronologically by start time
                      daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

                      return CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (daySchedules.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(48.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No classes scheduled for this day.',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ...daySchedules.map((sch) {
                                  final match = subjects.where((s) => s.id == sch.subjectId).toList();
                                  final subject = match.isNotEmpty ? match.first : subjects.first;
                                  return _ScheduleTile(
                                    schedule: sch,
                                    subjectName: subject.name,
                                    subjectCode: subject.code,
                                    classroom: subject.classroom,
                                    instructor: subject.instructor,
                                  );
                                }).toList(),
                              ]),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error loading schedule: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentDayNum = _getDayNumForIndex(_tabController.index);
          _showAddScheduleDialog(context, ref, currentDayNum);
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context, WidgetRef ref, int dayOfWeek) {
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
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map<DropdownMenuItem<String>>((sub) {
                        return DropdownMenuItem<String>(
                          value: sub.id,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSubjectId = val);
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
                    final startString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endString = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    ref.read(scheduleNotifierProvider.notifier).addSchedule(
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (classroom.isNotEmpty) ...[
                      const Icon(Icons.room_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(classroom, style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 16),
                    ],
                    if (instructor.isNotEmpty) ...[
                      const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
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
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
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
      startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    } catch (_) {
      startTime = const TimeOfDay(hour: 9, minute: 0);
    }

    try {
      final endParts = schedule.endTime.split(':');
      endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
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
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map<DropdownMenuItem<String>>((sub) {
                        return DropdownMenuItem<String>(
                          value: sub.id,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSubjectId = val);
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
                    final startString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                    final endString = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

                    final updatedSchedule = schedule.copyWith(
                      subjectId: selectedSubjectId,
                      startTime: startString,
                      endTime: endString,
                      updatedAt: DateTime.now(),
                    );

                    ref.read(scheduleNotifierProvider.notifier).editSchedule(updatedSchedule);
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
          content: const Text('Are you sure you want to delete this class time slot?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(scheduleNotifierProvider.notifier).deleteSchedule(schedule.id);
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
