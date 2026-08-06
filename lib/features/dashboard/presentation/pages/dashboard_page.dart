import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

// Providers
import 'package:semestra_app/features/semester/presentation/providers/semester_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:semestra_app/features/assignment/presentation/providers/assignment_provider.dart';
import 'package:semestra_app/features/note/presentation/providers/note_provider.dart';
import 'package:semestra_app/features/exam/presentation/providers/exam_provider.dart';
import 'package:semestra_app/features/study_timer/presentation/providers/study_session_provider.dart';

// Themes
import 'package:semestra_app/core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentDayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    
    final semesterState = ref.watch(semesterNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final assignmentState = ref.watch(assignmentNotifierProvider);
    final notesState = ref.watch(noteNotifierProvider);
    final examsState = ref.watch(examNotifierProvider);
    final studyState = ref.watch(studySessionHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Gorgeous Greeting Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back, Student!',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            // Top Summary cards row (GPA, Study Sessions, Total Classes Today)
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    // Study sessions card
                    studyState.when(
                      data: (sessions) {
                        final count = sessions.where((s) => s.sessionType == 0).length;
                        return _HeaderQuickStatCard(
                          title: 'Study Logs',
                          value: '$count Sessions',
                          icon: Icons.timer_rounded,
                          color: const Color(0xFF6366F1),
                        );
                      },
                      loading: () => const _LoadingStatCard(),
                      error: (_, __) => const _LoadingStatCard(),
                    ),
                    const SizedBox(width: 16),

                    // Assignments remaining card
                    assignmentState.when(
                      data: (assigns) {
                        final pending = assigns.where((a) => a.status != 2).length;
                        return _HeaderQuickStatCard(
                          title: 'Assignments',
                          value: '$pending Pending',
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFFEC4899),
                        );
                      },
                      loading: () => const _LoadingStatCard(),
                      error: (_, __) => const _LoadingStatCard(),
                    ),
                    const SizedBox(width: 16),

                    // Exams remaining card
                    examsState.when(
                      data: (exams) {
                        final upcoming = exams.where((e) => e.scheduledDate.isAfter(DateTime.now())).length;
                        return _HeaderQuickStatCard(
                          title: 'Exams Scheduled',
                          value: '$upcoming Upcoming',
                          icon: Icons.quiz_rounded,
                          color: const Color(0xFFF59E0B),
                        );
                      },
                      loading: () => const _LoadingStatCard(),
                      error: (_, __) => const _LoadingStatCard(),
                    ),
                  ],
                ),
              ),
            ),

            // Main dashboard content sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),

                  // Today's classes
                  _buildSectionHeader(context, "Today's Timetable", () => context.go('/schedule')),
                  const SizedBox(height: 12),
                  scheduleState.when(
                    data: (schedules) {
                      final todayClasses = schedules.where((s) => s.dayOfWeek == currentDayOfWeek).toList();
                      todayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

                      if (todayClasses.isEmpty) {
                        return const _DashboardEmptyCard(
                          message: 'No classes scheduled for today. Time to study or relax!',
                          icon: Icons.hotel_rounded,
                        );
                      }

                      return Column(
                        children: todayClasses.take(3).map((sch) {
                          final subjects = subjectState.value ?? [];
                          final match = subjects.where((s) => s.id == sch.subjectId).toList();
                          final sub = match.isNotEmpty ? match.first : null;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.class_rounded,
                                color: sub != null ? Color(sub.colorValue) : Colors.grey,
                              ),
                              title: Text(
                                sub != null ? '${sub.code}: ${sub.name}' : 'Unknown Subject',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${sch.startTime} - ${sch.endTime} @ Room ${sch.classroom}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 24),

                  // Upcoming assignments
                  _buildSectionHeader(context, "Upcoming Assignments", () => context.go('/assignments')),
                  const SizedBox(height: 12),
                  assignmentState.when(
                    data: (assigns) {
                      final activeAssigns = assigns.where((a) => a.status != 2).toList();
                      activeAssigns.sort((a, b) => a.dueDate.compareTo(b.dueDate));

                      if (activeAssigns.isEmpty) {
                        return const _DashboardEmptyCard(
                          message: 'All caught up! No pending assignments.',
                          icon: Icons.thumb_up_alt_rounded,
                        );
                      }

                      return Column(
                        children: activeAssigns.take(2).map((a) {
                          final subjects = subjectState.value ?? [];
                          final sub = subjects.firstWhere((s) => s.id == a.subjectId, orElse: () => subjects.first);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Due: ${DateFormat('MMM d').format(a.dueDate)} | ${sub.code}'),
                              trailing: Icon(
                                Icons.circle,
                                color: a.priority == 2 ? Colors.red : (a.priority == 1 ? Colors.orange : Colors.green),
                                size: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 24),

                  // Recent lecture notes
                  _buildSectionHeader(context, "Recently Accessed Notes", () => context.go('/notes')),
                  const SizedBox(height: 12),
                  notesState.when(
                    data: (notes) {
                      if (notes.isEmpty) {
                        return const _DashboardEmptyCard(
                          message: 'No study notes recorded yet.',
                          icon: Icons.note_alt_rounded,
                        );
                      }

                      return Column(
                        children: notes.take(3).map((n) {
                          final subjects = subjectState.value ?? [];
                          final sub = subjects.firstWhere((s) => s.id == n.subjectId, orElse: () => subjects.first);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.note_rounded, color: Colors.blueAccent),
                              title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Subject: ${sub.code} | Updated: ${DateFormat('MMM d').format(n.updatedAt)}'),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text('View All'),
        ),
      ],
    );
  }
}

class _HeaderQuickStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _HeaderQuickStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            foregroundColor: color,
            child: Icon(icon, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _LoadingStatCard extends StatelessWidget {
  const _LoadingStatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  final String message;
  final IconData icon;

  const _DashboardEmptyCard({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
