import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_local_data_source.dart';
import '../models/schedule_model.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleLocalDataSource localDataSource;

  ScheduleRepositoryImpl(this.localDataSource);

  @override
  Future<List<ScheduleEntity>> getSchedules() async {
    final models = await localDataSource.getSchedules();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ScheduleEntity>> getSchedulesBySubject(String subjectId) async {
    final models = await localDataSource.getSchedulesBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveSchedule(ScheduleEntity schedule) async {
    final model = ScheduleModel.fromEntity(schedule);
    await localDataSource.saveSchedule(model);
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await localDataSource.deleteSchedule(id);
  }
}
