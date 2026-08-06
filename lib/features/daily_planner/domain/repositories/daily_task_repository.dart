import '../entities/daily_task_entity.dart';

abstract class DailyTaskRepository {
  Future<List<DailyTaskEntity>> getDailyTasks();
  Future<void> saveDailyTask(DailyTaskEntity task);
  Future<void> deleteDailyTask(String id);
}
