import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_data_source.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;

  NoteRepositoryImpl(this.localDataSource);

  @override
  Future<List<NoteEntity>> getNotes() async {
    final models = await localDataSource.getNotes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<NoteEntity>> getNotesBySubject(String subjectId) async {
    final models = await localDataSource.getNotesBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<NoteEntity?> getNoteById(String id) async {
    final model = await localDataSource.getNoteById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveNote(NoteEntity note) async {
    final model = NoteModel.fromEntity(note);
    await localDataSource.saveNote(model);
  }

  @override
  Future<void> deleteNote(String id) async {
    await localDataSource.deleteNote(id);
  }
}
