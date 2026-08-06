import '../../../../shared/domain/entities/base_entity.dart';

class ExamEntity extends BaseEntity {
  final String subjectId;
  final String title;
  final DateTime scheduledDate;
  final String coverage;
  final String notes;
  final int type; // 0 = Quiz, 1 = Exam, 2 = Presentation, 3 = Project

  const ExamEntity({
    required super.id,
    required this.subjectId,
    required this.title,
    required this.scheduledDate,
    required this.coverage,
    required this.notes,
    required this.type,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  ExamEntity copyWith({
    String? subjectId,
    String? title,
    DateTime? scheduledDate,
    String? coverage,
    String? notes,
    int? type,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ExamEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      coverage: coverage ?? this.coverage,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
