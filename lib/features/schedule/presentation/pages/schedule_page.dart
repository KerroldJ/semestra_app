import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/schedule/domain/entities/schedule_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    // Monday is 1, Sunday is 7. We match index (0-6) to dayOfWeek (1-7).
    final currentDay = DateTime.now().weekday; // 1 to 7
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: (currentDay - 1).clamp(0, 6),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Schedule'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((day) => Tab(text: day.substring(0, 3))).toList(),
        ),
      ),
      body: subjectState.when(
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
                final dayNum = index + 1; // Day of week (1 to 7)
                final daySchedules = schedules.where((s) => s.dayOfWeek == dayNum).toList();

                // Sort schedules chronologically by start time
                daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _days[index],
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddScheduleDialog(context, ref, dayNum),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add Class'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (daySchedules.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Column(
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
                            // Find matching subject
                            final subject = subjects.firstWhere(
                              (s) => s.id == sch.subjectId,
                              orElse: () => subjects.first,
                            );
                            return _ScheduleTile(schedule: sch, subjectName: subject.name, subjectCode: subject.code, subjectColor: Color(subject.colorValue));
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
    );
  }

  void _showAddScheduleDialog(BuildContext context, WidgetRef ref, int dayOfWeek) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    String selectedSubjectId = subjects.first.id;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 30);
    final classroomController = TextEditingController();
    final instructorController = TextEditingController();

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
                      items: subjects.map((sub) {
                        return DropdownMenuItem(
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
                    const SizedBox(height: 8),
                    TextField(
                      controller: classroomController,
                      decoration: const InputDecoration(labelText: 'Classroom / Lab'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(labelText: 'Instructor'),
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
                          classroom: classroomController.text.trim(),
                          instructor: instructorController.text.trim(),
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
  final Color subjectColor;

  const _ScheduleTile({
    required this.schedule,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeString = '${schedule.startTime} - ${schedule.endTime}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: subjectColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                                if (schedule.classroom.isNotEmpty) ...[
                                  const Icon(Icons.room_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(schedule.classroom, style: theme.textTheme.bodyMedium),
                                  const SizedBox(width: 16),
                                ],
                                if (schedule.instructor.isNotEmpty) ...[
                                  const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(schedule.instructor, style: theme.textTheme.bodyMedium),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(scheduleNotifierProvider.notifier).deleteSchedule(schedule.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
