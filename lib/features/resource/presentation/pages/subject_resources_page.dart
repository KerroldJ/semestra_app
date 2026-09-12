import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../domain/entities/resource_entity.dart';
import '../providers/resource_provider.dart';
import '../widgets/upload_resource_sheet.dart';

class SubjectResourcesPage extends ConsumerStatefulWidget {
  final SubjectEntity subject;

  const SubjectResourcesPage({super.key, required this.subject});

  @override
  ConsumerState<SubjectResourcesPage> createState() =>
      _SubjectResourcesPageState();
}

class _SubjectResourcesPageState extends ConsumerState<SubjectResourcesPage> {
  String _filterType = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

    // Apply category filter
    if (_filterType == 'PDF') {
      filtered = filtered.where((r) => r.extension == 'pdf').toList();
    } else if (_filterType == 'PPT') {
      filtered = filtered.where((r) => r.extension.startsWith('ppt')).toList();
    } else if (_filterType == 'Sheets') {
      filtered = filtered
          .where((r) =>
              r.extension == 'xls' ||
              r.extension == 'xlsx' ||
              r.extension == 'csv')
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

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.fileName.toLowerCase().contains(q) ||
            r.notes.toLowerCase().contains(q);
      }).toList();
    }

    final spine = AppTheme.spineFor(widget.subject.colorValue);
    final brandFill = AppTheme.brandFill(context);

    final pdfCount = subjectResources.where((r) => r.extension == 'pdf').length;
    final pptCount =
        subjectResources.where((r) => r.extension.startsWith('ppt')).length;
    final sheetCount = subjectResources
        .where((r) =>
            r.extension == 'xls' ||
            r.extension == 'xlsx' ||
            r.extension == 'csv')
        .length;
    final docCount = subjectResources
        .where((r) =>
            r.extension.startsWith('doc') ||
            r.extension == 'txt' ||
            r.extension == 'rtf' ||
            r.extension == 'odt')
        .length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: spine,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.subject.code.isNotEmpty ? "${widget.subject.code} • " : ""}Resources',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subject.name,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: brandFill,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Upload Resource',
        onPressed: () {
          showUploadResourceSheet(
            context,
            defaultSubjectId: widget.subject.id,
          );
        },
        child: const Icon(Icons.upload_file_rounded, size: 26),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // 1. Illustrated Hero Banner with Resources.png
          Container(
            height: 215,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: brandFill.withValues(alpha: isDark ? 0.2 : 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full Background artwork
                  Image.asset(
                    'assets/images/Resources.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEBF7F0), Color(0xFFD4EFE1)],
                        ),
                      ),
                    ),
                  ),

                  // Subtle dark mode dimming if dark theme
                  if (isDark)
                    Container(
                      color: Colors.black.withValues(alpha: 0.25),
                    ),

                  // Left Hero Content Overlay
                  Positioned(
                    left: 18,
                    top: 18,
                    bottom: 16,
                    right: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEARN  •  SHARE  •  GROW',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: isDark
                                    ? const Color(0xFF90C2A9)
                                    : const Color(0xFF0F4B38),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Resources',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF083C2C),
                                letterSpacing: -0.6,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Upload lecture presentations,\nPDFs, datasets, and docs.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF2C5545),
                              ),
                            ),
                          ],
                        ),

                        // Quote Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E2C24).withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.white.withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 16,
                                color: const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '“Good materials lead to greater learning!”',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0D3B2C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Four-Category Floating Stats Card (PDF, Slides, Sheets, Docs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.hairlineBorder(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatColumnItem(
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: const Color(0xFFE53935),
                  iconBgColor: const Color(0xFFFDE8E8),
                  count: pdfCount,
                  label: 'PDFs',
                  isSelected: _filterType == 'PDF',
                  onTap: () {
                    setState(() {
                      _filterType = _filterType == 'PDF' ? 'All' : 'PDF';
                    });
                  },
                ),
                _buildStatDivider(context),
                _StatColumnItem(
                  icon: Icons.slideshow_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBgColor: const Color(0xFFFEF3C7),
                  count: pptCount,
                  label: 'Slides',
                  isSelected: _filterType == 'PPT',
                  onTap: () {
                    setState(() {
                      _filterType = _filterType == 'PPT' ? 'All' : 'PPT';
                    });
                  },
                ),
                _buildStatDivider(context),
                _StatColumnItem(
                  icon: Icons.table_chart_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBgColor: const Color(0xFFDCFCE7),
                  count: sheetCount,
                  label: 'Sheets',
                  isSelected: _filterType == 'Sheets',
                  onTap: () {
                    setState(() {
                      _filterType = _filterType == 'Sheets' ? 'All' : 'Sheets';
                    });
                  },
                ),
                _buildStatDivider(context),
                _StatColumnItem(
                  icon: Icons.article_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFDBEAFE),
                  count: docCount,
                  label: 'Docs',
                  isSelected: _filterType == 'Docs',
                  onTap: () {
                    setState(() {
                      _filterType = _filterType == 'Docs' ? 'All' : 'Docs';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Search & Filter Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.hairlineBorder(context)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search files by title or keyword...',
                hintStyle: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white38 : AppTheme.inkMuted,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : AppTheme.inkMuted,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                    backgroundColor:
                        isDark ? const Color(0xFF1B2520) : Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
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
          const SizedBox(height: 16),

          // 3. Resources List
          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.soft(brandFill, 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 44,
                        color: AppTheme.accent(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subjectResources.isEmpty
                          ? 'No files uploaded yet'
                          : 'No files match your filter',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Upload your lecture notes, slides, problem sets, or readings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : AppTheme.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((resource) {
              final color = resource.categoryColor;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.hairlineBorder(context),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.22 : 0.035),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _openFile(resource),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // File Icon Badge
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                resource.icon,
                                color: color,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource.title,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : AppTheme.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    resource.fileName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : AppTheme.inkMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          resource.extension.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        resource.formattedSize,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.white60
                                              : AppTheme.inkMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${DateFormat('MMM d, yyyy').format(resource.createdAt)}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? Colors.white38
                                              : AppTheme.inkFaint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (resource.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : const Color(0xFFF7FAF8),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        resource.notes,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? Colors.white70
                                              : AppTheme.inkMuted,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Action Menu
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF8B9E94),
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
                                      Icon(Icons.open_in_new_rounded, size: 18),
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
                                          color: AppTheme.danger, size: 18),
                                      SizedBox(width: 10),
                                      Text('Delete',
                                          style:
                                              TextStyle(color: AppTheme.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.hairlineBorder(context),
    );
  }
}

class _StatColumnItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final int count;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatColumnItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.count,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? iconColor.withValues(alpha: isDark ? 0.2 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Box
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? iconColor.withValues(alpha: 0.18)
                      : iconBgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              // Count & Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.ink,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : AppTheme.inkMuted,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
