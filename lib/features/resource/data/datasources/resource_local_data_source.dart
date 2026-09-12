import '../../../../core/database/database_helper.dart';
import '../models/resource_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ResourceLocalDataSource {
  Future<List<ResourceModel>> getResources({String? subjectId});
  Future<ResourceModel?> getResourceById(String id);
  Future<void> saveResource(ResourceModel resource);
  Future<void> deleteResource(String id);
}

class ResourceLocalDataSourceImpl implements ResourceLocalDataSource {
  final DatabaseHelper _dbHelper;

  ResourceLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ResourceModel>> getResources({String? subjectId}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps;
    if (subjectId != null && subjectId.isNotEmpty) {
      maps = await db.query(
        'resources',
        where: 'subject_id = ? AND deleted_at IS NULL',
        whereArgs: [subjectId],
        orderBy: 'created_at DESC',
      );
    } else {
      maps = await db.query(
        'resources',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
    }
    return maps.map((m) => ResourceModel.fromMap(m)).toList();
  }

  @override
  Future<ResourceModel?> getResourceById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'resources',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ResourceModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveResource(ResourceModel resource) async {
    final db = await _dbHelper.database;
    await db.insert(
      'resources',
      resource.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteResource(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'resources',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
