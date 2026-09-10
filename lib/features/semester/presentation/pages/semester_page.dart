import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/navigation/navigation_shell.dart' show fabHiddenNotifier;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/common.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/entities/semester_entity.dart';
import '../providers/semester_provider.dart';

/// Screen — Semesters Management Tab.
/// Allows viewing, activating, editing, deleting, and creating semesters.
class SemesterPage extends ConsumerWidget {
  const SemesterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersState = ref.watch(semesterNotifierProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: semestersState.when(
          data: (semesters) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                Text(
                  DateFormat('MMMM d').format(now),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Semesters',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 20),
                if (semesters.isEmpty)
                  _EmptySemesters(
                    onCreate: () => showSemesterSheet(context),
                  )
                else ...[
                  ...semesters.map((sem) {
                    final semSubjects =
                        subjects.where((s) => s.semesterId == sem.id).toList();
                    final semUnits = semSubjects.fold<double>(
                        0.0, (acc, s) => acc + s.units);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SemesterCard(
                        semester: sem,
                        subjectCount: semSubjects.length,
                        totalUnits: semUnits,
                      ),
                    );
                  }),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading semesters: $err')),
        ),
      ),
    );
  }
}

/// Shared add / edit bottom sheet. Pass [existing] to edit; omit to create.
Future<void> showSemesterSheet(
  BuildContext context, {
  SemesterEntity? existing,
}) async {
  fabHiddenNotifier.value = true;
  try {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _SemesterSheet(existing: existing),
    );
  } finally {
    fabHiddenNotifier.value = false;
  }
}

class _SemesterSheet extends ConsumerStatefulWidget {
  final SemesterEntity? existing;
  const _SemesterSheet({this.existing});

  @override
  ConsumerState<_SemesterSheet> createState() => _SemesterSheetState();
}

class _SemesterSheetState extends ConsumerState<_SemesterSheet> {
  late final TextEditingController _name;
  late DateTime _start;
  late DateTime _end;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _start = e?.startDate ?? DateTime.now();
    _end = e?.endDate ?? DateTime.now().add(const Duration(days: 7 * 15));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      AppToast.error('Please enter a semester name');
      return;
    }
    final notifier = ref.read(semesterNotifierProvider.notifier);
    if (_isEditing) {
      notifier.editSemester(widget.existing!.copyWith(
        name: name,
        startDate: _start,
        endDate: _end,
      ));
      AppToast.success('Semester updated');
    } else {
      notifier.addSemester(
        name: name,
        startDate: _start,
        endDate: _end,
        isActive: true,
      );
      AppToast.success('Semester created');
    }
    Navigator.of(context).pop();
  }

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.inkFaint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_isEditing ? 'Edit Semester' : 'New Semester',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                const _Label('NAME'),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'e.g. Fall 2026'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('STARTS'),
                          _DateField(
                              label: DateFormat('MMM d, y').format(_start),
                              onTap: () => _pick(true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('ENDS'),
                          _DateField(
                              label: DateFormat('MMM d, y').format(_end),
                              onTap: () => _pick(false)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Semester',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.inkMuted,
            )),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.onTap});
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
          border: Border.all(color: AppTheme.hairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppTheme.inkFaint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.ink, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterCard extends ConsumerWidget {
  final SemesterEntity semester;
  final int subjectCount;
  final double totalUnits;

  const _SemesterCard({
    required this.semester,
    required this.subjectCount,
    required this.totalUnits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateRange =
        '${DateFormat('MMM d, yyyy').format(semester.startDate)} – ${DateFormat('MMM d, yyyy').format(semester.endDate)}';
    final unitsStr = totalUnits.toStringAsFixed(
        totalUnits.truncateToDouble() == totalUnits ? 0 : 1);

    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (semester.isArchived)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Pill(
                          text: 'Archived',
                          bg: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
                          fg: AppTheme.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: semester.isArchived ? 'Unarchive' : 'Archive',
                    icon: Icon(
                      semester.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 20,
                      color: semester.isArchived
                          ? AppTheme.brandDeep
                          : AppTheme.inkMuted,
                    ),
                    onPressed: () {
                      ref.read(semesterNotifierProvider.notifier).archiveSemester(
                            semester,
                            !semester.isArchived,
                          );
                      AppToast.success(semester.isArchived
                          ? '${semester.name} unarchived'
                          : '${semester.name} archived');
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit Semester',
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: AppTheme.inkMuted),
                    onPressed: () =>
                        showSemesterSheet(context, existing: semester),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 15, color: AppTheme.inkFaint),
                  const SizedBox(width: 6),
                  Text(
                    dateRange,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 15, color: AppTheme.inkFaint),
                  const SizedBox(width: 6),
                  Text(
                    '$subjectCount ${subjectCount == 1 ? 'subject' : 'subjects'} · $unitsStr ${totalUnits == 1 ? 'unit' : 'units'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                semester.isActive ? 'Active' : 'Inactive',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: semester.isActive
                      ? AppTheme.brandDeep
                      : AppTheme.inkMuted,
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: semester.isActive,
                activeColor: AppTheme.brandDeep,
                activeTrackColor: AppTheme.soft(AppTheme.brand, 0.4),
                onChanged: (val) {
                  ref.read(semesterNotifierProvider.notifier).editSemester(
                        semester.copyWith(isActive: val),
                      );
                  AppToast.success(val
                      ? '${semester.name} is now the active semester'
                      : '${semester.name} deactivated');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySemesters extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptySemesters({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.soft(AppTheme.brand, 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 28, color: AppTheme.brandDeep),
          ),
          const SizedBox(height: 16),
          Text(
            'No Semesters Created',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your academic semesters (e.g. Fall 2026, Spring 2027) to organize your courses and schedules.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Semester'),
          ),
        ],
      ),
    );
  }
}

