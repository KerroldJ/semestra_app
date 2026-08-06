import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'database_helper.dart';

class DatabaseBackupService {
  static final List<String> _tables = [
    'semesters',
    'subjects',
    'schedules',
    'assignments',
    'notes',
    'exams',
    'study_sessions',
    'daily_tasks',
    'grades',
    'expenses',
    'readings',
    'settings'
  ];

  /// Exports all database tables to a JSON string and writes to a file in documents directory
  static Future<String> exportBackup() async {
    final db = await DatabaseHelper.instance.database;
    final backupData = <String, List<Map<String, dynamic>>>{};

    for (final table in _tables) {
      final rows = await db.query(table);
      backupData[table] = rows;
    }

    final jsonString = jsonEncode(backupData);
    final directory = await getApplicationDocumentsDirectory();
    final backupFile = File('${directory.path}/semestra_backup.json');
    await backupFile.writeAsString(jsonString);

    return backupFile.path;
  }

  /// Restores the database from a JSON file path
  static Future<bool> restoreBackupFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final jsonString = await file.readAsString();
    return await restoreBackupFromJson(jsonString);
  }

  /// Restores the database from a JSON string
  static Future<bool> restoreBackupFromJson(String jsonString) async {
    try {
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // Disable foreign keys temporarily during restore to avoid ordering constraints
        await txn.execute('PRAGMA foreign_keys = OFF');

        for (final table in _tables) {
          await txn.delete(table);
          final rows = backupData[table];
          if (rows != null && rows is List) {
            for (final row in rows) {
              if (row is Map<String, dynamic>) {
                await txn.insert(table, row);
              }
            }
          }
        }

        await txn.execute('PRAGMA foreign_keys = ON');
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
