import '../../domain/entities/semester_entity.dart';

class SemesterModel {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final int isActive;
  final int isArchived;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const SemesterModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SemesterModel.fromMap(Map<String, dynamic> map) {
    return SemesterModel(
      id: map['id'] as String,
      name: map['name'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String,
      isActive: map['is_active'] as int,
      isArchived: map['is_archived'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'is_archived': isArchived,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory SemesterModel.fromEntity(SemesterEntity entity) {
    return SemesterModel(
      id: entity.id,
      name: entity.name,
      startDate: entity.startDate.toIso8601String(),
      endDate: entity.endDate.toIso8601String(),
      isActive: entity.isActive ? 1 : 0,
      isArchived: entity.isArchived ? 1 : 0,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  SemesterEntity toEntity() {
    return SemesterEntity(
      id: id,
      name: name,
      startDate: DateTime.parse(startDate),
      endDate: DateTime.parse(endDate),
      isActive: isActive == 1,
      isArchived: isArchived == 1,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
