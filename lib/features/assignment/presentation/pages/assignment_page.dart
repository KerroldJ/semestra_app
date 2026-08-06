import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/assignment_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/assignment/domain/entities/assignment_entity.dart';
import '../../../../core/theme/app_theme.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: subjectState.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Please add a Subject in the Subject Registry before tracking assignments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return assignmentsState.when(
            data: (assignments) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildAssignmentList(assignments.where((a) => a.status == 0).toList(), subjects, 0),
                  _buildAssignmentList(assignments.where((a) => a.status == 1).toList(), subjects, 1),
                  _buildAssignmentList(assignments.where((a) => a.status == 2).toList(), subjects, 2),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading assignments: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssignmentDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildAssignmentList(List<AssignmentEntity> list, List<dynamic> subjects, int statusTab) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusTab == 2 ? Icons.check_circle_outline_rounded : Icons.assignment_turned_in_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                statusTab == 2
                    ? 'No completed assignments yet. Finish your work to celebrate!'
                    : 'Clear! No active assignments in this section.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final assign = list[index];
        final subject = subjects.firstWhere(
          (s) => s.id == assign.subjectId,
          orElse: () => subjects.first,
        );
        return _AssignmentCard(assignment: assign, subjectName: subject.name, subjectCode: subject.code, subjectColor: Color(subject.colorValue));
      },
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSubjectId = subjects.first.id;
    int selectedPriority = 1; // Medium
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Assignment'),
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
                      decoration: const InputDecoration(labelText: 'Assignment Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Short Description'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(dueDate)),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => dueDate = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority Level'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Low')),
                        DropdownMenuItem(value: 1, child: Text('Medium')),
                        DropdownMenuItem(value: 2, child: Text('High')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedPriority = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Additional Notes'),
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
                      ref.read(assignmentNotifierProvider.notifier).addAssignment(
                            subjectId: selectedSubjectId,
                            title: titleController.text.trim(),
                            description: descController.text.trim(),
                            dueDate: dueDate,
                            priority: selectedPriority,
                            status: 0, // Not started
                            notes: notesController.text.trim(),
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

class _AssignmentCard extends ConsumerWidget {
  final AssignmentEntity assignment;
  final String subjectName;
  final String subjectCode;
  final Color subjectColor;

  const _AssignmentCard({
    required this.assignment,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Priority formatting
    Color priorityColor = Colors.green;
    String priorityText = 'Low';
    if (assignment.priority == 1) {
      priorityColor = Colors.orange;
      priorityText = 'Medium';
    } else if (assignment.priority == 2) {
      priorityColor = Colors.red;
      priorityText = 'High';
    }

    // Days remaining
    final daysRemaining = assignment.dueDate.difference(DateTime.now()).inDays;
    String dueText = 'Due in $daysRemaining days';
    if (daysRemaining == 0) {
      dueText = 'Due today!';
    } else if (daysRemaining < 0) {
      dueText = 'Overdue by ${-daysRemaining} days';
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
                    color: subjectColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$subjectCode: $subjectName',
                    style: TextStyle(
                      color: subjectColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priorityText,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              assignment.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (assignment.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                assignment.description,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dueText,
                  style: TextStyle(
                    color: daysRemaining < 0 ? Colors.red : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    fontSize: 13,
                    fontWeight: daysRemaining < 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (assignment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assignment.notes,
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Quick transition buttons
                Row(
                  children: [
                    if (assignment.status != 0)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(assignmentNotifierProvider.notifier)
                            .updateAssignmentStatus(assignment, 0),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('To Do'),
                      ),
                    if (assignment.status != 1) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(assignmentNotifierProvider.notifier)
                            .updateAssignmentStatus(assignment, 1),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('In Progress'),
                      ),
                    ],
                    if (assignment.status != 2) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(assignmentNotifierProvider.notifier)
                            .updateAssignmentStatus(assignment, 2),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Complete'),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () {
                    ref.read(assignmentNotifierProvider.notifier).deleteAssignment(assignment.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
