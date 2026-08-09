import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:semestra_app/core/widgets/lottie_header.dart';
import 'package:semestra_app/features/item/domain/entities/item_entity.dart';
import 'package:semestra_app/features/item/presentation/providers/item_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import '../../../../core/theme/app_theme.dart';

/// Unified workspace that merges Notes, Tasks (daily planner) and Assignments
/// into a single module with three tabs.
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTab) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    switch (_currentTab) {
      case 0: // Notes
        if (subjects.isEmpty) {
          _needSubject();
          return;
        }
        context.push('/planner/note');
        break;
      case 1: // Tasks
        context.push('/planner/task');
        break;
      case 2: // Assignments
        if (subjects.isEmpty) {
          _needSubject();
          return;
        }
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const FractionallySizedBox(
            heightFactor: 1.0,
            child: _AddAssignmentSheet(),
          ),
        );
        break;
    }
  }

  void _needSubject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create a Subject first to organize this.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const LottieHeader(
              url: 'https://assets2.lottiefiles.com/packages/lf20_touohxv0.json',
              title: 'Your Planner',
              subtitle: 'Notes, tasks & assignments — all in one vibe ✨',
              height: 120,
              fallbackIcon: Icons.auto_awesome_rounded,
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.sticky_note_2_rounded), text: 'Notes'),
                Tab(icon: Icon(Icons.checklist_rounded), text: 'Tasks'),
                Tab(icon: Icon(Icons.assignment_rounded), text: 'Assignments'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _NotesTab(),
                  _TasksTab(),
                  _AssignmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NOTES TAB
// ---------------------------------------------------------------------------

class _NotesTab extends ConsumerStatefulWidget {
  const _NotesTab();

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  String _searchQuery = '';
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return subjectState.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return const _CenteredHint(
            'Please create at least one Subject before recording notes.',
          );
        }

        return itemsState.when(
          data: (items) {
            var notes = items.where((i) => i.type == ItemType.note).toList();
            if (_selectedSubjectId != null) {
              notes = notes.where((n) => n.subjectId == _selectedSubjectId).toList();
            }
            if (_searchQuery.trim().isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              notes = notes
                  .where((n) =>
                      n.title.toLowerCase().contains(q) ||
                      n.content.toLowerCase().contains(q))
                  .toList();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search notes and contents...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          labelText: 'Subject Filter',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Subjects')),
                          ...subjects.map((sub) => DropdownMenuItem(
                                value: sub.id,
                                child: Text(sub.code),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedSubjectId = val),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: notes.isEmpty
                      ? _CenteredHint(
                          'No notes match your filters. Tap + to compose your first note!',
                          style: theme.textTheme.bodyMedium,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(24),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 350,
                            mainAxisExtent: 140,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final sub = subjects.firstWhere(
                              (s) => s.id == note.subjectId,
                              orElse: () => subjects.first,
                            );
                            return _NoteCard(
                              note: note,
                              subjectName: sub.name,
                              subjectCode: sub.code,
                              subjectColor: Color(sub.colorValue),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading notes: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading subjects: $err')),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final ItemEntity note;
  final String subjectName;
  final String subjectCode;
  final Color subjectColor;

  const _NoteCard({
    required this.note,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _openViewer(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                      subjectCode,
                      style: TextStyle(
                        color: subjectColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(note.createdAt),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                note.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(note.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () {
                  ref.read(itemNotifierProvider.notifier).deleteItem(note.id, ItemType.note);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$subjectCode: $subjectName',
                          style: TextStyle(color: subjectColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Created: ${note.createdAt.toString().substring(0, 16)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _CustomMarkdownRenderer(markdown: note.content),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomMarkdownRenderer extends StatelessWidget {
  final String markdown;

  const _CustomMarkdownRenderer({required this.markdown});

  @override
  Widget build(BuildContext context) {
    final lines = markdown.split('\n');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
        }
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              trimmed.substring(3),
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }
        if (trimmed.startsWith('- [ ] ')) {
          return Row(
            children: [
              const Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(trimmed.substring(6), style: theme.textTheme.bodyLarge),
            ],
          );
        }
        if (trimmed.startsWith('- [x] ') || trimmed.startsWith('- [X] ')) {
          return Row(
            children: [
              const Icon(Icons.check_box_rounded, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                trimmed.substring(6),
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }
        if (trimmed.startsWith('- ')) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 6, right: 10),
                child: Icon(Icons.fiber_manual_record, size: 6, color: Colors.grey),
              ),
              Expanded(child: Text(trimmed.substring(2), style: theme.textTheme.bodyLarge)),
            ],
          );
        }
        if (trimmed.startsWith('```')) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Text(
              'Code Snippet Block',
              style: TextStyle(fontFamily: 'monospace', color: Colors.indigoAccent),
            ),
          );
        }
        if (trimmed.startsWith('> ')) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFF6366F1), width: 4)),
            ),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: theme.textTheme.bodyLarge),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// TASKS TAB
// ---------------------------------------------------------------------------

class _TasksTab extends ConsumerWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemNotifierProvider);

    return itemsState.when(
      data: (items) {
        final tasks = items.where((i) => i.type == ItemType.task).toList();
        if (tasks.isEmpty) {
          return const _CenteredHint('No tasks yet. Tap + to add one.');
        }

        tasks.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.updatedAt.compareTo(a.updatedAt);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: tasks.length,
          itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading tasks: $err')),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final ItemEntity task;

  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color priorityColor = Colors.green;
    if (task.priority == 1) {
      priorityColor = Colors.orange;
    } else if (task.priority == 2) {
      priorityColor = Colors.red;
    }

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
            ref.read(itemNotifierProvider.notifier).toggleTaskCompletion(task);
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
            if (task.content.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                task.content,
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
                  decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  task.dueDate != null
                      ? 'Due: ${DateFormat('MMM d').format(task.dueDate!)}'
                      : 'No due date',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
          onPressed: () {
            ref.read(itemNotifierProvider.notifier).deleteItem(task.id, ItemType.task);
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ASSIGNMENTS TAB
// ---------------------------------------------------------------------------

class _AssignmentsTab extends ConsumerStatefulWidget {
  const _AssignmentsTab();

  @override
  ConsumerState<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends ConsumerState<_AssignmentsTab> {
  int _statusFilter = 0; // 0 Not Started, 1 In Progress, 2 Completed

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);

    return subjectState.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return const _CenteredHint(
            'Please add a Subject before tracking assignments.',
          );
        }
        return itemsState.when(
          data: (items) {
            final assignments =
                items.where((i) => i.type == ItemType.assignment).toList();
            final filtered =
                assignments.where((a) => a.status == _statusFilter).toList()
                  ..sort((a, b) => (a.dueDate ?? DateTime(2100))
                      .compareTo(b.dueDate ?? DateTime(2100)));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('To Do')),
                      ButtonSegment(value: 1, label: Text('Doing')),
                      ButtonSegment(value: 2, label: Text('Done')),
                    ],
                    selected: {_statusFilter},
                    onSelectionChanged: (s) => setState(() => _statusFilter = s.first),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _AssignmentEmpty(statusTab: _statusFilter)
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final assign = filtered[index];
                            final subject = subjects.firstWhere(
                              (s) => s.id == assign.subjectId,
                              orElse: () => subjects.first,
                            );
                            return _AssignmentCard(
                              assignment: assign,
                              subjectName: subject.name,
                              subjectCode: subject.code,
                              subjectColor: Color(subject.colorValue),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading assignments: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading subjects: $err')),
    );
  }
}

class _AssignmentEmpty extends StatelessWidget {
  final int statusTab;
  const _AssignmentEmpty({required this.statusTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusTab == 2
                  ? Icons.check_circle_outline_rounded
                  : Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              statusTab == 2
                  ? 'No completed assignments yet. Finish your work to celebrate!'
                  : 'Clear! No assignments in this section.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final ItemEntity assignment;
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

    Color priorityColor = Colors.green;
    String priorityText = 'Low';
    if (assignment.priority == 1) {
      priorityColor = Colors.orange;
      priorityText = 'Medium';
    } else if (assignment.priority == 2) {
      priorityColor = Colors.red;
      priorityText = 'High';
    }

    final due = assignment.dueDate;
    final daysRemaining = due?.difference(DateTime.now()).inDays;
    String dueText = 'No due date';
    if (daysRemaining != null) {
      dueText = 'Due in $daysRemaining days';
      if (daysRemaining == 0) {
        dueText = 'Due today!';
      } else if (daysRemaining < 0) {
        dueText = 'Overdue by ${-daysRemaining} days';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            if (assignment.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(assignment.content, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dueText,
                  style: TextStyle(
                    color: (daysRemaining != null && daysRemaining < 0)
                        ? Colors.red
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    fontSize: 13,
                    fontWeight: (daysRemaining != null && daysRemaining < 0)
                        ? FontWeight.bold
                        : FontWeight.normal,
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
                Row(
                  children: [
                    if (assignment.status != 0)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(itemNotifierProvider.notifier)
                            .updateStatus(assignment, 0),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text('To Do'),
                      ),
                    if (assignment.status != 1) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(itemNotifierProvider.notifier)
                            .updateStatus(assignment, 1),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('In Progress'),
                      ),
                    ],
                    if (assignment.status != 2) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(itemNotifierProvider.notifier)
                            .updateStatus(assignment, 2),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Complete'),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () {
                    ref
                        .read(itemNotifierProvider.notifier)
                        .deleteItem(assignment.id, ItemType.assignment);
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

class _AddAssignmentSheet extends ConsumerStatefulWidget {
  const _AddAssignmentSheet();

  @override
  ConsumerState<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends ConsumerState<_AddAssignmentSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedSubjectId;
  int _priority = 1;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));

  Color get _priorityColor {
    switch (_priority) {
      case 0:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get _priorityLabel {
    switch (_priority) {
      case 0:
        return 'Low';
      case 2:
        return 'High';
      default:
        return 'Medium';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save(List<dynamic> subjects) {
    final title = _titleController.text.trim();
    final subjectId = _selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);
    if (title.isNotEmpty && subjectId != null) {
      ref.read(itemNotifierProvider.notifier).addItem(
            type: ItemType.assignment,
            subjectId: subjectId,
            title: title,
            content: _descController.text.trim(),
            notes: _notesController.text.trim(),
            dueDate: _dueDate,
            priority: _priority,
            status: 0,
          );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an assignment title.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : const Color(0xFFF9FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'New Assignment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => _save(subjects),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Assignment Title',
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Add short description...',
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.book_rounded, color: theme.colorScheme.primary),
                              title: const Text('Subject'),
                              trailing: DropdownButton<String>(
                                value: _selectedSubjectId,
                                underline: const SizedBox.shrink(),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                                items: subjects.map<DropdownMenuItem<String>>((sub) {
                                  return DropdownMenuItem<String>(
                                    value: sub.id,
                                    child: Text(sub.code),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedSubjectId = val);
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                              title: const Text('Due Date'),
                              subtitle: Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(_dueDate),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _dueDate = picked);
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.flag_rounded, color: _priorityColor),
                              title: const Text('Priority'),
                              trailing: PopupMenuButton<int>(
                                initialValue: _priority,
                                onSelected: (val) => setState(() => _priority = val),
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 0, child: Text('Low')),
                                  PopupMenuItem(value: 1, child: Text('Medium')),
                                  PopupMenuItem(value: 2, child: Text('High')),
                                ],
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _priorityLabel,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _priorityColor,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.arrow_drop_down_rounded, size: 16, color: _priorityColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Additional Notes',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    TextField(
                      controller: _notesController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Add details, link, or resources...',
                        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                        ),
                        filled: isDark,
                        fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED
// ---------------------------------------------------------------------------

class _CenteredHint extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _CenteredHint(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style ?? const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
