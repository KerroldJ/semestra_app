import '../../domain/entities/daily_task_entity.dart';
import '../../domain/repositories/daily_task_repository.dart';
import '../datasources/daily_task_local_data_source.dart';
import '../models/daily_task_model.dart';

class DailyTaskRepositoryImpl implements DailyTaskRepository {
  final DailyTaskLocalDataSource localDataSource;

  DailyTaskRepositoryImpl(this.localDataSource);

  @override
  Future<List<DailyTaskEntity>> getDailyTasks() async {
    final models = await localDataSource.getDailyTasks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveDailyTask(DailyTaskEntity task) async {
    final model = DailyTaskModel.fromEntity(task);
    await localDataSource.saveDailyTask(model);
  }

  @override
  Future<void> deleteDailyTask(String id) async {
    await localDataSource.deleteDailyTask(id);
  }
}
