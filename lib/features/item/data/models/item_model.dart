import '../../domain/entities/item_entity.dart';

class ItemModel {
  final String id;
  final int type;
  final String? subjectId;
  final String title;
  final String content;
  final String notes;
  final String tags; // Comma-separated
  final String? dueDate;
  final int priority;
  final int status;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ItemModel({
    required this.id,
    required this.type,
    this.subjectId,
    required this.title,
    required this.content,
    required this.notes,
    required this.tags,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as String,
      type: map['type'] as int,
      subjectId: map['subject_id'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      notes: map['notes'] as String,
      tags: map['tags'] as String,
      dueDate: map['due_date'] as String?,
      priority: map['priority'] as int,
      status: map['status'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'subject_id': subjectId,
      'title': title,
      'content': content,
      'notes': notes,
      'tags': tags,
      'due_date': dueDate,
      'priority': priority,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ItemModel.fromEntity(ItemEntity entity) {
    return ItemModel(
      id: entity.id,
      type: entity.type.value,
      subjectId: entity.subjectId,
      title: entity.title,
      content: entity.content,
      notes: entity.notes,
      tags: entity.tags.join(','),
      dueDate: entity.dueDate?.toIso8601String(),
      priority: entity.priority,
      status: entity.status,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ItemEntity toEntity() {
    final tagList = tags.isEmpty
        ? <String>[]
        : tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    return ItemEntity(
      id: id,
      type: ItemType.fromValue(type),
      subjectId: subjectId,
      title: title,
      content: content,
      notes: notes,
      tags: tagList,
      dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
      priority: priority,
      status: status,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
