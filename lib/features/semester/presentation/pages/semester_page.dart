import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:semestra_app/core/utils/app_toast.dart';
import 'package:semestra_app/features/semester/presentation/providers/semester_provider.dart';
import 'package:semestra_app/features/semester/domain/entities/semester_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class SemesterPage extends ConsumerWidget {
  const SemesterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(semesterNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semesters'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: state.when(
        data: (semesters) {
          if (semesters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No semesters added yet. Create one to begin organizing subjects!',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: semesters
                .map((sem) => _SemesterCard(semester: sem))
                .toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading semesters: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSemesterSheet(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// Shared add / edit bottom sheet. Pass [existing] to edit; omit to create.
Future<void> showSemesterSheet(
  BuildContext context, {
  SemesterEntity? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.25),
    builder: (_) => _SemesterSheet(existing: existing),
  );
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
      AppToast.error('Name your semester');
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
                      color: AppTheme.inkFaint.withOpacity(0.5),
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
                    child: Text(_isEditing ? 'Save Changes' : 'Create Semester'),
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

  const _SemesterCard({required this.semester});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateRange =
        '${DateFormat('MMM d, yyyy').format(semester.startDate)} - ${DateFormat('MMM d, yyyy').format(semester.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: semester.isActive
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : Border.all(color: AppTheme.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    semester.name,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (semester.isActive)
                  _Badge(
                    label: 'ACTIVE',
                    gradient: const LinearGradient(
                        colors: AppTheme.primaryGradient),
                  )
                else if (semester.isArchived)
                  _Badge(label: 'ARCHIVED', color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 16, color: AppTheme.inkFaint),
                const SizedBox(width: 8),
                Text(dateRange, style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!semester.isActive)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(semesterNotifierProvider.notifier).editSemester(
                            semester.copyWith(isActive: true),
                          );
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    label: const Text('Set Active'),
                  ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () =>
                      showSemesterSheet(context, existing: semester),
                ),
                IconButton(
                  tooltip: semester.isArchived ? 'Unarchive' : 'Archive',
                  icon: Icon(
                      semester.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 20),
                  onPressed: () {
                    ref.read(semesterNotifierProvider.notifier).archiveSemester(
                          semester,
                          !semester.isArchived,
                        );
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Semester?'),
          content: Text(
              'Are you sure you want to delete "${semester.name}"? This action will hide all associated subjects and schedules.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref
                    .read(semesterNotifierProvider.notifier)
                    .deleteSemester(semester.id);
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

class _Badge extends StatelessWidget {
  final String label;
  final Gradient? gradient;
  final Color? color;
  const _Badge({required this.label, this.gradient, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
