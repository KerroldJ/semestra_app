import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl(this.localDataSource);

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    final models = await localDataSource.getExpenses();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveExpense(ExpenseEntity expense) async {
    final model = ExpenseModel.fromEntity(expense);
    await localDataSource.saveExpense(model);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await localDataSource.deleteExpense(id);
  }
}
