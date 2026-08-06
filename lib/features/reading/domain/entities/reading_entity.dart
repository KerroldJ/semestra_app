import '../../../../shared/domain/entities/base_entity.dart';

class ReadingEntity extends BaseEntity {
  final String title;
  final String author;
  final String? filePath;
  final int format; // 0 = Book, 1 = PDF, 2 = Research Material
  final int totalPages;
  final int currentPage;
  final int status; // 0 = To Read, 1 = Reading, 2 = Completed
  final String notes;

  const ReadingEntity({
    required super.id,
    required this.title,
    required this.author,
    this.filePath,
    required this.format,
    required this.totalPages,
    required this.currentPage,
    required this.status,
    required this.notes,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  double get progressPercentage => totalPages > 0 ? (currentPage / totalPages) * 100 : 0.0;

  ReadingEntity copyWith({
    String? title,
    String? author,
    String? filePath,
    int? format,
    int? totalPages,
    int? currentPage,
    int? status,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ReadingEntity(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
