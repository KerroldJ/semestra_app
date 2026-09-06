import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/format.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../schedule/domain/entities/schedule_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../auth_provider.dart';

/// Screen 05 — class times. Optional: users can add a few weekly class blocks
/// now or skip. Finishing either way completes onboarding.
class OnboardingSchedulePage extends ConsumerStatefulWidget {
  const OnboardingSchedulePage({super.key});

  @override
  ConsumerState<OnboardingSchedulePage> createState() =>
      _OnboardingSchedulePageState();
}

class _OnboardingSchedulePageState
    extends ConsumerState<OnboardingSchedulePage> {
  String? _subjectId;
  final Set<int> _days = {DateTime.now().weekday};
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked != null) {
      setState(() => start ? _start = picked : _end = picked);
    }
  }

  Future<void> _addClass(List<SubjectEntity> subjects) async {
    final id = _subjectId ?? (subjects.isNotEmpty ? subjects.first.id : null);
    if (id == null || _days.isEmpty) return;
    final subject = subjects.firstWhere((s) => s.id == id);
    final notifier = ref.read(scheduleNotifierProvider.notifier);
    for (final day in _days) {
      await notifier.addSchedule(
        subjectId: id,
        dayOfWeek: day,
        startTime: Fmt.hhmmFromTod(_start),
        endTime: Fmt.hhmmFromTod(_end),
        classroom: subject.classroom,
        instructor: subject.instructor,
        type: 0,
      );
    }
    setState(() {});
  }

  Future<void> _finish() =>
      ref.read(authNotifierProvider.notifier).completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final schedules = ref.watch(scheduleNotifierProvider).value ?? [];
    _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;
    final subjectsById = {for (final s in subjects) s.id: s};

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _StepDots(step: 2),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Add class times',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'Optional — drop in your weekly classes so Today and Planner '
                'come alive. You can always add more later.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppTheme.inkMuted, height: 1.5),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    Text('SUBJECT', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 10),
                    _SubjectChips(
                      subjects: subjects,
                      selectedId: _subjectId,
                      onSelect: (id) => setState(() => _subjectId = id),
                    ),
                    const SizedBox(height: 20),
                    Text('DAYS', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 10),
                    _DayPicker(
                      selected: _days,
                      onToggle: (d) => setState(() {
                        _days.contains(d) ? _days.remove(d) : _days.add(d);
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: 'Start',
                            value: _start.format(context),
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TimeField(
                            label: 'End',
                            value: _end.format(context),
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: subjects.isEmpty
                            ? null
                            : () => _addClass(subjects),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add class block'),
                      ),
                    ),
                    if (schedules.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('ADDED', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 10),
                      ...schedules.map((s) => _ClassLine(
                            schedule: s,
                            subject: subjectsById[s.subjectId],
                          )),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finish,
                  child: Text(schedules.isEmpty
                      ? 'Finish'
                      : 'Finish (${schedules.length} added)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassLine extends StatelessWidget {
  final ScheduleEntity schedule;
  final SubjectEntity? subject;
  const _ClassLine({required this.schedule, required this.subject});

  @override
  Widget build(BuildContext context) {
    final spine = subject != null
        ? AppTheme.spineFor(subject!.colorValue)
        : AppTheme.inkFaint;
    final dayAbbr = Fmt.weekdayAbbr[(schedule.dayOfWeek - 1).clamp(0, 6)];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 2, height: 26, color: spine),
          const SizedBox(width: 12),
          Expanded(
            child: Text(subject?.name ?? 'Class',
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '$dayAbbr · ${Fmt.time12(schedule.startTime)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.merge(AppTheme.tnum),
          ),
        ],
      ),
    );
  }
}

class _SubjectChips extends StatelessWidget {
  final List<SubjectEntity> subjects;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _SubjectChips({
    required this.subjects,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Text('Add a subject first',
          style: Theme.of(context).textTheme.bodyMedium);
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: subjects.map((s) {
        final selected = s.id == selectedId;
        final spine = AppTheme.spineFor(s.colorValue);
        return GestureDetector(
          onTap: () => onSelect(s.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppTheme.gold : AppTheme.hairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2, height: 14, color: spine),
                const SizedBox(width: 8),
                Text(s.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  const _DayPicker({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1; // 1..7
        final sel = selected.contains(day);
        return Expanded(
          child: GestureDetector(
            onTap: () => onToggle(day),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppTheme.gold : AppTheme.hairline,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Text(
                Fmt.weekdayAbbr[i].substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: sel ? AppTheme.goldDeep : AppTheme.inkMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.hairline),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 17, color: AppTheme.inkFaint),
                const SizedBox(width: 8),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.merge(AppTheme.tnum)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDots extends StatelessWidget {
  final int step;
  const _StepDots({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i == step;
        return Container(
          margin: const EdgeInsets.only(right: 8),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active ? AppTheme.gold : AppTheme.hairline,
          ),
        );
      }),
    );
  }
}
