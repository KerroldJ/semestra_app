import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/study_timer/presentation/providers/study_session_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class StudyTimerPage extends ConsumerWidget {
  const StudyTimerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(pomodoroTimerProvider);
    final historyState = ref.watch(studySessionHistoryProvider);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final theme = Theme.of(context);

    // Format remaining time (MM:SS)
    final minutes = (timerState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    // Calculate progress percentage
    final progress = timerState.initialSeconds > 0
        ? timerState.remainingSeconds / timerState.initialSeconds
        : 1.0;

    // Session type strings
    String stateLabel = 'Focus Session';
    if (timerState.sessionType == 1) stateLabel = 'Short Break';
    else if (timerState.sessionType == 2) stateLabel = 'Long Break';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Study Timer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Circular timer widget
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timerState.sessionType == 0
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeStr,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Subject selector
            if (timerState.sessionType == 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String?>(
                    value: timerState.activeSubjectId,
                    decoration: const InputDecoration(
                      labelText: 'Tag Study to Subject',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('General Focus (No Subject)')),
                      ...subjects.map((sub) {
                        return DropdownMenuItem(
                          value: sub.id,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      ref.read(pomodoroTimerProvider.notifier).selectSubject(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Timer Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: () => ref.read(pomodoroTimerProvider.notifier).resetTimer(),
                ),
                const SizedBox(width: 24),
                FloatingActionButton.large(
                  backgroundColor: timerState.sessionType == 0
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF10B981),
                  child: Icon(
                    timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (timerState.isRunning) {
                      ref.read(pomodoroTimerProvider.notifier).pauseTimer();
                    } else {
                      ref.read(pomodoroTimerProvider.notifier).startTimer();
                    }
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () {
                    int nextType = 0;
                    if (timerState.sessionType == 0) {
                      nextType = 1;
                    } else {
                      nextType = 0;
                    }
                    ref.read(pomodoroTimerProvider.notifier).changeSessionType(nextType);
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Statistics panels
            historyState.when(
              data: (sessions) {
                final focusSessions = sessions.where((s) => s.sessionType == 0).toList();
                final totalMinutes = focusSessions.fold<int>(0, (prev, s) => prev + (s.durationSeconds ~/ 60));
                final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Statistics',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: '${focusSessions.length}',
                            label: 'Focus Intervals',
                            icon: Icons.timer_rounded,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            value: '$totalHours hrs',
                            label: 'Total Hours',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.displayLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
