import '../../../../core/database/database_helper.dart';
import '../models/assignment_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class AssignmentLocalDataSource {
  Future<List<AssignmentModel>> getAssignments();
  Future<List<AssignmentModel>> getAssignmentsBySubject(String subjectId);
  Future<void> saveAssignment(AssignmentModel assignment);
  Future<void> deleteAssignment(String id);
}

class AssignmentLocalDataSourceImpl implements AssignmentLocalDataSource {
  final DatabaseHelper _dbHelper;

  AssignmentLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<AssignmentModel>> getAssignments() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'assignments',
      where: 'deleted_at IS NULL',
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => AssignmentModel.fromMap(m)).toList();
  }

  @override
  Future<List<AssignmentModel>> getAssignmentsBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'assignments',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'due_date ASC',
    );
    return maps.map((m) => AssignmentModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveAssignment(AssignmentModel assignment) async {
    final db = await _dbHelper.database;
    await db.insert(
      'assignments',
      assignment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteAssignment(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'assignments',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
