import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:semestra_app/core/widgets/lottie_header.dart';

// Providers
import 'package:semestra_app/features/semester/presentation/providers/semester_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:semestra_app/features/item/presentation/providers/item_provider.dart';
import 'package:semestra_app/features/item/domain/entities/item_entity.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentDayOfWeek = DateTime.now().weekday; // 1 = Monday, 7 = Sunday

    // Ensure these providers stay alive so their data is ready across the app.
    ref.watch(semesterNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final itemsState = ref.watch(itemNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: LottieHeader(
                url: 'https://assets10.lottiefiles.com/packages/lf20_1a8dx7zj.json',
                title: 'Hey there! 👋',
                subtitle: 'Let\'s make today productive',
                height: 110,
                fallbackIcon: Icons.emoji_emotions_rounded,
              ),
            ),
            // Greeting Banner
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

            // Top summary cards
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    itemsState.when(
                      data: (items) {
                        final pending = items
                            .where((i) => i.type == ItemType.assignment && i.status != 2)
                            .length;
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
                    itemsState.when(
                      data: (items) {
                        final openTasks = items
                            .where((i) => i.type == ItemType.task && i.status != 2)
                            .length;
                        return _HeaderQuickStatCard(
                          title: 'Tasks',
                          value: '$openTasks To Do',
                          icon: Icons.checklist_rounded,
                          color: const Color(0xFF6366F1),
                        );
                      },
                      loading: () => const _LoadingStatCard(),
                      error: (_, __) => const _LoadingStatCard(),
                    ),
                    const SizedBox(width: 16),
                    itemsState.when(
                      data: (items) {
                        final notes =
                            items.where((i) => i.type == ItemType.note).length;
                        return _HeaderQuickStatCard(
                          title: 'Notes',
                          value: '$notes Saved',
                          icon: Icons.sticky_note_2_rounded,
                          color: const Color(0xFF10B981),
                        );
                      },
                      loading: () => const _LoadingStatCard(),
                      error: (_, __) => const _LoadingStatCard(),
                    ),
                  ],
                ),
              ),
            ),

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
                      final todayClasses =
                          schedules.where((s) => s.dayOfWeek == currentDayOfWeek).toList();
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
                  _buildSectionHeader(context, "Upcoming Assignments", () => context.go('/planner')),
                  const SizedBox(height: 12),
                  itemsState.when(
                    data: (items) {
                      final activeAssigns = items
                          .where((i) => i.type == ItemType.assignment && i.status != 2)
                          .toList();
                      activeAssigns.sort((a, b) => (a.dueDate ?? DateTime(2100))
                          .compareTo(b.dueDate ?? DateTime(2100)));

                      if (activeAssigns.isEmpty) {
                        return const _DashboardEmptyCard(
                          message: 'All caught up! No pending assignments.',
                          icon: Icons.thumb_up_alt_rounded,
                        );
                      }

                      return Column(
                        children: activeAssigns.take(2).map((a) {
                          final subjects = subjectState.value ?? [];
                          final sub = subjects.firstWhere(
                            (s) => s.id == a.subjectId,
                            orElse: () => subjects.first,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                a.dueDate != null
                                    ? 'Due: ${DateFormat('MMM d').format(a.dueDate!)} | ${sub.code}'
                                    : sub.code,
                              ),
                              trailing: Icon(
                                Icons.circle,
                                color: a.priority == 2
                                    ? Colors.red
                                    : (a.priority == 1 ? Colors.orange : Colors.green),
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

                  // Recent notes
                  _buildSectionHeader(context, "Recently Accessed Notes", () => context.go('/planner')),
                  const SizedBox(height: 12),
                  itemsState.when(
                    data: (items) {
                      final notes = items.where((i) => i.type == ItemType.note).toList();
                      if (notes.isEmpty) {
                        return const _DashboardEmptyCard(
                          message: 'No study notes recorded yet.',
                          icon: Icons.note_alt_rounded,
                        );
                      }

                      return Column(
                        children: notes.take(3).map((n) {
                          final subjects = subjectState.value ?? [];
                          final sub = subjects.firstWhere(
                            (s) => s.id == n.subjectId,
                            orElse: () => subjects.first,
                          );
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
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        TextButton(onPressed: onTap, child: const Text('View All')),
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
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
              child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
