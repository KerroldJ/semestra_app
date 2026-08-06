import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/daily_task_provider.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../../../core/theme/app_theme.dart';

class DailyPlannerPage extends ConsumerWidget {
  const DailyPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(dailyTaskNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: taskState.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text(
                'No planner tasks yet. Tap + to add one.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Sort: active tasks first, completed tasks last. Within groups, sort by updatedAt descending.
          final sortedTasks = List<DailyTaskEntity>.from(tasks);
          sortedTasks.sort((a, b) {
            if (a.isCompleted != b.isCompleted) {
              return a.isCompleted ? 1 : -1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              return _TaskTile(task: sortedTasks[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading tasks: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/planner/create'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }


}

class _TaskTile extends ConsumerWidget {
  final DailyTaskEntity task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Priority formatting
    Color priorityColor = Colors.green;
    if (task.priority == 1) priorityColor = Colors.orange;
    else if (task.priority == 2) priorityColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          activeColor: Colors.green,
          onChanged: (_) {
            ref.read(dailyTaskNotifierProvider.notifier).toggleTaskCompletion(task);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                task.description,
                style: TextStyle(
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? Colors.grey : null,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Due: ${DateFormat('MMM d').format(task.dueDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
          onPressed: () {
            ref.read(dailyTaskNotifierProvider.notifier).deleteTask(task.id);
          },
        ),
      ),
    );
  }
}
