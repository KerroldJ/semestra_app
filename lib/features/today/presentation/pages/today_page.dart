import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/video_background.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../item/domain/entities/item_entity.dart';
import '../../../item/presentation/providers/item_provider.dart';
import '../../../item/presentation/item_selectors.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../semester/presentation/providers/semester_provider.dart';

import '../../../../core/widgets/compose_sheet.dart' show showComposeSheet;

/// Home — the dashboard matching the requested design with a top header,
/// animated character banner (Welcome.mp4), 4-metric stats row, and Today / Due next cards.
class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final profile = ref.watch(authNotifierProvider).profile;
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final allItems = ref.watch(itemNotifierProvider).value ?? [];
    final allSchedules = ref.watch(scheduleNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    final subjectsById = {for (final s in subjects) s.id: s};

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scope the dashboard to the active semester only: its subjects, and the
    // classes / tasks / assignments / notes that belong to those subjects.
    final activeSemesterIds = {
      for (final sem in semesters)
        if (sem.isActive && !sem.isArchived) sem.id,
    };
    final activeSubjectIds = {
      for (final s in subjects)
        if (activeSemesterIds.contains(s.semesterId)) s.id,
    };
    final schedules = allSchedules
        .where((s) => activeSubjectIds.contains(s.subjectId))
        .toList();
    final items = allItems
        .where((i) => i.subjectId != null &&
            activeSubjectIds.contains(i.subjectId))
        .toList();

    // Today's non-study classes, sorted by start.
    final todays = schedules
        .where((s) =>
            s.dayOfWeek == now.weekday &&
            s.scheduleType != ScheduleType.study)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nowMinutes = now.hour * 60 + now.minute;
    ScheduleEntity? live;
    final later = <ScheduleEntity>[];
    for (final s in todays) {
      final st = Fmt.parseHHmm(s.startTime);
      final en = Fmt.parseHHmm(s.endTime);
      final startM = st == null ? 0 : st.hour * 60 + st.minute;
      final endM = en == null ? 0 : en.hour * 60 + en.minute;
      if (nowMinutes >= startM && nowMinutes < endM) {
        live = s;
      } else if (startM >= nowMinutes) {
        later.add(s);
      }
    }

    final groups = UrgencyGroups.from(items, now);
    final dueNext = [...groups.overdue, ...groups.thisWeek, ...groups.later];
    final dueSoonCount = groups.overdue.length + groups.thisWeek.length;
    final notesCount = items.where((i) => i.type == ItemType.note).length;

    // Academic standing / Focus level proxy
    final work = items.where((i) => i.type != ItemType.note).toList();
    final done = work.where((i) => i.isCompleted).length;
    var standingScore = work.isEmpty ? 0.85 : done / work.length;
    if (groups.overdue.isNotEmpty) {
      standingScore =
          (standingScore - 0.15 * groups.overdue.length).clamp(0.1, 1.0);
    }
    final standingLabel = standingScore >= 0.8
        ? 'Good'
        : standingScore >= 0.55
            ? 'Fair'
            : 'Needs work';

    // Recent activity, newest first.
    final recent = [...items]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recentTop = recent.take(4).toList();

    final username = profile?.username.isNotEmpty == true
        ? profile!.username
        : 'there';

    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final brandGreen = const Color(0xFF1B8755);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF9FBFA),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showComposeSheet(context),
        backgroundColor: brandGreen,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // ---- Top Header Row ----
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, color: brandGreen, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            username,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(Icons.chevron_right_rounded, color: brandGreen, size: 18),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('EEEE, MMM d').format(now),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: 25,
                        color: textPrimary,
                      ),
                      onPressed: () => context.push('/settings'),
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C566),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ---- Hero Banner Card with Animated Mascot Character ----
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF13281E), const Color(0xFF0B1912)]
                      : [const Color(0xFFEAF7EE), const Color(0xFFDDF3E7), const Color(0xFFE5F5EC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0x221B8755),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Mascot Video on the Right
                    Positioned(
                      top: -6,
                      bottom: -6,
                      right: -10,
                      width: 175,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: const VideoBackground(
                          key: ValueKey('hero_mascot_character_mp4'),
                          asset: 'assets/mp4/Welcome.mp4',
                          placeholderColor: Colors.transparent,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Banner Text on the Left
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 150, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                '\u{2728} ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: brandGreen,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  dueSoonCount == 0
                                      ? "You're all caught up"
                                      : '$dueSoonCount ${dueSoonCount == 1 ? 'task' : 'tasks'} due this week',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep up the great work!',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your goals are within reach.',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ---- 4 Metrics Stats Row ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatCell(
                    value: '$dueSoonCount',
                    label: 'Tasks This Week',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    value: '${todays.length}',
                    label: 'Classes Today',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    value: '${dueNext.length}',
                    label: 'Pending Tasks',
                    icon: Icons.assignment_outlined,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    value: standingLabel,
                    label: 'Focus Level',
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    isHighlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ---- Today Section ----
            _SectionTitle(
              icon: Icons.wb_sunny_outlined,
              title: 'Today',
              actionLabel: 'See all',
              onAction: () => context.push('/schedule'),
            ),
            const SizedBox(height: 14),
            if (todays.isEmpty)
              _EmptyStateCard(
                icon: Icons.coffee_outlined,
                title: 'No classes scheduled for today.',
                subtitle:
                    'Explore course materials or schedule a study session.',
                actions: [
                  _CardAction('View Syllabus', Icons.menu_book_outlined,
                      () => context.go('/subjects')),
                  _CardAction('Book Room', Icons.calendar_today_outlined,
                      () => context.go('/planner')),
                ],
              )
            else ...[
              if (live != null)
                _ClassCard(
                  schedule: live,
                  subject: subjectsById[live.subjectId],
                  highlighted: true,
                )
              else
                _QuietCard(
                    icon: Icons.free_breakfast_outlined,
                    text: 'No class right now.'),
              ...later.map((s) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _ClassCard(
                        schedule: s, subject: subjectsById[s.subjectId]),
                  )),
            ],
            const SizedBox(height: 28),

            // ---- Due Next Section ----
            if (dueNext.isEmpty)
              _EmptyStateCard(
                icon: Icons.check_rounded,
                title: "You're all caught up. No pending deliverables.",
                subtitle: "Get a head start on next term's tasks.",
                actions: [
                  _CardAction('Create Task', Icons.add_rounded,
                      () => context.push('/assignments/edit')),
                  _CardAction('Resource Library', Icons.folder_open_rounded,
                      () => context.go('/notes')),
                ],
              )
            else ...[
              _SectionTitle(
                icon: Icons.event_note_outlined,
                title: 'Due next',
                actionLabel: 'View all',
                onAction: () => context.push('/assignments'),
              ),
              const SizedBox(height: 14),
              ...dueNext.take(3).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DueCard(
                        item: i, subject: subjectsById[i.subjectId], now: now),
                  )),
            ],

            // ---- Recent updates ----
            if (recentTop.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'RECENT UPDATES',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white60 : AppTheme.inkMuted,
                ),
              ),
              const SizedBox(height: 14),
              _RecentGrid(items: recentTop, subjectsById: subjectsById),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single cell in the 4-column metrics row
class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isHighlight;

  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textMuted = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final greenColor = const Color(0xFF0A7D43);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isHighlight)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF00C566)),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: greenColor,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (!isHighlight) ...[
              Icon(icon, size: 11, color: textMuted),
              const SizedBox(width: 3),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section header with a leading icon and an optional trailing text action.
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final brandGreen = const Color(0xFF0A7D43);

    return Row(
      children: [
        Icon(icon, size: 19, color: textPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 16, color: brandGreen),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardAction {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _CardAction(this.label, this.icon, this.onTap);
}

/// A centered empty-state card matching the light rounded card design.
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_CardAction> actions;
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brandGreen = const Color(0xFF0A7D43);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0x14000000),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162C20) : const Color(0xFFE8F6EE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: brandGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Flexible(child: _GhostButton(action: actions[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// An outline button used inside empty states with green borders and icons.
class _GhostButton extends StatelessWidget {
  final _CardAction action;
  const _GhostButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandGreen = const Color(0xFF0A7D43);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.16)
                  : const Color(0x330A7D43),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (action.icon != null) ...[
                Icon(
                  action.icon,
                  size: 15,
                  color: brandGreen,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : brandGreen,
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

/// A responsive 2-column grid of recent-activity cards.
class _RecentGrid extends StatelessWidget {
  final List<ItemEntity> items;
  final Map<String, SubjectEntity> subjectsById;
  const _RecentGrid({required this.items, required this.subjectsById});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;
      rows.add(Padding(
        padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: _UpdateCard(
                      item: left, subject: subjectsById[left.subjectId])),
              const SizedBox(width: 12),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : _UpdateCard(
                        item: right, subject: subjectsById[right.subjectId]),
              ),
            ],
          ),
        ),
      ));
    }
    return Column(children: rows);
  }
}

class _UpdateCard extends StatelessWidget {
  final ItemEntity item;
  final SubjectEntity? subject;
  const _UpdateCard({required this.item, required this.subject});

  IconData get _icon {
    switch (item.type) {
      case ItemType.note:
        return Icons.sticky_note_2_outlined;
      case ItemType.task:
        return Icons.check_circle_outline_rounded;
      case ItemType.assignment:
        return Icons.assignment_outlined;
    }
  }

  String get _subline {
    if (item.dueDate != null) {
      return 'Due ${DateFormat('MMM d, yyyy').format(item.dueDate!)}';
    }
    return DateFormat('MMM d · h:mm a').format(item.updatedAt);
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.soft(AppTheme.brandFill(context), 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_icon, size: 18, color: AppTheme.accent(context)),
          ),
          const SizedBox(height: 12),
          Text(
            item.title.isEmpty ? 'Untitled' : item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 13.5),
          ),
          const SizedBox(height: 3),
          Text(
            _subline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ScheduleEntity schedule;
  final SubjectEntity? subject;
  final bool highlighted;
  const _ClassCard({
    required this.schedule,
    required this.subject,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : (isDark ? Colors.white24 : AppTheme.inkFaint);
    return SpineCard(
      spine: spine,
      highlighted: highlighted,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Fmt.time12(schedule.startTime),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.merge(AppTheme.tnum)),
              Text(schedule.scheduleType.label,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject?.name ?? 'Class',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (schedule.classroom.isNotEmpty)
                  Text(schedule.classroom,
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (highlighted)
            StrokeLabel(text: 'Now', color: AppTheme.brandFill(context)),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  final ItemEntity item;
  final SubjectEntity? subject;
  final DateTime now;
  const _DueCard({required this.item, required this.subject, required this.now});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : (isDark ? Colors.white24 : AppTheme.inkFaint);
    final overdue = item.urgencyFrom(now) == Urgency.overdue;
    return SpineCard(
      spine: spine,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  subject?.name ??
                      (item.type == ItemType.assignment
                          ? 'Assignment'
                          : 'Task'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            Fmt.dueLabel(item.dueDate!),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.merge(AppTheme.tnum)
                .copyWith(
                  color: overdue
                      ? AppTheme.danger
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppTheme.inkMuted),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuietCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _QuietCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.hairline,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? Colors.white.withValues(alpha: 0.40)
                : AppTheme.inkFaint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
