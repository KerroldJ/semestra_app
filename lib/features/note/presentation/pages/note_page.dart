import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/note/presentation/providers/note_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/note/domain/entities/note_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class NotePage extends ConsumerStatefulWidget {
  const NotePage({super.key});

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  String _searchQuery = '';
  String? _selectedSubjectId;
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(noteNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Workspace Notes'),
      ),
      body: subjectState.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Please create at least one Subject in the Subject Registry before recording notes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return notesState.when(
            data: (notes) {
              // Extract all tags for filter
              final allTags = notes.expand((n) => n.tags).toSet().toList();

              // Apply filters
              var filteredNotes = notes;
              if (_selectedSubjectId != null) {
                filteredNotes = filteredNotes.where((n) => n.subjectId == _selectedSubjectId).toList();
              }
              if (_selectedTag != null) {
                filteredNotes = filteredNotes.where((n) => n.tags.contains(_selectedTag)).toList();
              }
              if (_searchQuery.trim().isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                filteredNotes = filteredNotes.where((n) {
                  return n.title.toLowerCase().contains(query) ||
                      n.content.toLowerCase().contains(query) ||
                      n.tags.any((t) => t.toLowerCase().contains(query));
                }).toList();
              }

              return Column(
                children: [
                  // Filter bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search notes, contents, or tags...',
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
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedSubjectId,
                                decoration: const InputDecoration(
                                  labelText: 'Subject Filter',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Subjects')),
                                  ...subjects.map((sub) {
                                    return DropdownMenuItem(
                                      value: sub.id,
                                      child: Text(sub.code),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setState(() => _selectedSubjectId = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedTag,
                                decoration: const InputDecoration(
                                  labelText: 'Tag Filter',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Tags')),
                                  ...allTags.map((tag) {
                                    return DropdownMenuItem(
                                      value: tag,
                                      child: Text('#$tag'),
                                    );
                                  }),
                                ],
                                onChanged: (val) => setState(() => _selectedTag = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Notes List
                  Expanded(
                    child: filteredNotes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No notes match your filters. Click + to compose your first note!',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 350,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
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
            error: (err, stack) => Center(child: Text('Error loading notes: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final subjects = ref.read(subjectNotifierProvider).value ?? [];
    if (subjects.isEmpty) return;

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedSubjectId = subjects.first.id;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Lecture Note'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
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
                        decoration: const InputDecoration(labelText: 'Note Title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Note Content (supports Markdown like #, - [ ], code blocks)',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          hintText: 'e.g. algebra, lecture1, exam-prep',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                      final tags = tagsController.text
                          .split(',')
                          .map((t) => t.trim().toLowerCase())
                          .where((t) => t.isNotEmpty)
                          .toList();

                      ref.read(noteNotifierProvider.notifier).addNote(
                            subjectId: selectedSubjectId,
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                            tags: tags,
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

class _NoteCard extends ConsumerWidget {
  final NoteEntity note;
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
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: () => _openNoteViewer(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
                          subjectCode,
                          style: TextStyle(
                            color: subjectColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(note.createdAt),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.content,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonth(date.month)}';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _openNoteViewer(BuildContext context, WidgetRef ref) {
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
                  ref.read(noteNotifierProvider.notifier).deleteNote(note.id);
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
                          style: TextStyle(
                            color: subjectColor,
                            fontWeight: FontWeight.bold,
                          ),
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
                  // Custom offline Markdown parser/renderer
                  _CustomMarkdownRenderer(markdown: note.content),
                  const SizedBox(height: 24),
                  if (note.tags.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: note.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: Colors.grey),
                        );
                      }).toList(),
                    ),
                  ],
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

        // 1. Heading 1 (# title)
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          );
        }
        // 2. Heading 2 (## title)
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(
              trimmed.substring(3),
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          );
        }
        // 3. Checklist (- [ ] or - [x])
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
        // 4. Bullet lists (- list item)
        if (trimmed.startsWith('- ')) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 6, right: 10),
                child: Icon(Icons.fiber_manual_record, size: 6, color: Colors.grey),
              ),
              Expanded(
                child: Text(trimmed.substring(2), style: theme.textTheme.bodyLarge),
              ),
            ],
          );
        }
        // 5. Code block
        if (trimmed.startsWith('```')) {
          // Simplistic code block container
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

        // 6. Blockquote (> quote)
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

        // Standard body paragraph
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line, style: theme.textTheme.bodyLarge),
        );
      }).toList(),
    );
  }
}
