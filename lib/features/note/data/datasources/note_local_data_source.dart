import '../../../../core/database/database_helper.dart';
import '../models/note_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Future<List<NoteModel>> getNotesBySubject(String subjectId);
  Future<NoteModel?> getNoteById(String id);
  Future<void> saveNote(NoteModel note);
  Future<void> deleteNote(String id);
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final DatabaseHelper _dbHelper;

  NoteLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<NoteModel>> getNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  @override
  Future<List<NoteModel>> getNotesBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => NoteModel.fromMap(m)).toList();
  }

  @override
  Future<NoteModel?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return NoteModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveNote(NoteModel note) async {
    final db = await _dbHelper.database;
    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteNote(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'notes',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
