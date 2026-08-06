import '../../domain/entities/exam_entity.dart';

class ExamModel {
  final String id;
  final String subjectId;
  final String title;
  final String scheduledDate;
  final String coverage;
  final String notes;
  final int type;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ExamModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.scheduledDate,
    required this.coverage,
    required this.notes,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      title: map['title'] as String,
      scheduledDate: map['scheduled_date'] as String,
      coverage: map['coverage'] as String,
      notes: map['notes'] as String,
      type: map['type'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'scheduled_date': scheduledDate,
      'coverage': coverage,
      'notes': notes,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ExamModel.fromEntity(ExamEntity entity) {
    return ExamModel(
      id: entity.id,
      subjectId: entity.subjectId,
      title: entity.title,
      scheduledDate: entity.scheduledDate.toIso8601String(),
      coverage: entity.coverage,
      notes: entity.notes,
      type: entity.type,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ExamEntity toEntity() {
    return ExamEntity(
      id: id,
      subjectId: subjectId,
      title: title,
      scheduledDate: DateTime.parse(scheduledDate),
      coverage: coverage,
      notes: notes,
      type: type,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
