import '../../../../core/database/database_helper.dart';
import '../models/subject_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class SubjectLocalDataSource {
  Future<List<SubjectModel>> getSubjects();
  Future<List<SubjectModel>> getSubjectsBySemester(String semesterId);
  Future<SubjectModel?> getSubjectById(String id);
  Future<void> saveSubject(SubjectModel subject);
  Future<void> deleteSubject(String id);
}

class SubjectLocalDataSourceImpl implements SubjectLocalDataSource {
  final DatabaseHelper _dbHelper;

  SubjectLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<SubjectModel>> getSubjects() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'deleted_at IS NULL',
      orderBy: 'code ASC',
    );
    return maps.map((m) => SubjectModel.fromMap(m)).toList();
  }

  @override
  Future<List<SubjectModel>> getSubjectsBySemester(String semesterId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'semester_id = ? AND deleted_at IS NULL',
      whereArgs: [semesterId],
      orderBy: 'code ASC',
    );
    return maps.map((m) => SubjectModel.fromMap(m)).toList();
  }

  @override
  Future<SubjectModel?> getSubjectById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subjects',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SubjectModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveSubject(SubjectModel subject) async {
    final db = await _dbHelper.database;
    await db.insert(
      'subjects',
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSubject(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'subjects',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
