import '../../../../core/database/database_helper.dart';
import '../models/exam_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ExamLocalDataSource {
  Future<List<ExamModel>> getExams();
  Future<List<ExamModel>> getExamsBySubject(String subjectId);
  Future<void> saveExam(ExamModel exam);
  Future<void> deleteExam(String id);
}

class ExamLocalDataSourceImpl implements ExamLocalDataSource {
  final DatabaseHelper _dbHelper;

  ExamLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ExamModel>> getExams() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exams',
      where: 'deleted_at IS NULL',
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((m) => ExamModel.fromMap(m)).toList();
  }

  @override
  Future<List<ExamModel>> getExamsBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'exams',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'scheduled_date ASC',
    );
    return maps.map((m) => ExamModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveExam(ExamModel exam) async {
    final db = await _dbHelper.database;
    await db.insert(
      'exams',
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteExam(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'exams',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
