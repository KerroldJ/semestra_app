import 'package:flutter/material.dart';
import '../../../../shared/domain/entities/base_entity.dart';

/// ResourceEntity represents an uploaded file resource attached to a specific subject.
/// Supported file types: PPT, PDF, Excel, CSV, Docs.
/// (Images are strictly disallowed).
class ResourceEntity extends BaseEntity {
  final String subjectId;
  final String title;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String notes;

  const ResourceEntity({
    required super.id,
    required this.subjectId,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.notes = '',
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  String get extension => fileType.toLowerCase().replaceAll('.', '');

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get categoryLabel {
    final ext = extension;
    switch (ext) {
      case 'pdf':
        return 'PDF';
      case 'ppt':
      case 'pptx':
        return 'Presentation';
      case 'xls':
      case 'xlsx':
        return 'Spreadsheet';
      case 'csv':
        return 'CSV Data';
      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
      case 'txt':
        return 'Document';
      default:
        return 'Document';
    }
  }

  IconData get icon {
    final ext = extension;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
      case 'txt':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color get categoryColor {
    final ext = extension;
    switch (ext) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFE65100);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF2E7D32);
      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
      case 'txt':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF0A7D43);
    }
  }

  ResourceEntity copyWith({
    String? subjectId,
    String? title,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? notes,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ResourceEntity(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
