import '../../../../core/database/database_helper.dart';
import '../models/semester_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class SemesterLocalDataSource {
  Future<List<SemesterModel>> getSemesters({bool includeArchived = true});
  Future<SemesterModel?> getSemesterById(String id);
  Future<void> saveSemester(SemesterModel semester);
  Future<void> deleteSemester(String id);
}

class SemesterLocalDataSourceImpl implements SemesterLocalDataSource {
  final DatabaseHelper _dbHelper;

  SemesterLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<SemesterModel>> getSemesters({bool includeArchived = true}) async {
    final db = await _dbHelper.database;
    String query = 'SELECT * FROM semesters WHERE deleted_at IS NULL';
    if (!includeArchived) {
      query += ' AND is_archived = 0';
    }
    query += ' ORDER BY start_date DESC';
    
    final maps = await db.rawQuery(query);
    return maps.map((m) => SemesterModel.fromMap(m)).toList();
  }

  @override
  Future<SemesterModel?> getSemesterById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'semesters',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SemesterModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveSemester(SemesterModel semester) async {
    final db = await _dbHelper.database;
    await db.insert(
      'semesters',
      semester.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSemester(String id) async {
    final db = await _dbHelper.database;
    // Set deleted_at timestamp instead of hard deleting (soft delete)
    await db.update(
      'semesters',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
