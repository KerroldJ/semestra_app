import '../entities/note_entity.dart';

abstract class NoteRepository {
  Future<List<NoteEntity>> getNotes();
  Future<List<NoteEntity>> getNotesBySubject(String subjectId);
  Future<NoteEntity?> getNoteById(String id);
  Future<void> saveNote(NoteEntity note);
  Future<void> deleteNote(String id);
}
