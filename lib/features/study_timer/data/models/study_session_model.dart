import '../../domain/entities/study_session_entity.dart';

class StudySessionModel {
  final String id;
  final String? subjectId;
  final int durationSeconds;
  final int sessionType;
  final String completedAt;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const StudySessionModel({
    required this.id,
    this.subjectId,
    required this.durationSeconds,
    required this.sessionType,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory StudySessionModel.fromMap(Map<String, dynamic> map) {
    return StudySessionModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String?,
      durationSeconds: map['duration_seconds'] as int,
      sessionType: map['session_type'] as int,
      completedAt: map['completed_at'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'duration_seconds': durationSeconds,
      'session_type': sessionType,
      'completed_at': completedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory StudySessionModel.fromEntity(StudySessionEntity entity) {
    return StudySessionModel(
      id: entity.id,
      subjectId: entity.subjectId,
      durationSeconds: entity.durationSeconds,
      sessionType: entity.sessionType,
      completedAt: entity.completedAt.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  StudySessionEntity toEntity() {
    return StudySessionEntity(
      id: id,
      subjectId: subjectId,
      durationSeconds: durationSeconds,
      sessionType: sessionType,
      completedAt: DateTime.parse(completedAt),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
