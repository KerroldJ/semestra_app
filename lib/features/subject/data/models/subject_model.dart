import '../../domain/entities/subject_entity.dart';

class SubjectModel {
  final String id;
  final String semesterId;
  final String code;
  final String name;
  final String instructor;
  final String classroom;
  final double units;
  final int color;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const SubjectModel({
    required this.id,
    required this.semesterId,
    required this.code,
    required this.name,
    required this.instructor,
    required this.classroom,
    required this.units,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as String,
      semesterId: map['semester_id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      instructor: map['instructor'] as String,
      classroom: map['classroom'] as String,
      units: (map['units'] as num).toDouble(),
      color: map['color'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester_id': semesterId,
      'code': code,
      'name': name,
      'instructor': instructor,
      'classroom': classroom,
      'units': units,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory SubjectModel.fromEntity(SubjectEntity entity) {
    return SubjectModel(
      id: entity.id,
      semesterId: entity.semesterId,
      code: entity.code,
      name: entity.name,
      instructor: entity.instructor,
      classroom: entity.classroom,
      units: entity.units,
      color: entity.colorValue,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  SubjectEntity toEntity() {
    return SubjectEntity(
      id: id,
      semesterId: semesterId,
      code: code,
      name: name,
      instructor: instructor,
      classroom: classroom,
      units: units,
      colorValue: color,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
