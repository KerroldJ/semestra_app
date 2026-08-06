import '../../domain/entities/daily_task_entity.dart';

class DailyTaskModel {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final int isCompleted;
  final int priority;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const DailyTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory DailyTaskModel.fromMap(Map<String, dynamic> map) {
    return DailyTaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: map['due_date'] as String,
      isCompleted: map['is_completed'] as int,
      priority: map['priority'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'is_completed': isCompleted,
      'priority': priority,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory DailyTaskModel.fromEntity(DailyTaskEntity entity) {
    return DailyTaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate.toIso8601String(),
      isCompleted: entity.isCompleted ? 1 : 0,
      priority: entity.priority,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  DailyTaskEntity toEntity() {
    return DailyTaskEntity(
      id: id,
      title: title,
      description: description,
      dueDate: DateTime.parse(dueDate),
      isCompleted: isCompleted == 1,
      priority: priority,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
