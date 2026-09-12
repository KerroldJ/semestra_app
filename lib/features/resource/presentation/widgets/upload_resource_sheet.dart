import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../providers/resource_provider.dart';

const List<String> kAllowedResourceExtensions = [
  'pdf',
  'ppt',
  'pptx',
  'xls',
  'xlsx',
  'csv',
  'doc',
  'docx',
  'txt',
  'rtf',
  'odt',
];

const List<String> kDisallowedImageExtensions = [
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'svg',
  'bmp',
  'heic',
  'heif',
  'ico',
  'tiff',
  'tif',
  'raw',
  'psd',
  'ai',
];

Future<void> showUploadResourceSheet(
  BuildContext context, {
  String? defaultSubjectId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _UploadResourceSheet(defaultSubjectId: defaultSubjectId),
  );
}

class _UploadResourceSheet extends ConsumerStatefulWidget {
  final String? defaultSubjectId;
  const _UploadResourceSheet({this.defaultSubjectId});

  @override
  ConsumerState<_UploadResourceSheet> createState() =>
      _UploadResourceSheetState();
}

class _UploadResourceSheetState extends ConsumerState<_UploadResourceSheet> {
  String? _selectedSubjectId;
  PlatformFile? _pickedFile;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectId = widget.defaultSubjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedResourceExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final ext = (file.extension ?? '').toLowerCase().replaceAll('.', '');

      if (kDisallowedImageExtensions.contains(ext)) {
        AppToast.error('Images are not allowed. Please upload PPT, PDF, Excel, CSV, or Docs.');
        return;
      }

      if (!kAllowedResourceExtensions.contains(ext)) {
        AppToast.error('File type .$ext is not supported. Supported: PPT, PDF, Excel, CSV, Docs.');
        return;
      }

      setState(() {
        _pickedFile = file;
        if (_titleController.text.trim().isEmpty) {
          // Set initial title from file name without extension
          final name = file.name;
          final dotIndex = name.lastIndexOf('.');
          _titleController.text =
              dotIndex != -1 ? name.substring(0, dotIndex) : name;
        }
      });
    } on MissingPluginException {
      AppToast.error('Please stop and restart the app to enable file picking.');
    } on PlatformException catch (e) {
      if (e.code.contains('MissingPluginException') ||
          e.message?.contains('No implementation found') == true) {
        AppToast.error('Please restart the app to enable the file picker plugin.');
      } else {
        AppToast.error('File picker error: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('No implementation found')) {
        AppToast.error('Please restart the app to enable the file picker plugin.');
      } else {
        AppToast.error('Error picking file: $e');
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _iconForExt(String ext) {
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

  Color _colorForExt(String ext) {
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

  Future<void> _handleSave() async {
    if (_selectedSubjectId == null || _selectedSubjectId!.isEmpty) {
      AppToast.error('Please select a subject');
      return;
    }

    if (_pickedFile == null || _pickedFile!.path == null) {
      AppToast.error('Please select a file to upload');
      return;
    }

    final sourcePath = _pickedFile!.path!;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      AppToast.error('Selected file not found on device');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final resourcesDir = Directory('${appDir.path}/subject_resources');
      if (!await resourcesDir.exists()) {
        await resourcesDir.create(recursive: true);
      }

      final ext = (_pickedFile!.extension ?? '').toLowerCase().replaceAll('.', '');
      final uniqueFileName = '${const Uuid().v4()}_${_pickedFile!.name}';
      final targetPath = '${resourcesDir.path}/$uniqueFileName';

      await sourceFile.copy(targetPath);

      final success = await ref
          .read(resourceNotifierProvider.notifier)
          .addResource(
            subjectId: _selectedSubjectId!,
            title: _titleController.text.trim().isEmpty
                ? _pickedFile!.name
                : _titleController.text.trim(),
            fileName: _pickedFile!.name,
            filePath: targetPath,
            fileType: ext,
            fileSize: _pickedFile!.size,
            notes: _notesController.text.trim(),
          );

      if (mounted && success) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      AppToast.error('Failed to save file: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    final brandFill = AppTheme.brandFill(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : AppTheme.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: brandFill.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : AppTheme.inkFaint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.soft(brandFill, 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.folder_open_rounded,
                          color: AppTheme.accent(context),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Resource',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'PPT, PDF, Excel, CSV, or Docs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.white60 : AppTheme.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? Colors.white70 : AppTheme.inkMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Subject Selector
                  Text(
                    'SUBJECT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (subjects.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text('No subjects found. Please create a subject first.'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2622) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.hairlineBorder(context),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubjectId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          items: subjects.map((SubjectEntity s) {
                            final spine = AppTheme.spineFor(s.colorValue);
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: spine,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${s.code.isNotEmpty ? "${s.code} - " : ""}${s.name}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSubjectId = val),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // File Picker Section
                  Text(
                    'FILE ATTACHMENT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_pickedFile == null)
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF16231D)
                              : const Color(0xFFF3FAF6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: brandFill.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: brandFill.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 32,
                                color: AppTheme.accent(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to select a document',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: isDark ? Colors.white : AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PDF, PPT, PPTX, XLS, XLSX, CSV, DOC, DOCX, TXT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : AppTheme.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Note: Images are not allowed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // File preview card
                    Builder(
                      builder: (_) {
                        final ext = (_pickedFile!.extension ?? '').toLowerCase();
                        final color = _colorForExt(ext);
                        final icon = _iconForExt(ext);
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2720) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedFile!.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : AppTheme.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${ext.toUpperCase()} • ${_formatBytes(_pickedFile!.size)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : AppTheme.inkMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickFile,
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Title (Optional override)
                  Text(
                    'TITLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Midterm Lecture Slides',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2622) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.hairlineBorder(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.hairlineBorder(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: brandFill, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Notes / Description
                  Text(
                    'NOTES (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add remarks or topic keywords...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E2622) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.hairlineBorder(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.hairlineBorder(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: brandFill, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandFill(context),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Upload Resource',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
