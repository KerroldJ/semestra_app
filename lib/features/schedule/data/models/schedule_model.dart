import '../../domain/entities/schedule_entity.dart';

class ScheduleModel {
  final String id;
  final String subjectId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String classroom;
  final String instructor;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ScheduleModel({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.instructor,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      classroom: map['classroom'] as String,
      instructor: map['instructor'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'classroom': classroom,
      'instructor': instructor,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ScheduleModel.fromEntity(ScheduleEntity entity) {
    return ScheduleModel(
      id: entity.id,
      subjectId: entity.subjectId,
      dayOfWeek: entity.dayOfWeek,
      startTime: entity.startTime,
      endTime: entity.endTime,
      classroom: entity.classroom,
      instructor: entity.instructor,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ScheduleEntity toEntity() {
    return ScheduleEntity(
      id: id,
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      classroom: classroom,
      instructor: instructor,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
