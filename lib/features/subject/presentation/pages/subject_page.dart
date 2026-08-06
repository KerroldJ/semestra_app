import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/semester/presentation/providers/semester_provider.dart';
import 'package:semestra_app/features/subject/domain/entities/subject_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class SubjectPage extends ConsumerWidget {
  const SubjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsState = ref.watch(subjectNotifierProvider);
    final semestersState = ref.watch(semesterNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: semestersState.when(
        data: (semesters) {
          if (semesters.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Please create a Semester in Semester Management before logging subjects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Find active semester or default to first
          final activeSem = semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);

          return subjectsState.when(
            data: (subjects) {
              final semesterSubjects = subjects.where((s) => s.semesterId == activeSem.id).toList();

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Responsive header card containing semester info and add subject button
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 450;
                                
                                final detailsWidget = Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Academic Semester',
                                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            activeSem.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                final actionButton = ElevatedButton.icon(
                                  onPressed: () => _showAddSubjectDialog(context, ref, activeSem.id),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Subject'),
                                  style: isMobile
                                      ? ElevatedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(48),
                                        )
                                      : null,
                                );

                                return isMobile
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          detailsWidget,
                                          const SizedBox(height: 16),
                                          actionButton,
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: detailsWidget),
                                          const SizedBox(width: 16),
                                          actionButton,
                                        ],
                                      );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (semesterSubjects.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                'No subjects added to this semester yet.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 200,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: semesterSubjects.length,
                          itemBuilder: (context, index) {
                            return _SubjectCard(subject: semesterSubjects[index]);
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading semesters: $err')),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, String semesterId) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final instructorController = TextEditingController();
    final classroomController = TextEditingController();
    double units = 3.0;
    Color selectedColor = AppTheme.subjectColors.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Subject Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code (e.g. CS101)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name (e.g. Intro to CS)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(labelText: 'Instructor Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: classroomController,
                      decoration: const InputDecoration(labelText: 'Classroom / Location'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Units / Credits:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: () {
                                if (units > 0.5) setState(() => units -= 0.5);
                              },
                            ),
                            Text('$units', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              onPressed: () => setState(() => units += 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color Theme:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppTheme.subjectColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [const BoxShadow(color: Colors.black38, blurRadius: 4, spreadRadius: 1)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
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
                    if (codeController.text.trim().isNotEmpty && nameController.text.trim().isNotEmpty) {
                      ref.read(subjectNotifierProvider.notifier).addSubject(
                            semesterId: semesterId,
                            code: codeController.text.trim().toUpperCase(),
                            name: nameController.text.trim(),
                            instructor: instructorController.text.trim(),
                            classroom: classroomController.text.trim(),
                            units: units,
                            colorValue: selectedColor.value,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  final SubjectEntity subject;

  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectColor = Color(subject.colorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subject.code,
                        style: TextStyle(
                          color: subjectColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${subject.units} Units',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subject.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Prof. ${subject.instructor.isNotEmpty ? subject.instructor : "N/A"}',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Room: ${subject.classroom.isNotEmpty ? subject.classroom : "N/A"}',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditSubjectDialog(context, ref),
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
          ],
        ),
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController(text: subject.code);
    final nameController = TextEditingController(text: subject.name);
    final instructorController = TextEditingController(text: subject.instructor);
    final classroomController = TextEditingController(text: subject.classroom);
    double units = subject.units;
    Color selectedColor = Color(subject.colorValue);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Subject Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Subject Code (e.g. CS101)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Subject Name (e.g. Intro to CS)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: instructorController,
                      decoration: const InputDecoration(labelText: 'Instructor Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: classroomController,
                      decoration: const InputDecoration(labelText: 'Classroom / Location'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Units / Credits:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded),
                              onPressed: () {
                                if (units > 0.5) setState(() => units -= 0.5);
                              },
                            ),
                            Text('$units', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              onPressed: () => setState(() => units += 0.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Color Theme:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppTheme.subjectColors.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [const BoxShadow(color: Colors.black38, blurRadius: 4, spreadRadius: 1)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
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
                    if (codeController.text.trim().isNotEmpty && nameController.text.trim().isNotEmpty) {
                      final updatedSubject = subject.copyWith(
                        code: codeController.text.trim().toUpperCase(),
                        name: nameController.text.trim(),
                        instructor: instructorController.text.trim(),
                        classroom: classroomController.text.trim(),
                        units: units,
                        colorValue: selectedColor.value,
                      );
                      ref.read(subjectNotifierProvider.notifier).editSubject(updatedSubject);
                      Navigator.pop(context);
                    }
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
          title: const Text('Delete Subject?'),
          content: Text('Are you sure you want to delete "${subject.code} - ${subject.name}"? All related schedules, assignments, and grades will also be hidden.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(subjectNotifierProvider.notifier).deleteSubject(subject.id);
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
