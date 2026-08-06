import '../../../../shared/domain/entities/base_entity.dart';

class GradeEntity extends BaseEntity {
  final String subjectId;
  final String assessmentName;
  final double weight; // Percentage weight, e.g. 20.0 for 20%
  final double scoreObtained;
  final double scoreMax;
  final String gradeLetter;

  const GradeEntity({
    required super.id,
    required this.subjectId,
    required this.assessmentName,
    required this.weight,
    required this.scoreObtained,
    required this.scoreMax,
    required this.gradeLetter,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  double get percentage => scoreMax > 0 ? (scoreObtained / scoreMax) * 100 : 0.0;
  double get weightedScore => scoreMax > 0 ? (scoreObtained / scoreMax) * weight : 0.0;

  GradeEntity copyWith({
    String? subjectId,
    String? assessmentName,
    double? weight,
    double? scoreObtained,
    double? scoreMax,
    String? gradeLetter,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return GradeEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      assessmentName: assessmentName ?? this.assessmentName,
      weight: weight ?? this.weight,
      scoreObtained: scoreObtained ?? this.scoreObtained,
      scoreMax: scoreMax ?? this.scoreMax,
      gradeLetter: gradeLetter ?? this.gradeLetter,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
