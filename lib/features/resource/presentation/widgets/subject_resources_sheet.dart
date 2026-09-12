import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../domain/entities/resource_entity.dart';
import '../providers/resource_provider.dart';
import 'upload_resource_sheet.dart';

Future<void> showSubjectResourcesSheet(
  BuildContext context, {
  required SubjectEntity subject,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _SubjectResourcesSheet(subject: subject),
  );
}

class _SubjectResourcesSheet extends ConsumerStatefulWidget {
  final SubjectEntity subject;
  const _SubjectResourcesSheet({required this.subject});

  @override
  ConsumerState<_SubjectResourcesSheet> createState() =>
      _SubjectResourcesSheetState();
}

class _SubjectResourcesSheetState
    extends ConsumerState<_SubjectResourcesSheet> {
  String _filterType = 'All';

  Future<void> _openFile(ResourceEntity resource) async {
    final file = File(resource.filePath);
    if (!await file.exists()) {
      AppToast.error('File no longer exists at ${resource.filePath}');
      return;
    }
    if (mounted) {
      context.push('/resource/viewer', extra: resource);
    }
  }

  void _confirmDelete(BuildContext context, ResourceEntity resource) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(resourceNotifierProvider.notifier).deleteResource(
                    resource.id,
                    filePath: resource.filePath,
                  );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allResources = ref.watch(resourceNotifierProvider).value ?? [];
    final subjectResources = allResources
        .where((r) => r.subjectId == widget.subject.id && !r.isDeleted)
        .toList();

    List<ResourceEntity> filtered = subjectResources;
    if (_filterType == 'PDF') {
      filtered = filtered.where((r) => r.extension == 'pdf').toList();
    } else if (_filterType == 'PPT') {
      filtered = filtered.where((r) => r.extension.startsWith('ppt')).toList();
    } else if (_filterType == 'Sheets') {
      filtered = filtered
          .where((r) => r.extension == 'xls' || r.extension == 'xlsx' || r.extension == 'csv')
          .toList();
    } else if (_filterType == 'Docs') {
      filtered = filtered
          .where((r) =>
              r.extension.startsWith('doc') ||
              r.extension == 'txt' ||
              r.extension == 'rtf' ||
              r.extension == 'odt')
          .toList();
    }

    final brandFill = AppTheme.brandFill(context);
    final spine = AppTheme.spineFor(widget.subject.colorValue);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
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
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: spine,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.subject.code.isNotEmpty ? "${widget.subject.code} • " : ""}Resources',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.subject.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : AppTheme.inkMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showUploadResourceSheet(
                        context,
                        defaultSubjectId: widget.subject.id,
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppTheme.accent(context),
                    tooltip: 'Upload new file',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? Colors.white70 : AppTheme.inkMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: ['All', 'PDF', 'PPT', 'Sheets', 'Docs'].map((category) {
                  final isSelected = _filterType == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filterType = category),
                      selectedColor: AppTheme.soft(brandFill, 0.18),
                      backgroundColor: isDark
                          ? const Color(0xFF1B2520)
                          : Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.accent(context)
                            : (isDark ? Colors.white70 : AppTheme.ink),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? brandFill
                              : AppTheme.hairlineBorder(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Content List
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.soft(brandFill, 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_open_rounded,
                                size: 36,
                                color: AppTheme.accent(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              subjectResources.isEmpty
                                  ? 'No resources uploaded yet'
                                  : 'No files match "$_filterType"',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Upload lecture slides, syllabus, readings, or sheets.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : AppTheme.inkMuted,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () {
                                showUploadResourceSheet(
                                  context,
                                  defaultSubjectId: widget.subject.id,
                                );
                              },
                              icon: const Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('Upload Resource'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandFill,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final resource = filtered[index];
                        final color = resource.categoryColor;

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2720) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.hairlineBorder(context),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openFile(resource),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // File icon badge
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      resource.icon,
                                      color: color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // File details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resource.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              resource.extension.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: color,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '• ${resource.formattedSize}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: isDark
                                                    ? Colors.white60
                                                    : AppTheme.inkMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (resource.notes.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            resource.notes,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                              color: isDark
                                                  ? Colors.white54
                                                  : AppTheme.inkMuted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded,
                                        size: 20),
                                    color: AppTheme.accent(context),
                                    tooltip: 'Open',
                                    onPressed: () => _openFile(resource),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: isDark
                                          ? Colors.white54
                                          : AppTheme.inkMuted,
                                      size: 20,
                                    ),
                                    onSelected: (val) {
                                      if (val == 'open') {
                                        _openFile(resource);
                                      } else if (val == 'delete') {
                                        _confirmDelete(context, resource);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'open',
                                        child: Row(
                                          children: [
                                            Icon(Icons.open_in_new_rounded,
                                                size: 18),
                                            SizedBox(width: 10),
                                            Text('Open File'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded,
                                                color: AppTheme.danger,
                                                size: 18),
                                            SizedBox(width: 10),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: AppTheme.danger)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
