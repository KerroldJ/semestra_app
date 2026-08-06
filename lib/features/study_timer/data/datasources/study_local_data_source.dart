import '../../../../core/database/database_helper.dart';
import '../models/study_session_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class StudyLocalDataSource {
  Future<List<StudySessionModel>> getStudySessions();
  Future<List<StudySessionModel>> getStudySessionsBySubject(String subjectId);
  Future<void> saveStudySession(StudySessionModel session);
}

class StudyLocalDataSourceImpl implements StudyLocalDataSource {
  final DatabaseHelper _dbHelper;

  StudyLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<StudySessionModel>> getStudySessions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'study_sessions',
      where: 'deleted_at IS NULL',
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => StudySessionModel.fromMap(m)).toList();
  }

  @override
  Future<List<StudySessionModel>> getStudySessionsBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'study_sessions',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'completed_at DESC',
    );
    return maps.map((m) => StudySessionModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveStudySession(StudySessionModel session) async {
    final db = await _dbHelper.database;
    await db.insert(
      'study_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
