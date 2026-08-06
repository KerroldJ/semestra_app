import '../../domain/entities/note_entity.dart';

class NoteModel {
  final String id;
  final String subjectId;
  final String title;
  final String content;
  final String tags; // Comma-separated tags
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const NoteModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: map['tags'] as String,
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
      'content': content,
      'tags': tags,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      subjectId: entity.subjectId,
      title: entity.title,
      content: entity.content,
      tags: entity.tags.join(','),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  NoteEntity toEntity() {
    final tagList = tags.isEmpty ? <String>[] : tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    return NoteEntity(
      id: id,
      subjectId: subjectId,
      title: title,
      content: content,
      tags: tagList,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
