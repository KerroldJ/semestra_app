import '../../domain/entities/resource_entity.dart';

class ResourceModel {
  final String id;
  final String subjectId;
  final String title;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ResourceModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] as String,
      subjectId: map['subject_id'] as String,
      title: map['title'] as String,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      fileType: map['file_type'] as String,
      fileSize: map['file_size'] as int,
      notes: map['notes'] as String?,
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
      'file_name': fileName,
      'file_path': filePath,
      'file_type': fileType,
      'file_size': fileSize,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ResourceModel.fromEntity(ResourceEntity entity) {
    return ResourceModel(
      id: entity.id,
      subjectId: entity.subjectId,
      title: entity.title,
      fileName: entity.fileName,
      filePath: entity.filePath,
      fileType: entity.fileType,
      fileSize: entity.fileSize,
      notes: entity.notes.isEmpty ? null : entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ResourceEntity toEntity() {
    return ResourceEntity(
      id: id,
      subjectId: subjectId,
      title: title,
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      notes: notes ?? '',
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
