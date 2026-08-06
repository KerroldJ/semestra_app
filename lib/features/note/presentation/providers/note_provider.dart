import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/note/domain/entities/note_entity.dart';
import 'package:semestra_app/features/note/domain/repositories/note_repository.dart';

class NoteNotifier extends StateNotifier<AsyncValue<List<NoteEntity>>> {
  final NoteRepository _repository;

  NoteNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getNotes();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNote({
    required String subjectId,
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final newNote = NoteEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: title,
      content: content,
      tags: tags,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveNote(newNote);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editNote(NoteEntity note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveNote(updated);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _repository.deleteNote(id);
      await loadNotes();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final noteNotifierProvider =
    StateNotifierProvider<NoteNotifier, AsyncValue<List<NoteEntity>>>((ref) {
  final repository = ref.watch(noteRepositoryProvider);
  return NoteNotifier(repository);
});
