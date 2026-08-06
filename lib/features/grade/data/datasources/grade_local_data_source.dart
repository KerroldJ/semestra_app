import '../../../../core/database/database_helper.dart';
import '../models/grade_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class GradeLocalDataSource {
  Future<List<GradeModel>> getGrades();
  Future<List<GradeModel>> getGradesBySubject(String subjectId);
  Future<void> saveGrade(GradeModel grade);
  Future<void> deleteGrade(String id);
}

class GradeLocalDataSourceImpl implements GradeLocalDataSource {
  final DatabaseHelper _dbHelper;

  GradeLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<GradeModel>> getGrades() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'grades',
      where: 'deleted_at IS NULL',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => GradeModel.fromMap(m)).toList();
  }

  @override
  Future<List<GradeModel>> getGradesBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'grades',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => GradeModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveGrade(GradeModel grade) async {
    final db = await _dbHelper.database;
    await db.insert(
      'grades',
      grade.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteGrade(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'grades',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
