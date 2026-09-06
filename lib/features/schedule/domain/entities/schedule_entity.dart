import '../../../../shared/domain/entities/base_entity.dart';

/// Kind of timetable block. Backed by an int in the database.
enum ScheduleType {
  classSession, // 0
  lab, // 1
  study; // 2

  int get value => index;

  static ScheduleType fromValue(int value) {
    switch (value) {
      case 1:
        return ScheduleType.lab;
      case 2:
        return ScheduleType.study;
      default:
        return ScheduleType.classSession;
    }
  }

  String get label {
    switch (this) {
      case ScheduleType.classSession:
        return 'CLASS';
      case ScheduleType.lab:
        return 'LAB';
      case ScheduleType.study:
        return 'STUDY';
    }
  }
}

class ScheduleEntity extends BaseEntity {
  final String subjectId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String classroom;
  final String instructor;
  final int type; // 0 = class, 1 = lab, 2 = study

  const ScheduleEntity({
    required super.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.classroom,
    required this.instructor,
    this.type = 0,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  ScheduleType get scheduleType => ScheduleType.fromValue(type);

  ScheduleEntity copyWith({
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? classroom,
    String? instructor,
    int? type,
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
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
