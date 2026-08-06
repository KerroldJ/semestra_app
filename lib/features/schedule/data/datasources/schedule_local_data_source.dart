import '../../../../core/database/database_helper.dart';
import '../models/schedule_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ScheduleLocalDataSource {
  Future<List<ScheduleModel>> getSchedules();
  Future<List<ScheduleModel>> getSchedulesBySubject(String subjectId);
  Future<void> saveSchedule(ScheduleModel schedule);
  Future<void> deleteSchedule(String id);
}

class ScheduleLocalDataSourceImpl implements ScheduleLocalDataSource {
  final DatabaseHelper _dbHelper;

  ScheduleLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ScheduleModel>> getSchedules() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'deleted_at IS NULL',
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return maps.map((m) => ScheduleModel.fromMap(m)).toList();
  }

  @override
  Future<List<ScheduleModel>> getSchedulesBySubject(String subjectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'schedules',
      where: 'subject_id = ? AND deleted_at IS NULL',
      whereArgs: [subjectId],
      orderBy: 'day_of_week ASC, start_time ASC',
    );
    return maps.map((m) => ScheduleModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveSchedule(ScheduleModel schedule) async {
    final db = await _dbHelper.database;
    await db.insert(
      'schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'schedules',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
