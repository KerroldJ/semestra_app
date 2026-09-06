import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/item_provider.dart';

/// Screen 11 — Assignment editor. Subject chips, title, description, due date,
/// priority, status and a lightweight steps checklist. Editing is opened from
/// the Assignments list (`/assignments/edit` with the item as `extra`); with no
/// item it creates a new assignment.
class AssignmentEditorPage extends ConsumerStatefulWidget {
  final ItemEntity? item;
  const AssignmentEditorPage({super.key, this.item});

  @override
  ConsumerState<AssignmentEditorPage> createState() =>
      _AssignmentEditorPageState();
}

class _AssignmentEditorPageState extends ConsumerState<AssignmentEditorPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _stepController = TextEditingController();

  String? _subjectId;
  DateTime? _dueDate;
  int _priority = 1;
  int _status = 0;
  List<_Step> _steps = [];

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item != null) {
      _titleController.text = item.title;
      _descController.text = item.content;
      _subjectId = item.subjectId;
      _dueDate = item.dueDate;
      _priority = item.priority;
      _status = item.status;
      _steps = _parseSteps(item.notes);
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit assignment' : 'New assignment'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.goldDeep, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: subjects.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Create a subject before adding assignments.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // Subject chips.
                Eyebrow('Subject'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.map((s) {
                    final selected = s.id == _subjectId;
                    return GestureDetector(
                      onTap: () => setState(() => _subjectId = s.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? AppTheme.gold : AppTheme.hairline,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 2,
                                height: 12,
                                color: AppTheme.spineFor(s.colorValue)),
                            const SizedBox(width: 8),
                            Text(s.name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: AppTheme.ink,
                                )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Title.
                TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'Assignment title',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 6),

                // Due date + priority row.
                Row(
                  children: [
                    _Pill(
                      icon: Icons.calendar_today_rounded,
                      label: _dueDate == null
                          ? 'Set due date'
                          : DateFormat('MMM d, yyyy').format(_dueDate!),
                      onTap: _pickDate,
                    ),
                    const SizedBox(width: 10),
                    _PriorityPicker(
                      priority: _priority,
                      onChanged: (p) => setState(() => _priority = p),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Status segmented.
                Eyebrow('Status'),
                const SizedBox(height: 10),
                _StatusSegmented(
                  status: _status,
                  onChanged: (s) => setState(() => _status = s),
                ),
                const SizedBox(height: 22),

                // Description.
                Eyebrow('Details'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: null,
                  minLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add description or details…',
                  ),
                ),
                const SizedBox(height: 22),

                // Steps checklist.
                Eyebrow('Steps'),
                const SizedBox(height: 10),
                ..._steps.asMap().entries.map((e) {
                  final i = e.key;
                  final step = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => _steps[i] = step.copyWith(done: !step.done)),
                          child: Icon(
                            step.done
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: step.done
                                ? AppTheme.success
                                : AppTheme.inkFaint,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  decoration: step.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: step.done ? AppTheme.inkMuted : null,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppTheme.inkFaint),
                          onPressed: () =>
                              setState(() => _steps.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stepController,
                        onSubmitted: (_) => _addStep(),
                        decoration: const InputDecoration(
                          hintText: 'Add a step…',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_rounded,
                          color: AppTheme.goldDeep),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _addStep() {
    final text = _stepController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _steps.add(_Step(text: text, done: false));
      _stepController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // Nothing to save.
      context.pop();
      return;
    }
    final notes = _serializeSteps(_steps);
    final notifier = ref.read(itemNotifierProvider.notifier);
    final existing = widget.item;
    if (existing != null) {
      notifier.editItem(existing.copyWith(
        title: title,
        content: _descController.text.trim(),
        subjectId: _subjectId,
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
        notes: notes,
      ));
    } else {
      notifier.addItem(
        type: ItemType.assignment,
        subjectId: _subjectId,
        title: title,
        content: _descController.text.trim(),
        notes: notes,
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
      );
    }
    context.pop();
  }

  // ---- Steps <-> notes serialization ----
  // Steps persist in the item's `notes` field, one per line, prefixed with
  // "[x] " (done) or "[ ] " (open). Free-form notes without a marker are kept
  // as open steps so nothing is lost.
  static List<_Step> _parseSteps(String notes) {
    if (notes.trim().isEmpty) return [];
    return notes
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map((l) {
      if (l.startsWith('[x] ')) return _Step(text: l.substring(4), done: true);
      if (l.startsWith('[ ] ')) {
        return _Step(text: l.substring(4), done: false);
      }
      return _Step(text: l, done: false);
    }).toList();
  }

  static String _serializeSteps(List<_Step> steps) => steps
      .map((s) => '${s.done ? '[x] ' : '[ ] '}${s.text}')
      .join('\n');
}

class _Step {
  final String text;
  final bool done;
  const _Step({required this.text, required this.done});
  _Step copyWith({String? text, bool? done}) =>
      _Step(text: text ?? this.text, done: done ?? this.done);
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Pill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppTheme.inkMuted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.ink,
                )),
          ],
        ),
      ),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  final int priority;
  final ValueChanged<int> onChanged;
  const _PriorityPicker({required this.priority, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Low', 'Medium', 'High'];
    final colors = [AppTheme.inkMuted, AppTheme.gold, AppTheme.danger];
    return PopupMenuButton<int>(
      initialValue: priority,
      onSelected: onChanged,
      itemBuilder: (_) => List.generate(
        3,
        (i) => PopupMenuItem(value: i, child: Text(labels[i])),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors[priority], width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 14, color: colors[priority]),
            const SizedBox(width: 6),
            Text(labels[priority],
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors[priority],
                )),
            Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: colors[priority]),
          ],
        ),
      ),
    );
  }
}

class _StatusSegmented extends StatelessWidget {
  final int status;
  final ValueChanged<int> onChanged;
  const _StatusSegmented({required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['Not started', 'In progress', 'Done'];
    return Row(
      children: List.generate(3, (i) {
        final selected = status == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: selected ? AppTheme.soft(AppTheme.gold, 0.14) : null,
                border: Border.all(
                  color: selected ? AppTheme.gold : AppTheme.hairline,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppTheme.goldDeep : AppTheme.inkMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
