import '../../../../core/database/database_helper.dart';
import '../models/expense_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<void> saveExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final DatabaseHelper _dbHelper;

  ExpenseLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'deleted_at IS NULL',
      orderBy: 'date DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  @override
  Future<void> saveExpense(ExpenseModel expense) async {
    final db = await _dbHelper.database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'expenses',
      {'deleted_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
