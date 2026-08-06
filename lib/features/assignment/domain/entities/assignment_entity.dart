import '../../../../shared/domain/entities/base_entity.dart';

class AssignmentEntity extends BaseEntity {
  final String subjectId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int priority; // 0 = Low, 1 = Medium, 2 = High
  final int status; // 0 = Not Started, 1 = In Progress, 2 = Completed
  final String notes;

  const AssignmentEntity({
    required super.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.notes,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  AssignmentEntity copyWith({
    String? subjectId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
    int? status,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return AssignmentEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
