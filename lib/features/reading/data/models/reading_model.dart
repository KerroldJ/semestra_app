import '../../domain/entities/reading_entity.dart';

class ReadingModel {
  final String id;
  final String title;
  final String author;
  final String? filePath;
  final int format;
  final int totalPages;
  final int currentPage;
  final int status;
  final String notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const ReadingModel({
    required this.id,
    required this.title,
    required this.author,
    this.filePath,
    required this.format,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ReadingModel.fromMap(Map<String, dynamic> map) {
    return ReadingModel(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      filePath: map['file_path'] as String?,
      format: map['format'] as int,
      totalPages: map['total_pages'] as int,
      currentPage: map['current_page'] as int,
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
      'title': title,
      'author': author,
      'file_path': filePath,
      'format': format,
      'total_pages': totalPages,
      'current_page': currentPage,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  factory ReadingModel.fromEntity(ReadingEntity entity) {
    return ReadingModel(
      id: entity.id,
      title: entity.title,
      author: entity.author,
      filePath: entity.filePath,
      format: entity.format,
      totalPages: entity.totalPages,
      currentPage: entity.currentPage,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: entity.deletedAt?.toIso8601String(),
    );
  }

  ReadingEntity toEntity() {
    return ReadingEntity(
      id: id,
      title: title,
      author: author,
      filePath: filePath,
      format: format,
      totalPages: totalPages,
      currentPage: currentPage,
      status: status,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }
}
