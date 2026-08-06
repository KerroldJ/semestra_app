import '../../../../core/database/database_helper.dart';
import '../models/daily_task_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class DailyTaskLocalDataSource {
  Future<List<DailyTaskModel>> getDailyTasks();
  Future<void> saveDailyTask(DailyTaskModel task);
  Future<void> deleteDailyTask(String id);
}

class DailyTaskLocalDataSourceImpl implements DailyTaskLocalDataSource {
  final DatabaseHelper _dbHelper;

  DailyTaskLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<DailyTaskModel>> getDailyTasks() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'daily_tasks',
      where: 'deleted_at IS NULL',
      orderBy: 'is_completed ASC, due_date ASC',
    );
    return maps.map((m) => DailyTaskModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveDailyTask(DailyTaskModel task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'daily_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteDailyTask(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'daily_tasks',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
