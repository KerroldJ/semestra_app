import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../domain/entities/user_profile.dart';

/// Persists the single-row local profile in `user_profile`.
abstract class UserProfileLocalDataSource {
  Future<UserProfile?> getProfile();
  Future<void> saveProfile(UserProfile profile);
  Future<void> clear();
}

class UserProfileLocalDataSourceImpl implements UserProfileLocalDataSource {
  final DatabaseHelper _dbHelper;

  UserProfileLocalDataSourceImpl(this._dbHelper);

  @override
  Future<UserProfile?> getProfile() async {
    final db = await _dbHelper.database;
    final rows = await db.query('user_profile', limit: 1);
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final db = await _dbHelper.database;
    // Single-row table: clear then insert so a re-sign-in with a different
    // account never leaves two identities behind.
    await db.delete('user_profile');
    await db.insert(
      'user_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('user_profile');
  }
}
