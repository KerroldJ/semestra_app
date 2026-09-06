import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('semestra.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      debugPrint('DBDIAG: opening db at "$path" (kIsWeb=$kIsWeb)');

      final db = await openDatabase(
        path,
        version: 6,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
      debugPrint('DBDIAG: db opened OK');
      return db;
    } catch (e, s) {
      debugPrint('DBDIAG: DB OPEN FAILED: $e');
      debugPrint('$s');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v5 -> v6 is purely additive: the semesters/subjects/schedules/items
    // schema is unchanged, we only add the `user_profile` table. Do the cheap,
    // non-destructive thing so real user data (subjects, items, schedules) is
    // never dropped on the way to the gated/onboarded build.
    if (oldVersion >= 5) {
      await _createUserProfileTable(db);
      return;
    }

    // Older databases: fold the three legacy "work item" tables into the
    // unified `items` table, then also snapshot the current-schema tables so a
    // full drop/recreate does not lose subjects/semesters/schedules.
    await _migrateLegacyItems(db);
    _preserved = {
      'semesters': await _safeQuery(db, 'semesters'),
      'subjects': await _safeQuery(db, 'subjects'),
      'schedules': await _safeQuery(db, 'schedules'),
    };

    // Drop all legacy / removed tables.
    await db.execute('DROP TABLE IF EXISTS settings');
    await db.execute('DROP TABLE IF EXISTS readings');
    await db.execute('DROP TABLE IF EXISTS expenses');
    await db.execute('DROP TABLE IF EXISTS grades');
    await db.execute('DROP TABLE IF EXISTS daily_tasks');
    await db.execute('DROP TABLE IF EXISTS study_sessions');
    await db.execute('DROP TABLE IF EXISTS exams');
    await db.execute('DROP TABLE IF EXISTS notes');
    await db.execute('DROP TABLE IF EXISTS assignments');
    await db.execute('DROP TABLE IF EXISTS schedules');
    await db.execute('DROP TABLE IF EXISTS subjects');
    await db.execute('DROP TABLE IF EXISTS semesters');
    await db.execute('DROP TABLE IF EXISTS workspace_items');

    // Recreate current schema (includes user_profile).
    await _createDB(db, newVersion);

    // Restore preserved + migrated rows.
    await _restorePreserved(db);
    await _restoreLegacyItems(db);
  }

  static Future<List<Map<String, dynamic>>> _safeQuery(
      Database db, String table) async {
    try {
      // Detach from the live cursor so the rows survive the table drop.
      return (await db.query(table))
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // Snapshots of current-schema tables held between drop and recreate.
  Map<String, List<Map<String, dynamic>>> _preserved = const {};

  Future<void> _restorePreserved(Database db) async {
    if (_preserved.isEmpty) return;
    try {
      await db.execute('PRAGMA foreign_keys = OFF');
      final batch = db.batch();
      // Insert parents before children (semesters -> subjects -> schedules).
      for (final table in const ['semesters', 'subjects', 'schedules']) {
        for (final row in _preserved[table] ?? const []) {
          batch.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await batch.commit(noResult: true);
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {
      // Non-fatal: app still runs with whatever restored.
    } finally {
      _preserved = const {};
    }
  }

  // Holds migrated rows between drop and recreate.
  List<Map<String, dynamic>> _migratedItems = const [];

  Future<void> _migrateLegacyItems(Database db) async {
    final migrated = <Map<String, dynamic>>[];

    Future<List<Map<String, dynamic>>> safeQuery(String table) async {
      try {
        return await db.query(table);
      } catch (_) {
        return const [];
      }
    }

    // Notes -> type 0
    for (final n in await safeQuery('notes')) {
      migrated.add({
        'id': n['id'],
        'type': 0,
        'subject_id': n['subject_id'],
        'title': n['title'] ?? '',
        'content': n['content'] ?? '',
        'notes': '',
        'tags': n['tags'] ?? '',
        'due_date': null,
        'priority': 0,
        'status': 0,
        'created_at': n['created_at'],
        'updated_at': n['updated_at'],
        'deleted_at': n['deleted_at'],
      });
    }

    // Daily tasks -> type 1
    for (final t in await safeQuery('daily_tasks')) {
      migrated.add({
        'id': t['id'],
        'type': 1,
        'subject_id': null,
        'title': t['title'] ?? '',
        'content': t['description'] ?? '',
        'notes': '',
        'tags': '',
        'due_date': t['due_date'],
        'priority': t['priority'] ?? 0,
        'status': ((t['is_completed'] ?? 0) == 1) ? 2 : 0,
        'created_at': t['created_at'],
        'updated_at': t['updated_at'],
        'deleted_at': t['deleted_at'],
      });
    }

    // Assignments -> type 2
    for (final a in await safeQuery('assignments')) {
      migrated.add({
        'id': a['id'],
        'type': 2,
        'subject_id': a['subject_id'],
        'title': a['title'] ?? '',
        'content': a['description'] ?? '',
        'notes': a['notes'] ?? '',
        'tags': '',
        'due_date': a['due_date'],
        'priority': a['priority'] ?? 0,
        'status': a['status'] ?? 0,
        'created_at': a['created_at'],
        'updated_at': a['updated_at'],
        'deleted_at': a['deleted_at'],
      });
    }

    _migratedItems = migrated;
  }

  Future<void> _restoreLegacyItems(Database db) async {
    if (_migratedItems.isEmpty) return;
    try {
      // Foreign keys off during bulk restore to avoid subject-ordering issues.
      await db.execute('PRAGMA foreign_keys = OFF');
      final batch = db.batch();
      for (final row in _migratedItems) {
        batch.insert('items', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {
      // If restore fails the app still works with an empty items table.
    } finally {
      _migratedItems = const [];
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Semesters table
    await db.execute('''
      CREATE TABLE semesters (
        id $idType,
        name $textType,
        start_date $textType,
        end_date $textType,
        is_active $integerType,
        is_archived $integerType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType
      )
    ''');

    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id $idType,
        semester_id $textType,
        code $textType,
        name $textType,
        instructor $textType,
        classroom $textType,
        units $realType,
        color $integerType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (semester_id) REFERENCES semesters (id) ON DELETE CASCADE
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id $idType,
        subject_id $textType,
        day_of_week $integerType,
        start_time $textType,
        end_time $textType,
        classroom $textType,
        instructor $textType,
        type $integerType DEFAULT 0,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Unified items table (notes = 0, tasks = 1, assignments = 2)
    await db.execute('''
      CREATE TABLE items (
        id $idType,
        type $integerType,
        subject_id $textNullableType,
        title $textType,
        content $textType,
        notes $textType,
        tags $textType,
        due_date $textNullableType,
        priority $integerType,
        status $integerType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Default settings
    await db.insert('settings', {'key': 'theme_mode', 'value': 'light'});
    await db.insert('settings', {'key': 'notifications_enabled', 'value': 'true'});

    // Single-row local user profile (the sign-in gate).
    await _createUserProfileTable(db);
  }

  /// The local identity row created after Google sign-in. Single row, keyed by
  /// the Google account id. Created on fresh installs and added on the v5->v6
  /// upgrade. Idempotent.
  Future<void> _createUserProfileTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profile (
        google_id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        display_name TEXT NOT NULL,
        photo_url TEXT,
        username TEXT,
        onboarded_at TEXT
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
