import '../../../../shared/domain/entities/base_entity.dart';

class ScheduleEntity extends BaseEntity {
  final String subjectId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String classroom;
  final String instructor;

  const ScheduleEntity({
    required super.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.instructor,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  ScheduleEntity copyWith({
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    String? instructor,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ScheduleEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      classroom: classroom ?? this.classroom,
      instructor: instructor ?? this.instructor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
