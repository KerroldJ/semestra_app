import '../../../../shared/domain/entities/base_entity.dart';

class StudySessionEntity extends BaseEntity {
  final String? subjectId;
  final int durationSeconds;
  final int sessionType; // 0 = Focus, 1 = Short Break, 2 = Long Break
  final DateTime completedAt;

  const StudySessionEntity({
    required super.id,
    this.subjectId,
    required this.durationSeconds,
    required this.sessionType,
    required this.completedAt,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  StudySessionEntity copyWith({
    String? subjectId,
    int? durationSeconds,
    int? sessionType,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return StudySessionEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sessionType: sessionType ?? this.sessionType,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
