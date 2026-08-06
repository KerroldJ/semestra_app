import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/budget/domain/entities/expense_entity.dart';
import 'package:semestra_app/features/budget/domain/repositories/expense_repository.dart';

class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseEntity>>> {
  final ExpenseRepository _repository;

  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getExpenses();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExpense({
    required String category,
    required double amount,
    required DateTime date,
    required String description,
  }) async {
    final newExpense = ExpenseEntity(
      id: const Uuid().v4(),
      category: category,
      amount: amount,
      date: date,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveExpense(newExpense);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editExpense(ExpenseEntity expense) async {
    final updated = expense.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveExpense(updated);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final expenseNotifierProvider =
    StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseEntity>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repository);
});
