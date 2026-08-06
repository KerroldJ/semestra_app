import '../../domain/entities/assignment_entity.dart';

class AssignmentModel {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String dueDate;
  final int priority;
  final int status;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const AssignmentModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: map['due_date'] as String,
      priority: map['priority'] as int,
      status: map['status'] as int,
      notes: map['notes'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory AssignmentModel.fromEntity(AssignmentEntity entity) {
    return AssignmentModel(
      id: entity.id,
      subjectId: entity.subjectId,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate.toIso8601String(),
      priority: entity.priority,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  AssignmentEntity toEntity() {
    return AssignmentEntity(
      id: id,
      subjectId: subjectId,
      title: title,
      description: description,
      dueDate: DateTime.parse(dueDate),
      priority: priority,
      status: status,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
