import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_theme.dart';
import '../utils/app_toast.dart';
import '../utils/format.dart';
import '../../features/item/domain/entities/item_entity.dart';
import '../../features/item/presentation/providers/item_provider.dart';
import '../../features/subject/domain/entities/subject_entity.dart';
import '../../features/subject/presentation/providers/subject_provider.dart';
import '../../features/schedule/domain/entities/schedule_entity.dart';
import '../../features/schedule/presentation/providers/schedule_provider.dart';

import '../../features/semester/presentation/providers/semester_provider.dart';
import '../../features/semester/presentation/pages/semester_page.dart' show showSemesterSheet;
import '../../app/navigation/navigation_shell.dart' show fabHiddenNotifier;

// ---------------------------------------------------------------------------
// Public entry points
// ---------------------------------------------------------------------------

/// The quick-add menu is a floating popup anchored above the FAB.
Future<void> showQuickAddSheet(BuildContext context) async {
  fabHiddenNotifier.value = true;
  try {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Quick add',
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return _QuickAddFloating(animation: curved);
      },
    );
  } finally {
    fabHiddenNotifier.value = false;
  }
}

Future<T?> _showSheet<T>(BuildContext context, Widget child) async {
  fabHiddenNotifier.value = true;
  try {
    return await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (_) => child,
    );
  } finally {
    fabHiddenNotifier.value = false;
  }
}

// ---------------------------------------------------------------------------
// Shared sheet chrome
// ---------------------------------------------------------------------------

class _SheetShell extends StatelessWidget {
  final Widget child;
  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkBg : AppTheme.warmBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white24
                      : AppTheme.inkFaint.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;
  const _SheetTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.chevron_left_rounded,
              color: AppTheme.primary, size: 28),
        ),
        const SizedBox(width: 6),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.65)
              : AppTheme.inkMuted,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick add menu
// ---------------------------------------------------------------------------

class _QuickAddFloating extends StatelessWidget {
  final Animation<double> animation;
  const _QuickAddFloating({required this.animation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    void openThen(void Function() open) {
      Navigator.of(context).pop();
      open();
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        // Sit just above the FAB / bottom nav.
        padding: EdgeInsets.only(right: 16, bottom: 84 + bottomInset),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 288,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.45 : 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Row(
                        children: [
                          Text('Quick add',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                    _QuickAddOption(
                      icon: Icons.description_outlined,
                      color: AppTheme.statPurple,
                      title: 'Note',
                      subtitle: 'Capture a quick thought',
                      onTap: () => openThen(() => showNewNoteSheet(context)),
                    ),
                    _QuickAddOption(
                      icon: Icons.check_box_outlined,
                      color: AppTheme.statGreen,
                      title: 'Task',
                      subtitle: 'Something to get done',
                      onTap: () =>
                          openThen(() => showNewWorkItemSheet(context, ItemType.task)),
                    ),
                    _QuickAddOption(
                      icon: Icons.assignment_outlined,
                      color: AppTheme.statRed,
                      title: 'Assignment',
                      subtitle: 'Graded work with a due date',
                      onTap: () => openThen(
                          () => showNewWorkItemSheet(context, ItemType.assignment)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAddOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.soft(color, 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable subject chip selector
// ---------------------------------------------------------------------------

class _SubjectChips extends StatelessWidget {
  final List<SubjectEntity> subjects;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _SubjectChips({
    required this.subjects,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: subjects.map((s) {
        final color = Color(s.colorValue);
        final selected = s.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(s.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.soft(color, selected ? 0.22 : 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              s.name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NoSubjectsHint extends StatelessWidget {
  const _NoSubjectsHint();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.soft(AppTheme.statOrange, 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Add a subject in your Workspace first to attach items to it.',
        style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppTheme.inkMuted,
            fontSize: 13),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Note
// ---------------------------------------------------------------------------

Future<void> showNewNoteSheet(BuildContext context) =>
    _showSheet(context, const _NewNoteSheet());

class _NewNoteSheet extends ConsumerStatefulWidget {
  const _NewNoteSheet();
  @override
  ConsumerState<_NewNoteSheet> createState() => _NewNoteSheetState();
}

class _NewNoteSheetState extends ConsumerState<_NewNoteSheet> {
  final _title = TextEditingController();
  String? _subjectId;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save(List<SubjectEntity> subjects) {
    final title = _title.text.trim();
    if (title.isEmpty) {
      AppToast.error('Give your note a title');
      return;
    }
    if (_subjectId == null) {
      AppToast.error('Pick a subject');
      return;
    }
    ref.read(itemNotifierProvider.notifier).addItem(
          type: ItemType.note,
          subjectId: _subjectId,
          title: title,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;

    return _SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetTitle('New Note'),
          const SizedBox(height: 22),
          const _FieldLabel('TITLE'),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Untitled note'),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('SUBJECT'),
          if (subjects.isEmpty)
            const _NoSubjectsHint()
          else
            _SubjectChips(
              subjects: subjects,
              selectedId: _subjectId,
              onSelect: (id) => setState(() => _subjectId = id),
            ),
          const SizedBox(height: 26),
          _PrimaryButton(label: 'Save Note', onTap: () => _save(subjects)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Task / New Assignment (shared)
// ---------------------------------------------------------------------------

Future<void> showNewWorkItemSheet(BuildContext context, ItemType type) =>
    _showSheet(context, _NewWorkItemSheet(type: type));

class _NewWorkItemSheet extends ConsumerStatefulWidget {
  final ItemType type;
  const _NewWorkItemSheet({required this.type});
  @override
  ConsumerState<_NewWorkItemSheet> createState() => _NewWorkItemSheetState();
}

class _NewWorkItemSheetState extends ConsumerState<_NewWorkItemSheet> {
  final _title = TextEditingController();
  String? _subjectId;
  DateTime? _due;
  int _priority = 2; // High by default (matches mockup)

  bool get _isAssignment => widget.type == ItemType.assignment;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _due = picked);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      AppToast.error('Give it a title');
      return;
    }
    ref.read(itemNotifierProvider.notifier).addItem(
          type: widget.type,
          subjectId: _subjectId,
          title: title,
          dueDate: _due,
          priority: _priority,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final titleText = _isAssignment ? 'New Assignment' : 'New Task';
    final hint = _isAssignment ? 'e.g. Chapter 5 exercises' : 'What needs doing?';
    final saveLabel = _isAssignment ? 'Save Assignment' : 'Save Task';

    return _SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetTitle(titleText),
          const SizedBox(height: 22),
          const _FieldLabel('TITLE'),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: hint),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('SUBJECT'),
          if (subjects.isEmpty)
            const _NoSubjectsHint()
          else
            _SubjectChips(
              subjects: subjects,
              selectedId: _subjectId,
              onSelect: (id) => setState(
                () => _subjectId = _subjectId == id ? null : id,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('DUE'),
                    _PickerField(
                      label: _due == null ? 'Pick a date' : Fmt.dueLabel(_due!),
                      muted: _due == null,
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('PRIORITY'),
                    _PriorityField(
                      value: _priority,
                      onChanged: (v) => setState(() => _priority = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _PrimaryButton(label: saveLabel, onTap: _save),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final bool muted;
  final IconData icon;
  final VoidCallback onTap;
  const _PickerField({
    required this.label,
    required this.muted,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 17,
                color: isDark ? Colors.white38 : AppTheme.inkFaint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted
                      ? (isDark ? Colors.white38 : AppTheme.inkFaint)
                      : (isDark ? AppTheme.darkInk : AppTheme.ink),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _priorityLabels = ['Low', 'Med', 'High'];
const _priorityColors = [AppTheme.statGreen, AppTheme.statOrange, AppTheme.statRed];

class _PriorityField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PriorityField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColors[value];
    return GestureDetector(
      onTap: () => onChanged((value + 1) % 3),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.soft(color, 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _priorityLabels[value],
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Study session -> saved as a Schedule (type = study)
// ---------------------------------------------------------------------------

Future<void> showNewStudySessionSheet(BuildContext context) =>
    _showSheet(context, const _NewStudySessionSheet());

class _NewStudySessionSheet extends ConsumerStatefulWidget {
  const _NewStudySessionSheet();
  @override
  ConsumerState<_NewStudySessionSheet> createState() =>
      _NewStudySessionSheetState();
}

class _NewStudySessionSheetState extends ConsumerState<_NewStudySessionSheet> {
  String? _subjectId;
  int _day = DateTime.now().weekday; // 1..7
  TimeOfDay _start = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  void _save(List<SubjectEntity> subjects) {
    if (_subjectId == null) {
      AppToast.error('Pick a subject');
      return;
    }
    final subject = subjects.firstWhere((s) => s.id == _subjectId);
    ref.read(scheduleNotifierProvider.notifier).addSchedule(
          subjectId: _subjectId!,
          dayOfWeek: _day,
          startTime: Fmt.hhmmFromTod(_start),
          endTime: Fmt.hhmmFromTod(_end),
          classroom: subject.classroom,
          instructor: subject.instructor,
          type: 2, // study
        );
    AppToast.success('Study session added');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;

    return _SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetTitle('New Study Session'),
          const SizedBox(height: 22),
          const _FieldLabel('SUBJECT'),
          if (subjects.isEmpty)
            const _NoSubjectsHint()
          else
            _SubjectChips(
              subjects: subjects,
              selectedId: _subjectId,
              onSelect: (id) => setState(() => _subjectId = id),
            ),
          const SizedBox(height: 20),
          const _FieldLabel('DAY'),
          Row(
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _day == day;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _day = day),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary
                          : (isDark ? AppTheme.darkCard : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primary
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppTheme.hairline),
                      ),
                    ),
                    child: Text(
                      Fmt.weekdayAbbr[i].substring(0, 1),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppTheme.inkMuted),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('START'),
                    _PickerField(
                      label: _start.format(context),
                      muted: false,
                      icon: Icons.schedule_rounded,
                      onTap: () => _pickTime(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('END'),
                    _PickerField(
                      label: _end.format(context),
                      muted: false,
                      icon: Icons.schedule_rounded,
                      onTap: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _PrimaryButton(
              label: 'Save Study Session', onTap: () => _save(subjects)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Subject
// ---------------------------------------------------------------------------

Future<void> showNewSubjectSheet(BuildContext context, {String? defaultSemesterId}) =>
    _showSheet(context, _NewSubjectSheet(defaultSemesterId: defaultSemesterId));

Future<void> showEditSubjectSheet(
  BuildContext context, {
  required SubjectEntity subject,
  List<ScheduleEntity>? schedules,
}) =>
    _showSheet(
      context,
      _NewSubjectSheet(
        subjectToEdit: subject,
        existingSchedules: schedules,
      ),
    );

class _NewSubjectSheet extends ConsumerStatefulWidget {
  final String? defaultSemesterId;
  final SubjectEntity? subjectToEdit;
  final List<ScheduleEntity>? existingSchedules;

  const _NewSubjectSheet({
    this.defaultSemesterId,
    this.subjectToEdit,
    this.existingSchedules,
  });

  @override
  ConsumerState<_NewSubjectSheet> createState() => _NewSubjectSheetState();
}

class _NewSubjectSheetState extends ConsumerState<_NewSubjectSheet> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _instructor = TextEditingController();
  final _classroom = TextEditingController();
  String? _semesterId;
  double _units = 3.0;
  Color _color = AppTheme.subjectColors.first;
  final Set<int> _selectedDays = {1};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  bool get _isEditing => widget.subjectToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final sub = widget.subjectToEdit!;
      _code.text = sub.code;
      _name.text = sub.name;
      _instructor.text = sub.instructor;
      _classroom.text = sub.classroom;
      _semesterId = sub.semesterId;
      _units = sub.units;
      _color = Color(sub.colorValue);

      if (widget.existingSchedules != null &&
          widget.existingSchedules!.isNotEmpty) {
        _selectedDays.clear();
        for (final s in widget.existingSchedules!) {
          _selectedDays.add(s.dayOfWeek);
        }
        final first = widget.existingSchedules!.first;
        final st = Fmt.parseHHmm(first.startTime);
        if (st != null) _startTime = st;
        final et = Fmt.parseHHmm(first.endTime);
        if (et != null) _endTime = et;
      }
    } else {
      _semesterId = widget.defaultSemesterId;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _instructor.dispose();
    _classroom.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          final startMins = _startTime.hour * 60 + _startTime.minute;
          final endMins = _endTime.hour * 60 + _endTime.minute;
          if (endMins <= startMins) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    final code = _code.text.trim().toUpperCase();
    final name = _name.text.trim();
    if (name.isEmpty) {
      AppToast.error('Please enter a subject name');
      return;
    }
    if (_semesterId == null) {
      AppToast.error('Please select a semester');
      return;
    }

    if (_isEditing) {
      final updated = widget.subjectToEdit!.copyWith(
        semesterId: _semesterId!,
        code: code,
        name: name,
        instructor: _instructor.text.trim(),
        classroom: _classroom.text.trim(),
        units: _units,
        colorValue: _color.toARGB32(),
      );
      ref.read(subjectNotifierProvider.notifier).editSubject(updated);

      if (widget.existingSchedules != null) {
        for (final sch in widget.existingSchedules!) {
          ref.read(scheduleNotifierProvider.notifier).deleteSchedule(sch.id);
        }
      }

      for (final day in _selectedDays) {
        ref.read(scheduleNotifierProvider.notifier).addSchedule(
              subjectId: updated.id,
              dayOfWeek: day,
              startTime: Fmt.hhmmFromTod(_startTime),
              endTime: Fmt.hhmmFromTod(_endTime),
              classroom: _classroom.text.trim(),
              instructor: _instructor.text.trim(),
              type: 0,
            );
      }

      AppToast.success('Subject updated');
    } else {
      final subjectId = const Uuid().v4();
      ref.read(subjectNotifierProvider.notifier).addSubject(
            id: subjectId,
            semesterId: _semesterId!,
            code: code,
            name: name,
            instructor: _instructor.text.trim(),
            classroom: _classroom.text.trim(),
            units: _units,
            colorValue: _color.toARGB32(),
          );

      for (final day in _selectedDays) {
        ref.read(scheduleNotifierProvider.notifier).addSchedule(
              subjectId: subjectId,
              dayOfWeek: day,
              startTime: Fmt.hhmmFromTod(_startTime),
              endTime: Fmt.hhmmFromTod(_endTime),
              classroom: _classroom.text.trim(),
              instructor: _instructor.text.trim(),
              type: 0,
            );
      }

      AppToast.success('Subject added');
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    if (_semesterId == null && semesters.isNotEmpty) {
      final active = semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);
      _semesterId = active.id;
    }

    return _SheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetTitle(_isEditing ? 'Edit Subject' : 'New Subject'),
          const SizedBox(height: 20),
          if (semesters.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.soft(AppTheme.statOrange, 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No semesters found',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You need to create a semester before adding subjects to it.',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : AppTheme.inkMuted,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showSemesterSheet(context);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create a Semester'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const _FieldLabel('SEMESTER'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkCard
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _semesterId,
                  isExpanded: true,
                  items: semesters.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(
                        '${s.name}${s.isActive ? ' (Active)' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _semesterId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('CODE'),
                      TextField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(hintText: 'CS101'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('SUBJECT NAME'),
                      TextField(
                        controller: _name,
                        decoration: const InputDecoration(hintText: 'e.g. Data Structures'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('INSTRUCTOR'),
                      TextField(
                        controller: _instructor,
                        decoration: const InputDecoration(hintText: 'Optional'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('CLASSROOM'),
                      TextField(
                        controller: _classroom,
                        decoration: const InputDecoration(hintText: 'Optional'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FieldLabel('DAY (MON - SUN)'),
            Row(
              children: List.generate(7, (i) {
                final dayNum = i + 1;
                final isSelected = _selectedDays.contains(dayNum);
                const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedDays.length > 1) {
                            _selectedDays.remove(dayNum);
                          }
                        } else {
                          _selectedDays.add(dayNum);
                        }
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.brand
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkCard
                                : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.brand
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppTheme.hairline),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        dayLabels[i],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : AppTheme.inkMuted),
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('START TIME'),
                      _PickerField(
                        label: Fmt.time12(Fmt.hhmmFromTod(_startTime)),
                        muted: false,
                        icon: Icons.access_time_rounded,
                        onTap: () => _pickTime(true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('END TIME'),
                      _PickerField(
                        label: Fmt.time12(Fmt.hhmmFromTod(_endTime)),
                        muted: false,
                        icon: Icons.access_time_rounded,
                        onTap: () => _pickTime(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _FieldLabel('CREDITS / UNITS'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () {
                        if (_units > 0.5) setState(() => _units -= 0.5);
                      },
                    ),
                    Text(
                      '$_units',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () => setState(() => _units += 0.5),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FieldLabel('COLOR THEME'),
            Wrap(
              spacing: 8,
              children: AppTheme.subjectColors.map((color) {
                final isSelected = _color == color;
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: _isEditing ? 'Save Changes' : 'Save Subject',
              onTap: _save,
            ),
          ],
        ],
      ),
    );
  }
}

