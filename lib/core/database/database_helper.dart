import 'dart:async';
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Drop all tables
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
    
    // Recreate
    await _createDB(db, newVersion);
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
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Assignments table
    await db.execute('''
      CREATE TABLE assignments (
        id $idType,
        subject_id $textType,
        title $textType,
        description $textType,
        due_date $textType,
        priority $integerType,
        status $integerType,
        notes $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id $idType,
        subject_id $textType,
        title $textType,
        content $textType,
        tags $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Exams table
    await db.execute('''
      CREATE TABLE exams (
        id $idType,
        subject_id $textType,
        title $textType,
        scheduled_date $textType,
        coverage $textType,
        notes $textType,
        type $integerType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Study sessions table
    await db.execute('''
      CREATE TABLE study_sessions (
        id $idType,
        subject_id $textNullableType,
        duration_seconds $integerType,
        session_type $integerType,
        completed_at $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType
      )
    ''');

    // Daily tasks table
    await db.execute('''
      CREATE TABLE daily_tasks (
        id $idType,
        title $textType,
        description $textType,
        due_date $textType,
        is_completed $integerType,
        priority $integerType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType
      )
    ''');

    // Grades table
    await db.execute('''
      CREATE TABLE grades (
        id $idType,
        subject_id $textType,
        assessment_name $textType,
        weight $realType,
        score_obtained $realType,
        score_max $realType,
        grade_letter $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        category $textType,
        amount $realType,
        date $textType,
        description $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType
      )
    ''');

    // Readings table
    await db.execute('''
      CREATE TABLE readings (
        id $idType,
        title $textType,
        author $textType,
        file_path $textNullableType,
        format $integerType,
        total_pages $integerType,
        current_page $integerType,
        status $integerType,
        notes $textType,
        created_at $textType,
        updated_at $textType,
        deleted_at $textNullableType
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
    await db.insert('settings', {'key': 'theme_mode', 'value': 'dark'});
    await db.insert('settings', {'key': 'notifications_enabled', 'value': 'true'});
    await db.insert('settings', {'key': 'pomodoro_focus_duration', 'value': '25'});
    await db.insert('settings', {'key': 'pomodoro_short_break', 'value': '5'});
    await db.insert('settings', {'key': 'pomodoro_long_break', 'value': '15'});
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
