import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:semestra_app/features/exam/presentation/providers/exam_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/exam/domain/entities/exam_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class ExamPage extends ConsumerWidget {
  const ExamPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsState = ref.watch(examNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam & Assessment Manager'),
      ),
      body: subjectState.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Please create a Subject in the Subject Registry before recording exams.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return examsState.when(
            data: (exams) {
              if (exams.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'All clear! No upcoming exams or presentations logged.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort exams by schedule date (upcoming first)
              final sortedExams = List<ExamEntity>.from(exams);
              sortedExams.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: sortedExams.length,
                itemBuilder: (context, index) {
                  final exam = sortedExams[index];
                  final sub = subjects.firstWhere(
                    (s) => s.id == exam.subjectId,
                    orElse: () => subjects.first,
                  );
                  return _ExamCard(
                    exam: exam,
                    subjectName: sub.name,
                    subjectCode: sub.code,
                    subjectColor: Color(sub.colorValue),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading exams: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExamDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddExamDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    final titleController = TextEditingController();
    final coverageController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSubjectId = subjects.first.id;
    int selectedType = 1; // Exam
    DateTime examDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay examTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Assessment'),
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
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Assessment Title (e.g. Midterm)'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Assessment Type'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Quiz / Test')),
                        DropdownMenuItem(value: 1, child: Text('Major Examination')),
                        DropdownMenuItem(value: 2, child: Text('Presentation')),
                        DropdownMenuItem(value: 3, child: Text('Project / Practical')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(examDate)),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: examDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => examDate = picked);
                      },
                    ),
                    ListTile(
                      title: const Text('Time'),
                      subtitle: Text(examTime.format(context)),
                      trailing: const Icon(Icons.access_time_rounded),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: examTime,
                        );
                        if (picked != null) setState(() => examTime = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: coverageController,
                      decoration: const InputDecoration(labelText: 'Topics Covered'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Preparation Notes'),
                      maxLines: 2,
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
                    if (titleController.text.trim().isNotEmpty) {
                      final scheduledDateTime = DateTime(
                        examDate.year,
                        examDate.month,
                        examDate.day,
                        examTime.hour,
                        examTime.minute,
                      );

                      ref.read(examNotifierProvider.notifier).addExam(
                            subjectId: selectedSubjectId,
                            title: titleController.text.trim(),
                            scheduledDate: scheduledDateTime,
                            coverage: coverageController.text.trim(),
                            notes: notesController.text.trim(),
                            type: selectedType,
                          );
                      Navigator.pop(context);
                    }
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

class _ExamCard extends StatefulWidget {
  final ExamEntity exam;
  final String subjectName;
  final String subjectCode;
  final Color subjectColor;

  const _ExamCard({
    required this.exam,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  State<_ExamCard> createState() => _ExamCardState();
}

class _ExamCardState extends State<_ExamCard> {
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeLeft();
      }
    });
  }

  void _updateTimeLeft() {
    final diff = widget.exam.scheduledDate.difference(DateTime.now());
    setState(() {
      _timeLeft = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String typeText = 'Exam';
    if (widget.exam.type == 0) {
      typeText = 'Quiz';
    } else if (widget.exam.type == 2) {
      typeText = 'Presentation';
    } else if (widget.exam.type == 3) {
      typeText = 'Project';
    }

    // Format Countdown String
    String countdownStr = 'Ended';
    if (!_timeLeft.isNegative && _timeLeft.inSeconds > 0) {
      final days = _timeLeft.inDays;
      final hours = _timeLeft.inHours % 24;
      final minutes = _timeLeft.inMinutes % 60;
      final seconds = _timeLeft.inSeconds % 60;
      
      if (days > 0) {
        countdownStr = '$days d $hours h remaining';
      } else {
        countdownStr = '$hours h $minutes m $seconds s remaining';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.subjectCode} - $typeText',
                    style: TextStyle(
                      color: widget.subjectColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  countdownStr,
                  style: TextStyle(
                    color: _timeLeft.inDays == 0 && _timeLeft.inSeconds > 0 ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.exam.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${DateFormat('EEE, MMM d, yyyy @ hh:mm a').format(widget.exam.scheduledDate)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (widget.exam.coverage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Topics: ${widget.exam.coverage}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
            if (widget.exam.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.exam.notes,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Consumer(
                builder: (context, ref, child) {
                  return IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () {
                      ref.read(examNotifierProvider.notifier).deleteExam(widget.exam.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
