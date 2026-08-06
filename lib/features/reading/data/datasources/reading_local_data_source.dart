import '../../../../core/database/database_helper.dart';
import '../models/reading_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ReadingLocalDataSource {
  Future<List<ReadingModel>> getReadings();
  Future<void> saveReading(ReadingModel reading);
  Future<void> deleteReading(String id);
}

class ReadingLocalDataSourceImpl implements ReadingLocalDataSource {
  final DatabaseHelper _dbHelper;

  ReadingLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ReadingModel>> getReadings() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'readings',
      where: 'deleted_at IS NULL',
      orderBy: 'status ASC, title ASC',
    );
    return maps.map((m) => ReadingModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveReading(ReadingModel reading) async {
    final db = await _dbHelper.database;
    await db.insert(
      'readings',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteReading(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'readings',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
