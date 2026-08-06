import '../../domain/entities/grade_entity.dart';

class GradeModel {
  final String id;
  final String subjectId;
  final String assessmentName;
  final double weight;
  final double scoreObtained;
  final double scoreMax;
  final String gradeLetter;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const GradeModel({
    required this.id,
    required this.subjectId,
    required this.assessmentName,
    required this.weight,
    required this.scoreObtained,
    required this.scoreMax,
    required this.gradeLetter,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      assessmentName: map['assessment_name'] as String,
      weight: (map['weight'] as num).toDouble(),
      scoreObtained: (map['score_obtained'] as num).toDouble(),
      scoreMax: (map['score_max'] as num).toDouble(),
      gradeLetter: map['grade_letter'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'assessment_name': assessmentName,
      'weight': weight,
      'score_obtained': scoreObtained,
      'score_max': scoreMax,
      'grade_letter': gradeLetter,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory GradeModel.fromEntity(GradeEntity entity) {
    return GradeModel(
      id: entity.id,
      subjectId: entity.subjectId,
      assessmentName: entity.assessmentName,
      weight: entity.weight,
      scoreObtained: entity.scoreObtained,
      scoreMax: entity.scoreMax,
      gradeLetter: entity.gradeLetter,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  GradeEntity toEntity() {
    return GradeEntity(
      id: id,
      subjectId: subjectId,
      assessmentName: assessmentName,
      weight: weight,
      scoreObtained: scoreObtained,
      scoreMax: scoreMax,
      gradeLetter: gradeLetter,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
