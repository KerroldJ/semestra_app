import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/daily_planner/domain/entities/daily_task_entity.dart';
import 'package:semestra_app/features/daily_planner/domain/repositories/daily_task_repository.dart';

class DailyTaskNotifier extends StateNotifier<AsyncValue<List<DailyTaskEntity>>> {
  final DailyTaskRepository _repository;

  DailyTaskNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getDailyTasks();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required int priority,
  }) async {
    final newTask = DailyTaskEntity(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      priority: priority,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveDailyTask(newTask);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editTask(DailyTaskEntity task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveDailyTask(updated);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleTaskCompletion(DailyTaskEntity task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.saveDailyTask(updated);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteDailyTask(id);
      await loadTasks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final dailyTaskNotifierProvider =
    StateNotifierProvider<DailyTaskNotifier, AsyncValue<List<DailyTaskEntity>>>((ref) {
  final repository = ref.watch(dailyTaskRepositoryProvider);
  return DailyTaskNotifier(repository);
});
