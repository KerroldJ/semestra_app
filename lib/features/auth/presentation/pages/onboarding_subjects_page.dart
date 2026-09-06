import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';

/// Screen 04 — add your subjects. Writes real subjects (and, on first run, an
/// active semester) via the existing providers.
class OnboardingSubjectsPage extends ConsumerStatefulWidget {
  const OnboardingSubjectsPage({super.key});

  @override
  ConsumerState<OnboardingSubjectsPage> createState() =>
      _OnboardingSubjectsPageState();
}

class _OnboardingSubjectsPageState
    extends ConsumerState<OnboardingSubjectsPage> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  int _spineIndex = 0;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Ensures there is an active semester to attach subjects to. Creates a
  /// sensible default term spanning ~15 weeks if none exists yet.
  Future<String> _ensureSemester() async {
    final semesters = ref.read(semesterNotifierProvider).value ?? [];
    if (semesters.isNotEmpty) {
      final active = semesters.firstWhere(
        (s) => s.isActive,
        orElse: () => semesters.first,
      );
      return active.id;
    }
    final now = DateTime.now();
    final termName = '${now.month >= 6 ? 'Fall' : 'Spring'} ${now.year}';
    await ref.read(semesterNotifierProvider.notifier).addSemester(
          name: termName,
          startDate: now,
          endDate: now.add(const Duration(days: 7 * 15)),
          isActive: true,
        );
    final refreshed = ref.read(semesterNotifierProvider).value ?? [];
    return refreshed
        .firstWhere((s) => s.isActive, orElse: () => refreshed.first)
        .id;
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final semesterId = await _ensureSemester();
    final code =
        _code.text.trim().isEmpty ? _autoCode(name) : _code.text.trim().toUpperCase();
    await ref.read(subjectNotifierProvider.notifier).addSubject(
          semesterId: semesterId,
          code: code,
          name: name,
          instructor: '',
          classroom: '',
          units: 3,
          colorValue: _spineIndex, // stored as a spine palette index
        );
    _name.clear();
    _code.clear();
    setState(() => _spineIndex = (_spineIndex + 1) % AppTheme.spinePalette.length);
  }

  String _autoCode(String name) {
    final letters = name.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return (letters.length >= 3 ? letters.substring(0, 3) : letters)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StepDots(step: 1),
              const SizedBox(height: 24),
              Text('Add your subjects',
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                'These become the spine of everything — classes, notes and '
                'deadlines all hang off a subject.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppTheme.inkMuted, height: 1.5),
              ),
              const SizedBox(height: 22),
              _SpinePicker(
                selected: _spineIndex,
                onSelect: (i) => setState(() => _spineIndex = i),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'CODE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      decoration:
                          const InputDecoration(hintText: 'Subject name'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _add,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: subjects.isEmpty
                    ? Center(
                        child: Text('No subjects yet',
                            style: theme.textTheme.bodyMedium),
                      )
                    : ListView.separated(
                        itemCount: subjects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _SubjectRow(subject: subjects[i]),
                      ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      subjects.isEmpty ? null : () => context.go('/onboarding/schedule'),
                  child: Text(subjects.isEmpty
                      ? 'Add at least one subject'
                      : 'Continue (${subjects.length})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final SubjectEntity subject;
  const _SubjectRow({required this.subject});

  @override
  Widget build(BuildContext context) {
    final spine = AppTheme.spineFor(subject.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 34,
            decoration: BoxDecoration(
              color: spine,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 14),
          if (subject.code.isNotEmpty) ...[
            Text(subject.code,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppTheme.goldDeep)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(subject.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _SpinePicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SpinePicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(AppTheme.spinePalette.length, (i) {
        final c = AppTheme.spinePalette[i];
        final isSel = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: isSel
                  ? Border.all(color: AppTheme.ink, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
          ),
        );
      }),
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
