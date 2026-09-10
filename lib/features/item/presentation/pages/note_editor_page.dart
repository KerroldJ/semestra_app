import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:semestra_app/features/item/domain/entities/item_entity.dart';
import 'package:semestra_app/features/item/presentation/providers/item_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';

class NoteEditorPage extends ConsumerStatefulWidget {
  /// When non-null the editor updates this existing note instead of creating a
  /// new one (opened from the Notes list via `/notes/edit` with `extra`).
  final ItemEntity? note;
  const NoteEditorPage({super.key, this.note});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleUndoController = UndoHistoryController();
  final _contentUndoController = UndoHistoryController();
  String? _selectedSubjectId;
  bool _isSaved = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _selectedSubjectId = note.subjectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleUndoController.dispose();
    _contentUndoController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_isSaved) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final subjectId = _selectedSubjectId;

    if (title.isEmpty && content.isEmpty) {
      return; // Discard empty notes
    }
    if (subjectId == null) {
      return;
    }

    final finalTitle = title.isEmpty ? 'Untitled Note' : title;
    _isSaved = true;

    final existing = widget.note;
    if (existing != null) {
      ref.read(itemNotifierProvider.notifier).editItem(
            existing.copyWith(
              title: finalTitle,
              content: content,
              subjectId: subjectId,
            ),
            silent: true,
          );
    } else {
      ref.read(itemNotifierProvider.notifier).addItem(
            type: ItemType.note,
            subjectId: subjectId,
            title: finalTitle,
            content: content,
          );
    }
  }

  void _undo() {
    if (_contentUndoController.value.canUndo) {
      _contentUndoController.undo();
    } else if (_titleUndoController.value.canUndo) {
      _titleUndoController.undo();
    }
  }

  void _redo() {
    if (_contentUndoController.value.canRedo) {
      _contentUndoController.redo();
    } else if (_titleUndoController.value.canRedo) {
      _titleUndoController.redo();
    }
  }

  void _saveAndPop() {
    _saveNote();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final theme = Theme.of(context);

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
          title: Text(_isEditing ? 'Edit Note' : 'New Note',
              style: const TextStyle(fontWeight: FontWeight.normal)),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'Undo',
              onPressed: _undo,
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded),
              tooltip: 'Redo',
              onPressed: _redo,
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save Note',
              onPressed: _saveAndPop,
            ),
          ],
        ),
        body: subjects.isEmpty
            ? const Center(child: Text('Please create a subject before adding notes.'))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    TextField(
                      controller: _titleController,
                      undoController: _titleUndoController,
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
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        undoController: _contentUndoController,
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
