import '../../../../core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

abstract class SettingsLocalDataSource {
  Future<Map<String, String>> getAllSettings();
  Future<void> saveSetting(String key, String value);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettingsLocalDataSourceImpl(this._dbHelper);

  @override
  Future<Map<String, String>> getAllSettings() async {
    final db = await _dbHelper.database;
    final maps = await db.query('settings');
    final result = <String, String>{};
    for (final row in maps) {
      final key = row['key'] as String;
      final value = row['value'] as String;
      result[key] = value;
    }
    return result;
  }

  @override
  Future<void> saveSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
