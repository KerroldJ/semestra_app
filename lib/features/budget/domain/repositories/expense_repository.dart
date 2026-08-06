import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseEntity>> getExpenses();
  Future<void> saveExpense(ExpenseEntity expense);
  Future<void> deleteExpense(String id);
}
