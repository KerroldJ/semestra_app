import '../../../../shared/domain/entities/base_entity.dart';

class SubjectEntity extends BaseEntity {
  final String semesterId;
  final String code;
  final String name;
  final String instructor;
  final String classroom;
  final double units;
  final int colorValue;

  const SubjectEntity({
    required super.id,
    required this.semesterId,
    required this.code,
    required this.name,
    required this.instructor,
    required this.classroom,
    required this.units,
    required this.colorValue,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  SubjectEntity copyWith({
    String? semesterId,
    String? code,
    String? name,
    String? instructor,
    String? classroom,
    double? units,
    int? colorValue,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SubjectEntity(
      id: id,
      semesterId: semesterId ?? this.semesterId,
      code: code ?? this.code,
      name: name ?? this.name,
      instructor: instructor ?? this.instructor,
      classroom: classroom ?? this.classroom,
      units: units ?? this.units,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
