import '../../../../shared/domain/entities/base_entity.dart';

/// The kind of work item. Backed by an int in the database.
enum ItemType {
  note, // 0
  task, // 1
  assignment; // 2

  int get value => index;

  static ItemType fromValue(int value) {
    switch (value) {
      case 1:
        return ItemType.task;
      case 2:
        return ItemType.assignment;
      default:
        return ItemType.note;
    }
  }
}

/// Unified entity covering Notes, Tasks and Assignments.
///
/// Field usage by type:
/// - note:        subjectId, title, content (markdown), tags
/// - task:        title, content (=description), dueDate, priority, status(0/2)
/// - assignment:  subjectId, title, content (=description), notes, dueDate,
///                priority, status(0/1/2)
class ItemEntity extends BaseEntity {
  final ItemType type;
  final String? subjectId;
  final String title;
  final String content;
  final String notes;
  final List<String> tags;
  final DateTime? dueDate;
  final int priority; // 0 = Low, 1 = Medium, 2 = High
  final int status; // 0 = Not Started, 1 = In Progress, 2 = Completed/Done

  const ItemEntity({
    required super.id,
    required this.type,
    this.subjectId,
    required this.title,
    required this.content,
    this.notes = '',
    this.tags = const [],
    this.dueDate,
    this.priority = 0,
    this.status = 0,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  bool get isCompleted => status == 2;

  ItemEntity copyWith({
    ItemType? type,
    String? subjectId,
    String? title,
    String? content,
    String? notes,
    List<String>? tags,
    DateTime? dueDate,
    int? priority,
    int? status,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ItemEntity(
      id: id,
      type: type ?? this.type,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      content: content ?? this.content,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
