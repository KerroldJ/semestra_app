import '../../../../shared/domain/entities/base_entity.dart';

class SemesterEntity extends BaseEntity {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isArchived;

  const SemesterEntity({
    required super.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isArchived,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  SemesterEntity copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return SemesterEntity(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
