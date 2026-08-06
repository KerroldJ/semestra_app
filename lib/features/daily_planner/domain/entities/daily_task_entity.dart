import '../../../../shared/domain/entities/base_entity.dart';

class DailyTaskEntity extends BaseEntity {
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final int priority; // 0 = Low, 1 = Medium, 2 = High

  const DailyTaskEntity({
    required super.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.priority,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  DailyTaskEntity copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    int? priority,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return DailyTaskEntity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
