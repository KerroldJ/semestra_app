import '../../../../shared/domain/entities/base_entity.dart';

class NoteEntity extends BaseEntity {
  final String subjectId;
  final String title;
  final String content; // Supports Markdown, tables, checklists, images, code snippets
  final List<String> tags;

  const NoteEntity({
    required super.id,
    required this.subjectId,
    required this.title,
    required this.content,
    required this.tags,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  NoteEntity copyWith({
    String? subjectId,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return NoteEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
