import '../entities/schedule_entity.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleEntity>> getSchedules();
  Future<List<ScheduleEntity>> getSchedulesBySubject(String subjectId);
  Future<void> saveSchedule(ScheduleEntity schedule);
  Future<void> deleteSchedule(String id);
}
