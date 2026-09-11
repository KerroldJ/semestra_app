import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/navigation/navigation_shell.dart' show fabHiddenNotifier;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/common.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/entities/semester_entity.dart';
import '../providers/semester_provider.dart';

/// Screen — Semesters Management Tab (default landing screen).
/// Enterprise layout: an active-term hero with live progress, an overview
/// metric strip, segmented filters, and refined semester cards.
class SemesterPage extends ConsumerWidget {
  const SemesterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semestersState = ref.watch(semesterNotifierProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: semestersState.when(
          data: (semesters) {
            int subjCount(SemesterEntity s) =>
                subjects.where((x) => x.semesterId == s.id).length;
            double unitsOf(SemesterEntity s) => subjects
                .where((x) => x.semesterId == s.id)
                .fold<double>(0.0, (a, x) => a + x.units);

            if (semesters.isEmpty) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                children: [
                  _Header(now: now),
                  const SizedBox(height: 20),
                  _EmptySemesters(onCreate: () => showSemesterSheet(context)),
                ],
              );
            }

            // Prefer a live/current active term for the hero; fall back to any
            // flagged-active term.
            final activeTerms =
                semesters.where((s) => s.isActive && !s.isArchived).toList();
            SemesterEntity? hero;
            for (final s in activeTerms) {
              if (!now.isBefore(s.startDate) && !now.isAfter(s.endDate)) {
                hero = s;
                break;
              }
            }
            hero ??= activeTerms.isNotEmpty ? activeTerms.first : null;

            final visible = [...semesters]
              ..sort((a, b) => b.startDate.compareTo(a.startDate));

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                _Header(now: now),
                const SizedBox(height: 18),
                if (hero != null) ...[
                  _ActiveHero(
                    semester: hero,
                    subjectCount: subjCount(hero),
                    totalUnits: unitsOf(hero),
                    now: now,
                    onManage: () =>
                        showSemesterSheet(context, existing: hero),
                  ),
                  const SizedBox(height: 18),
                ],
                ...visible.map((sem) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _SemesterCard(
                        semester: sem,
                        subjectCount: subjCount(sem),
                        totalUnits: unitsOf(sem),
                      ),
                    )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading semesters: $err')),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Term timing helpers
// ─────────────────────────────────────────────────────────────────────────

double _termProgress(SemesterEntity s, DateTime now) {
  final total = s.endDate.difference(s.startDate).inSeconds;
  if (total <= 0) return 0;
  return (now.difference(s.startDate).inSeconds / total).clamp(0.0, 1.0);
}

int _totalWeeks(SemesterEntity s) =>
    (s.endDate.difference(s.startDate).inDays / 7).ceil().clamp(1, 999);

int _currentWeek(SemesterEntity s, DateTime now) {
  final w = (now.difference(s.startDate).inDays / 7).floor() + 1;
  return w.clamp(1, _totalWeeks(s));
}

/// Descriptive term state used for the status pill.
({String label, Color color}) _termStatus(
    BuildContext context, SemesterEntity s, DateTime now) {
  if (s.isArchived) return (label: 'Archived', color: AppTheme.inkMuted);
  if (now.isBefore(s.startDate)) {
    return (label: 'Upcoming', color: AppTheme.accent(context));
  }
  if (now.isAfter(s.endDate)) return (label: 'Completed', color: AppTheme.inkMuted);
  return (label: 'In progress', color: AppTheme.accent(context));
}

// ─────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────

/// Illustrated hero header for the Semesters tab — pairs the studying-mascot
/// artwork with the title, date, and term-count pill.
class _Header extends StatelessWidget {
  final DateTime now;
  const _Header({required this.now});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0D3B2C);
    final dateColor =
        isDark ? const Color(0xFF8FD8B3) : const Color(0xFF3B6756);
    final subColor = isDark ? Colors.white70 : const Color(0xFF4A6B5E);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isCompact = cardWidth < 440;
        final mascotWidth = isCompact ? cardWidth * 0.42 : 210.0;

        return Container(
          height: isCompact ? 168 : 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Campus-scene background image.
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/SemesterBG.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF13281E),
                                  const Color(0xFF0B1912),
                                ]
                              : [
                                  const Color(0xFFEAF7EE),
                                  const Color(0xFFDDF3E7),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Darken slightly in dark mode so text stays legible.
                if (isDark)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                // Legibility veil on the left, fading out toward the mascot so
                // the heading and subtitle stay readable over the artwork.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: isDark
                            ? [
                                Colors.black.withValues(alpha: 0.58),
                                Colors.black.withValues(alpha: 0.0),
                              ]
                            : [
                                const Color(0xFFE9F6EE).withValues(alpha: 0.97),
                                const Color(0xFFE9F6EE).withValues(alpha: 0.0),
                              ],
                        stops: const [0.0, 0.66],
                      ),
                    ),
                  ),
                ),
                // Mascot illustration, bottom-right.
                Positioned(
                  right: -8,
                  bottom: -8,
                  top: 6,
                  width: mascotWidth,
                  child: Image.asset(
                    'assets/images/Semester.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                // Left text block.
                Positioned(
                  left: 20,
                  top: 18,
                  bottom: 18,
                  right: mascotWidth * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(now),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: isCompact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: dateColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Semesters',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: isCompact ? 26 : 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.0,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Plan your term and track your progress.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: subColor,
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

// ─────────────────────────────────────────────────────────────────────────
// Active-term hero — the enterprise centerpiece with live term progress
// ─────────────────────────────────────────────────────────────────────────

class _ActiveHero extends StatelessWidget {
  final SemesterEntity semester;
  final int subjectCount;
  final double totalUnits;
  final DateTime now;
  final VoidCallback onManage;

  const _ActiveHero({
    required this.semester,
    required this.subjectCount,
    required this.totalUnits,
    required this.now,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final progress = _termProgress(semester, now);
    final pct = (progress * 100).round();
    final week = _currentWeek(semester, now);
    final weeks = _totalWeeks(semester);
    final daysLeft = semester.endDate.difference(now).inDays;
    final unitsStr = totalUnits.toStringAsFixed(
        totalUnits.truncateToDouble() == totalUnits ? 0 : 1);
    final started = !now.isBefore(semester.startDate);
    final ended = now.isAfter(semester.endDate);

    final progressLabel = !started
        ? 'Starts ${DateFormat('MMM d').format(semester.startDate)}'
        : ended
            ? 'Term completed'
            : daysLeft <= 0
                ? 'Final day'
                : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppTheme.accent(context);
    final textColor = AppTheme.text(context);
    final muted = AppTheme.textMuted(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft brand glow, top-right — a touch of green for depth.
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.brandFill(context).withValues(alpha: isDark ? 0.16 : 0.10),
                      AppTheme.brandFill(context).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.soft(AppTheme.brandFill(context), 0.14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ACTIVE TERM',
                              style: TextStyle(
                                color: accent,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (started && !ended)
                        Text(
                          'Week $week of $weeks',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    semester.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(semester.startDate)} – ${DateFormat('MMM d, yyyy').format(semester.endDate)}',
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Progress track
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        started && !ended ? '$pct% complete' : progressLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (started && !ended)
                        Text(
                          progressLabel,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppTheme.soft(AppTheme.brandFill(context), 0.16),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.brandFill(context)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _HeroStat(
                        value: '$subjectCount',
                        label: subjectCount == 1 ? 'Subject' : 'Subjects',
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        color: AppTheme.hairlineBorder(context),
                      ),
                      _HeroStat(
                        value: unitsStr,
                        label: totalUnits == 1 ? 'Unit' : 'Units',
                      ),
                      const Spacer(),
                      Material(
                        color: AppTheme.soft(AppTheme.brandFill(context), 0.14),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onManage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded,
                                    size: 17, color: accent),
                                const SizedBox(width: 7),
                                Text(
                                  'Manage',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppTheme.text(context),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Shared add / edit bottom sheet. Pass [existing] to edit; omit to create.
Future<void> showSemesterSheet(
  BuildContext context, {
  SemesterEntity? existing,
}) async {
  fabHiddenNotifier.value = true;
  try {
    return await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => _SemesterSheet(existing: existing),
    );
  } finally {
    fabHiddenNotifier.value = false;
  }
}

class _SemesterSheet extends ConsumerStatefulWidget {
  final SemesterEntity? existing;
  const _SemesterSheet({this.existing});

  @override
  ConsumerState<_SemesterSheet> createState() => _SemesterSheetState();
}

class _SemesterSheetState extends ConsumerState<_SemesterSheet> {
  late final TextEditingController _name;
  late DateTime _start;
  late DateTime _end;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _start = e?.startDate ?? DateTime.now();
    _end = e?.endDate ?? DateTime.now().add(const Duration(days: 7 * 15));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      AppToast.error('Please enter a semester name');
      return;
    }
    final notifier = ref.read(semesterNotifierProvider.notifier);
    if (_isEditing) {
      notifier.editSemester(widget.existing!.copyWith(
        name: name,
        startDate: _start,
        endDate: _end,
      ));
      AppToast.success('Semester updated');
    } else {
      notifier.addSemester(
        name: name,
        startDate: _start,
        endDate: _end,
        isActive: true,
      );
      AppToast.success('Semester created');
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).scaffoldBackgroundColor : AppTheme.warmBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.inkFaint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_isEditing ? 'Edit Semester' : 'New Semester',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                const _Label('NAME'),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'e.g. Fall 2026'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('STARTS'),
                          _DateField(
                              label: DateFormat('MMM d, y').format(_start),
                              onTap: () => _pick(true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('ENDS'),
                          _DateField(
                              label: DateFormat('MMM d, y').format(_end),
                              onTap: () => _pick(false)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Semester',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.65)
                  : AppTheme.inkMuted,
            )),
      );
}

class _DateField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.hairline,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.40)
                    : AppTheme.inkFaint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: isDark ? AppTheme.darkInk : AppTheme.ink,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterCard extends ConsumerWidget {
  final SemesterEntity semester;
  final int subjectCount;
  final double totalUnits;

  const _SemesterCard({
    required this.semester,
    required this.subjectCount,
    required this.totalUnits,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateRange =
        '${DateFormat('MMM d, yyyy').format(semester.startDate)} – ${DateFormat('MMM d, yyyy').format(semester.endDate)}';
    final unitsStr = totalUnits.toStringAsFixed(
        totalUnits.truncateToDouble() == totalUnits ? 0 : 1);

    final now = DateTime.now();
    final status = _termStatus(context, semester, now);
    final inProgress = !semester.isArchived &&
        !now.isBefore(semester.startDate) &&
        !now.isAfter(semester.endDate);
    final progress = _termProgress(semester, now);

    return SoftCard(
      padding: const EdgeInsets.all(18),
      color: semester.isArchived && !isDark
          ? const Color(0xFFF7F7F9)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            semester.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Pill(
                          text: status.label,
                          bg: AppTheme.soft(
                              status.color, isDark ? 0.20 : 0.12),
                          fg: status.color == AppTheme.inkMuted && isDark
                              ? Colors.white70
                              : status.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _MoreMenu(
                isArchived: semester.isArchived,
                onEdit: () => showSemesterSheet(context, existing: semester),
                onArchive: () {
                  ref.read(semesterNotifierProvider.notifier).archiveSemester(
                        semester,
                        !semester.isArchived,
                      );
                  AppToast.success(semester.isArchived
                      ? '${semester.name} unarchived'
                      : '${semester.name} archived');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaBit(icon: Icons.date_range_rounded, text: dateRange),
              _MetaBit(
                icon: Icons.menu_book_rounded,
                text:
                    '$subjectCount ${subjectCount == 1 ? 'subject' : 'subjects'} · $unitsStr ${totalUnits == 1 ? 'unit' : 'units'}',
              ),
            ],
          ),
          if (inProgress) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.soft(AppTheme.brandFill(context), 0.16),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.accent(context)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent(context),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                semester.isActive ? 'Active semester' : 'Set as active',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: semester.isActive
                      ? AppTheme.accent(context)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppTheme.inkMuted),
                ),
              ),
              const Spacer(),
              Switch.adaptive(
                value: semester.isActive,
                activeColor: AppTheme.accent(context),
                activeTrackColor: AppTheme.soft(AppTheme.brandFill(context), 0.4),
                onChanged: (val) {
                  ref.read(semesterNotifierProvider.notifier).editSemester(
                        semester.copyWith(isActive: val),
                      );
                  AppToast.success(val
                      ? '${semester.name} is now the active semester'
                      : '${semester.name} deactivated');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon + muted text row used for the semester metadata line.
class _MetaBit extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaBit({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppTheme.inkMuted;
    final faint = isDark ? Colors.white.withValues(alpha: 0.40) : AppTheme.inkFaint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: faint),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ],
    );
  }
}

/// Overflow menu (edit / archive) replacing the twin icon buttons.
class _MoreMenu extends StatelessWidget {
  final bool isArchived;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  const _MoreMenu({
    required this.isArchived,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : AppTheme.inkMuted;
    return PopupMenuButton<String>(
      tooltip: 'Options',
      icon: Icon(Icons.more_horiz_rounded, size: 22, color: iconColor),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (v) => v == 'edit' ? onEdit() : onArchive(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: iconColor),
              const SizedBox(width: 10),
              const Text('Edit semester'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(
                isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Text(isArchived ? 'Unarchive' : 'Archive'),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySemesters extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptySemesters({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.soft(AppTheme.brandFill(context), 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.calendar_month_rounded,
                size: 28, color: AppTheme.accent(context)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Semesters Created',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your academic semesters (e.g. Fall 2026, Spring 2027) to organize your courses and schedules.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create First Semester'),
          ),
        ],
      ),
    );
  }
}

