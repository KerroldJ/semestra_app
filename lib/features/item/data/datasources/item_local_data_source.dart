import '../../../../core/database/database_helper.dart';
import '../models/item_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ItemLocalDataSource {
  Future<List<ItemModel>> getItems();
  Future<List<ItemModel>> getItemsByType(int type);
  Future<ItemModel?> getItemById(String id);
  Future<void> saveItem(ItemModel item);
  Future<void> deleteItem(String id);
}

class ItemLocalDataSourceImpl implements ItemLocalDataSource {
  final DatabaseHelper _dbHelper;

  ItemLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ItemModel>> getItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'items',
      where: 'deleted_at IS NULL',
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => ItemModel.fromMap(m)).toList();
  }

  @override
  Future<List<ItemModel>> getItemsByType(int type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'items',
      where: 'type = ? AND deleted_at IS NULL',
      whereArgs: [type],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => ItemModel.fromMap(m)).toList();
  }

  @override
  Future<ItemModel?> getItemById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'items',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ItemModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> saveItem(ItemModel item) async {
    final db = await _dbHelper.database;
    await db.insert(
      'items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'items',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
