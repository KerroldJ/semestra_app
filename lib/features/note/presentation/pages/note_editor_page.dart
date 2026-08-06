import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:semestra_app/features/note/presentation/providers/note_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  const NoteEditorPage({super.key});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedSubjectId;
  bool _isSaved = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_isSaved) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final subjectId = _selectedSubjectId;

    if (title.isEmpty && content.isEmpty) {
      // Discard empty notes
      return;
    }

    if (subjectId == null) {
      return;
    }

    // Auto-fill title if empty but content exists
    final finalTitle = title.isEmpty ? 'Untitled Note' : title;

    ref.read(noteNotifierProvider.notifier).addNote(
          subjectId: subjectId,
          title: finalTitle,
          content: content,
          tags: const [], // Removed tags field
        );
    
    _isSaved = true;
  }

  void _saveAndPop() {
    _saveNote();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final theme = Theme.of(context);

    // Auto-select first subject if not selected
    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveNote();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveAndPop,
          ),
          title: const Text(
            'Notes',
            style: TextStyle(fontWeight: FontWeight.normal),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded),
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'save') {
                  _saveAndPop();
                } else if (val == 'discard') {
                  _isSaved = true; // prevent auto-save on pop
                  context.pop();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: Text('Save Note'),
                ),
                const PopupMenuItem(
                  value: 'discard',
                  child: Text('Discard Changes'),
                ),
              ],
            ),
          ],
        ),
        body: subjects.isEmpty
            ? const Center(
                child: Text('Please create a subject before adding notes.'),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtle, borderless Subject selector to keep the UI clean while supporting DB relations
                    Row(
                      children: [
                        Text(
                          'Subject:  ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedSubjectId,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          items: subjects.map((sub) {
                            return DropdownMenuItem(
                              value: sub.id,
                              child: Text('${sub.code} - ${sub.name}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSubjectId = val);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notion-style Title Input
                    TextField(
                      controller: _titleController,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: theme.textTheme.headlineMedium?.color?.withOpacity(0.9),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Multi-line editor area for note content
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Note something down',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
