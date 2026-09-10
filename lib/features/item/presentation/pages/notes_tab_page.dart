import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../item_selectors.dart';
import '../providers/item_provider.dart';

/// Screen 15 — Notes. Grouped by recency, subject filter chips, two-line
/// previews. Tapping a note opens the editor.
class NotesTabPage extends ConsumerStatefulWidget {
  const NotesTabPage({super.key});

  @override
  ConsumerState<NotesTabPage> createState() => _NotesTabPageState();
}

class _NotesTabPageState extends ConsumerState<NotesTabPage> {
  String? _filterSubjectId; // null = all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    final filtered = _filterSubjectId == null
        ? items
        : items.where((i) => i.subjectId == _filterSubjectId).toList();
    final groups = NoteGroups.from(filtered, now);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes',
                      style:
                          theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
                  const SizedBox(height: 14),
                  if (subjects.isNotEmpty)
                    _SubjectFilter(
                      subjects: subjects,
                      selectedId: _filterSubjectId,
                      onSelect: (id) => setState(() => _filterSubjectId = id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: groups.isEmpty
                  ? _EmptyNotes(onNew: () => context.push('/notes/edit'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      children: [
                        _section(context, 'Today', groups.today, subjectsById),
                        _section(context, 'This week', groups.thisWeek,
                            subjectsById),
                        _section(context, 'Earlier', groups.earlier,
                            subjectsById),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<ItemEntity> notes,
    Map<String, SubjectEntity> subjectsById,
  ) {
    if (notes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Eyebrow(title),
        ),
        ...notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NoteCard(
                note: n,
                subject: subjectsById[n.subjectId],
                onTap: () => context.push('/notes/edit', extra: n),
              ),
            )),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final ItemEntity note;
  final SubjectEntity? subject;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : AppTheme.inkFaint;
    return SpineCard(
      spine: spine,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(note.title.isEmpty ? 'Untitled note' : note.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(Fmt.dueLabel(note.updatedAt),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.merge(AppTheme.tnum)),
            ],
          ),
          if (note.content.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.content.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (subject != null) ...[
            const SizedBox(height: 8),
            Text(subject!.name,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.goldDeep)),
          ],
        ],
      ),
    );
  }
}

class _SubjectFilter extends StatelessWidget {
  final List<SubjectEntity> subjects;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  const _SubjectFilter({
    required this.subjects,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, 'All', selectedId == null, () => onSelect(null), null),
          ...subjects.map((s) => _chip(
                context,
                s.name,
                s.id == selectedId,
                () => onSelect(s.id),
                AppTheme.spineFor(s.colorValue),
              )),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected,
      VoidCallback onTap, Color? spine) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.gold : AppTheme.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (spine != null) ...[
                Container(width: 2, height: 12, color: spine),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyNotes({required this.onNew});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sticky_note_2_outlined,
                size: 34, color: AppTheme.inkFaint),
            const SizedBox(height: 14),
            Text('No notes yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Capture a thought and tag it to a subject.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
