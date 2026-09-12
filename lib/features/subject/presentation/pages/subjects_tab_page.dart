import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/quick_add_sheet.dart'
    show showEditSubjectSheet, showNewSubjectSheet;
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../semester/domain/entities/semester_entity.dart';
import '../../../semester/presentation/pages/semester_page.dart'
    show showSemesterSheet;
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../domain/entities/subject_entity.dart';
import '../providers/subject_provider.dart';
import '../../../resource/domain/entities/resource_entity.dart';
import '../../../resource/presentation/providers/resource_provider.dart';

enum _SubjectSortOption { code, name, units }

/// Illustrated Subjects Tab Page matching the design system with
/// mascot artwork, stats overview, search, and responsive subject cards.
class SubjectsTabPage extends ConsumerStatefulWidget {
  const SubjectsTabPage({super.key});

  @override
  ConsumerState<SubjectsTabPage> createState() => _SubjectsTabPageState();
}

class _SubjectsTabPageState extends ConsumerState<SubjectsTabPage> {
  String? _selectedSemesterId;
  _SubjectSortOption _sortOption = _SubjectSortOption.code;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDeleteSubject(
    BuildContext context,
    SubjectEntity subject,
    List<ScheduleEntity> subjectSchedules,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(subjectNotifierProvider.notifier)
                  .deleteSubject(subject.id);
              for (final sch in subjectSchedules) {
                ref
                    .read(scheduleNotifierProvider.notifier)
                    .deleteSchedule(sch.id);
              }
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
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final items = ref.watch(itemNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];
    final resources = ref.watch(resourceNotifierProvider).value ?? [];

    SemesterEntity? activeSemester;
    if (semesters.isNotEmpty) {
      if (_selectedSemesterId != null &&
          semesters.any((s) => s.id == _selectedSemesterId)) {
        activeSemester =
            semesters.firstWhere((s) => s.id == _selectedSemesterId);
      } else {
        activeSemester =
            semesters.firstWhere((s) => s.isActive, orElse: () => semesters.first);
        _selectedSemesterId = activeSemester.id;
      }
    } else {
      activeSemester = null;
      _selectedSemesterId = null;
    }

    // Determine base subjects (active semester or all subjects)
    final semester = activeSemester;
    List<SubjectEntity> displayedSubjects = semester == null
        ? subjects
        : subjects.where((s) => s.semesterId == semester.id).toList();
    if (displayedSubjects.isEmpty && subjects.isNotEmpty) {
      displayedSubjects = subjects;
    }

    // Apply search filter if query is present
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      displayedSubjects = displayedSubjects.where((s) {
        return s.code.toLowerCase().contains(q) ||
            s.name.toLowerCase().contains(q) ||
            s.instructor.toLowerCase().contains(q) ||
            s.classroom.toLowerCase().contains(q);
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case _SubjectSortOption.code:
        displayedSubjects.sort((a, b) => a.code.compareTo(b.code));
        break;
      case _SubjectSortOption.name:
        displayedSubjects.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _SubjectSortOption.units:
        displayedSubjects.sort((a, b) => b.units.compareTo(a.units));
        break;
    }

    final totalUnits =
        displayedSubjects.fold<double>(0.0, (acc, s) => acc + s.units);
    final subjectCount = displayedSubjects.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // 1. Hero Banner Card with Mascot and Statistics
            _SubjectHeroBanner(
              subjectCount: subjectCount,
              totalUnits: totalUnits,
              semesterName: activeSemester?.name,
            ),
            const SizedBox(height: 14),

            // 2. Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B231F) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E9E4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isDark ? Colors.white60 : const Color(0xFF6B8074),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0D3B2C),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by code, title, professor, room...',
                        hintStyle: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          color: isDark ? Colors.white38 : const Color(0xFF8B9E94),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Subject List / Empty State
            if (semesters.isEmpty)
              _EmptyNoSemester(
                onCreateSemester: () => showSemesterSheet(context),
              )
            else if (displayedSubjects.isEmpty)
              _EmptyNoSubjects(
                semesterName: activeSemester?.name ?? 'your classes',
                isFiltered: _searchQuery.isNotEmpty,
                onClearSearch: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                onAddSubject: () => showNewSubjectSheet(
                  context,
                  defaultSemesterId: activeSemester?.id,
                ),
              )
            else ...[
              ...displayedSubjects.map((s) {
                final subjectItems =
                    items.where((i) => i.subjectId == s.id).toList();
                final subjectSchedules =
                    schedules.where((sch) => sch.subjectId == s.id).toList();
                final subjectResources =
                    resources.where((r) => r.subjectId == s.id && !r.isDeleted).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubjectCard(
                    subject: s,
                    items: subjectItems,
                    schedules: subjectSchedules,
                    resources: subjectResources,
                    onView: () => showEditSubjectSheet(
                      context,
                      subject: s,
                      schedules: subjectSchedules,
                    ),
                    onEdit: () => showEditSubjectSheet(
                      context,
                      subject: s,
                      schedules: subjectSchedules,
                    ),
                    onResources: () => context.push(
                      '/subject/resources',
                      extra: s,
                    ),
                    onDelete: () =>
                        _confirmDeleteSubject(context, s, subjectSchedules),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: const Color(0xFF00C566),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => showNewSubjectSheet(
          context,
          defaultSemesterId: activeSemester?.id,
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Hero Banner Component
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectHeroBanner extends StatelessWidget {
  final int subjectCount;
  final double totalUnits;
  final String? semesterName;

  const _SubjectHeroBanner({
    required this.subjectCount,
    required this.totalUnits,
    this.semesterName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalUnitsStr = totalUnits.toStringAsFixed(
        totalUnits.truncateToDouble() == totalUnits ? 0 : 1);

    const titleColor = Color(0xFF0D3B2C);
    const subColor = Color(0xFF5A756C);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 420;
        final mascotWidth = isCompact ? cardWidth * 0.40 : 180.0;

        return Container(
          width: double.infinity,
          height: isCompact ? 175 : 185,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Campus Illustrated Background
                Image.asset(
                  'assets/images/SubjectBG.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEAF7EE), Color(0xFFDDF3E7)],
                      ),
                    ),
                  ),
                ),

                // Dark mode adjustment if dark theme
                if (isDark)
                  Container(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),

                // 2. Mascot Artwork on Right
                Positioned(
                  right: -8,
                  bottom: -10,
                  top: 2,
                  width: mascotWidth,
                  child: Image.asset(
                    'assets/images/Subject.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),

                // 3. Left Text and Stats Container
                Positioned(
                  left: 18,
                  top: 16,
                  bottom: 14,
                  right: mascotWidth * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header title & subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subjects',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: isCompact ? 23 : 26,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : titleColor,
                              letterSpacing: -0.6,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your classes, all in one place.',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: isCompact ? 11 : 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF90C2A9) : subColor,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Stats rounded card (Subjects & Units)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF14291F).withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2EFE7),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Stat 1: Subjects count
                            _StatPillItem(
                              icon: Icons.menu_book_rounded,
                              value: '$subjectCount',
                              label: subjectCount == 1 ? 'Subject' : 'Subjects',
                              isDark: isDark,
                            ),
                            Container(
                              height: 22,
                              width: 1,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2ECE6),
                            ),
                            // Stat 2: Units count
                            _StatPillItem(
                              icon: Icons.school_rounded,
                              value: totalUnitsStr,
                              label: 'Units',
                              isDark: isDark,
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
        );
      },
    );
  }
}

class _StatPillItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _StatPillItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF224433)
                : const Color(0xFFDEF5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isDark ? const Color(0xFF5EE59A) : const Color(0xFF0A7D43),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0D3B2C),
                height: 1.05,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white60
                    : const Color(0xFF6B8074),
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// 3. Subject Card Component
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectEntity subject;
  final List<ItemEntity> items;
  final List<ScheduleEntity> schedules;
  final List<ResourceEntity> resources;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onResources;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.items,
    required this.schedules,
    required this.resources,
    required this.onView,
    required this.onEdit,
    required this.onResources,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spineColor = AppTheme.spineFor(subject.colorValue);

    final notesCount = items.where((i) => i.type == ItemType.note).length;
    final tasksCount =
        items.where((i) => i.type != ItemType.note && !i.isCompleted).length;
    final resourcesCount = resources.length;

    // Formatting schedules
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const shortDayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final sortedSchedules = [...schedules]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    String dayString = 'No schedule';
    String timeString = '';

    if (sortedSchedules.isNotEmpty) {
      if (sortedSchedules.length == 1) {
        dayString = dayNames[sortedSchedules.first.dayOfWeek];
        timeString =
            '${Fmt.time12(sortedSchedules.first.startTime)} – ${Fmt.time12(sortedSchedules.first.endTime)}';
      } else {
        dayString = sortedSchedules
            .map((s) => shortDayNames[s.dayOfWeek])
            .toSet()
            .join(', ');
        timeString =
            '${Fmt.time12(sortedSchedules.first.startTime)} – ${Fmt.time12(sortedSchedules.first.endTime)}';
      }
    }

    final instructorClean = subject.instructor.trim();
    final instructorFormatted = instructorClean.isNotEmpty
        ? (instructorClean.toLowerCase().startsWith('prof')
            ? instructorClean
            : 'Prof. $instructorClean')
        : '';

    final classroomText = subject.classroom.trim().isNotEmpty
        ? subject.classroom.trim()
        : 'No room set';

    final unitsStr =
        '${subject.units.toStringAsFixed(subject.units.truncateToDouble() == subject.units ? 0 : 1)} Units';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8EFEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Colored Spine Accent Strip
              Container(
                width: 5,
                color: spineColor,
              ),

              // Card Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Header (Badge, Title, Units, Popup Menu)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Subject Code Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A2B)
                                  : const Color(0xFFDEF5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              subject.code.isNotEmpty ? subject.code : '101',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                color: isDark
                                    ? const Color(0xFF5EE59A)
                                    : const Color(0xFF0A7D43),
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Title and Units
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subject.name,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0D3B2C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  instructorFormatted.isNotEmpty
                                      ? '$unitsStr • $instructorFormatted'
                                      : unitsStr,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF6B8074),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 3-dots Menu
                          PopupMenuButton<String>(
                            tooltip: 'Subject actions',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (val) {
                              if (val == 'edit') {
                                onEdit();
                              } else if (val == 'resources') {
                                onResources();
                              } else if (val == 'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 10),
                                    Text('Edit Subject'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'resources',
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder_open_rounded, size: 18),
                                    const SizedBox(width: 10),
                                    Text('Resources ($resourcesCount)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 18, color: AppTheme.danger),
                                    SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF8B9E94),
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF0F4F1),
                      ),
                      const SizedBox(height: 10),

                      // Section 2: Schedule & Location Row
                      Row(
                        children: [
                          // Schedule info
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B8074),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dayString,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0D3B2C),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (timeString.isNotEmpty)
                                        Text(
                                          timeString,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF6B8074),
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

                          // Vertical subtle divider
                          Container(
                            height: 28,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF0F4F1),
                          ),

                          // Location & Instructor info
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B8074),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        classroomText,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0D3B2C),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (instructorFormatted.isNotEmpty)
                                        Text(
                                          instructorFormatted,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xFF6B8074),
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
                        ],
                      ),

                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color:
                            isDark ? Colors.white10 : const Color(0xFFF0F4F1),
                      ),
                      const SizedBox(height: 10),

                      // Section 3: Footer (Notes count, Open tasks count, View Subject pill)
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // Notes count
                                Icon(
                                  Icons.sticky_note_2_outlined,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B8074),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '$notesCount notes',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF5A756C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  height: 12,
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E7E4),
                                ),

                                // Tasks count
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B8074),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    '$tasksCount open',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF5A756C),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  height: 12,
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E7E4),
                                ),

                                // Resources count
                                InkWell(
                                  onTap: onResources,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.folder_open_rounded,
                                        size: 14,
                                        color: isDark
                                            ? Colors.white60
                                            : const Color(0xFF6B8074),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$resourcesCount files',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF5A756C),
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

                          const SizedBox(width: 6),

                          // View Resources -> Button (transparent bg)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: onResources,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Resources',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A7D43),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: Color(0xFF0A7D43),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Empty State Components
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNoSemester extends StatelessWidget {
  final VoidCallback onCreateSemester;
  const _EmptyNoSemester({required this.onCreateSemester});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8EFEA),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF224433) : const Color(0xFFDEF5E9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 28,
              color: Color(0xFF0A7D43),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Semester Created',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D3B2C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create an academic semester (e.g. Fall 2026) to add and organize your subjects under it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF6B8074),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateSemester,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C566),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Create Semester',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNoSubjects extends StatelessWidget {
  final String semesterName;
  final bool isFiltered;
  final VoidCallback onClearSearch;
  final VoidCallback onAddSubject;

  const _EmptyNoSubjects({
    required this.semesterName,
    this.isFiltered = false,
    required this.onClearSearch,
    required this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F1B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8EFEA),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF224433) : const Color(0xFFDEF5E9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 28,
              color: Color(0xFF0A7D43),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No Matching Subjects' : 'No Subjects in $semesterName',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0D3B2C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Try adjusting your search terms or filter options.'
                : 'Add your classes, lectures, or labs to begin tracking assignments, notes, and schedules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF6B8074),
            ),
          ),
          const SizedBox(height: 20),
          if (isFiltered)
            OutlinedButton(
              onPressed: onClearSearch,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Clear Search'),
            )
          else
            ElevatedButton.icon(
              onPressed: onAddSubject,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C566),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Subject',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
