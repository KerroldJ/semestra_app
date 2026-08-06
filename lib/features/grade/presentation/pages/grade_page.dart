import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/grade/presentation/providers/grade_provider.dart';
import 'package:semestra_app/features/subject/presentation/providers/subject_provider.dart';
import 'package:semestra_app/features/grade/domain/entities/grade_entity.dart';
import 'package:semestra_app/core/theme/app_theme.dart';

class GradePage extends ConsumerWidget {
  const GradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradeState = ref.watch(gradeNotifierProvider);
    final subjectState = ref.watch(subjectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Tracker & GPA'),
      ),
      body: subjectState.when(
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Please create Subjects in the Subject Registry before tracking grades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return gradeState.when(
            data: (grades) {
              // Perform GPA & averages calculations
              final calculations = _calculateGPA(subjects, grades);

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // GPA Summary card
                        _GPASummaryCard(
                          semesterGPA: calculations.gpa,
                          totalUnits: calculations.totalUnits,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subject Performance',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showAddGradeDialog(context, ref, subjects),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Score'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (grades.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Text('No scores logged yet. Add your quiz or exam grades!'),
                            ),
                          ),
                        ...calculations.subjectSummaries.map((summary) {
                          final subjectGrades = grades.where((g) => g.subjectId == summary.subject.id).toList();
                          return _SubjectGradeExpansionTile(
                            summary: summary,
                            grades: subjectGrades,
                          );
                        }).toList(),
                      ]),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading grades: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading subjects: $err')),
      ),
    );
  }

  _GpaCalculations _calculateGPA(List<dynamic> subjects, List<GradeEntity> grades) {
    double totalWeightedGpaPoints = 0.0;
    double totalUnits = 0.0;
    final summaries = <_SubjectGradeSummary>[];

    for (final subject in subjects) {
      final subjectGrades = grades.where((g) => g.subjectId == subject.id).toList();
      
      double totalWeight = 0.0;
      double weightedScoreSum = 0.0;
      
      for (final grade in subjectGrades) {
        totalWeight += grade.weight;
        weightedScoreSum += grade.weightedScore; // e.g. (obtained/max) * weight
      }

      double subjectPercentage = 0.0;
      if (totalWeight > 0) {
        // Normalize percentage to scale up to 100%
        subjectPercentage = (weightedScoreSum / totalWeight) * 100;
      }

      // Convert percentage to GPA points (4.0 scale)
      double gpaPoints = 0.0;
      String gradeLetter = 'F';
      if (subjectPercentage >= 90) {
        gpaPoints = 4.0;
        gradeLetter = 'A';
      } else if (subjectPercentage >= 80) {
        gpaPoints = 3.0;
        gradeLetter = 'B';
      } else if (subjectPercentage >= 70) {
        gpaPoints = 2.0;
        gradeLetter = 'C';
      } else if (subjectPercentage >= 60) {
        gpaPoints = 1.0;
        gradeLetter = 'D';
      }

      if (subjectGrades.isNotEmpty) {
        totalWeightedGpaPoints += gpaPoints * subject.units;
        totalUnits += subject.units;
      }

      summaries.add(_SubjectGradeSummary(
        subject: subject,
        averagePercentage: subjectPercentage,
        gpaPoints: gpaPoints,
        gradeLetter: gradeLetter,
      ));
    }

    final finalGpa = totalUnits > 0 ? totalWeightedGpaPoints / totalUnits : 0.0;

    return _GpaCalculations(
      gpa: finalGpa,
      totalUnits: totalUnits,
      subjectSummaries: summaries,
    );
  }

  void _showAddGradeDialog(BuildContext context, WidgetRef ref, List<dynamic> subjects) {
    String selectedSubjectId = subjects.first.id;
    final assessmentController = TextEditingController();
    final weightController = TextEditingController(text: '20'); // Default weight 20%
    final scoreObtainedController = TextEditingController();
    final scoreMaxController = TextEditingController(text: '100'); // Default max 100

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Assessment Grade'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map<DropdownMenuItem<String>>((sub) {
                        return DropdownMenuItem<String>(
                          value: sub.id as String,
                          child: Text('${sub.code} - ${sub.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSubjectId = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: assessmentController,
                      decoration: const InputDecoration(labelText: 'Assessment (e.g. Midterm, Quiz 1)'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: scoreObtainedController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Score Obtained'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: scoreMaxController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Out of (Max Score)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight Percentage (%)',
                        hintText: 'e.g. 20 for 20%',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = assessmentController.text.trim();
                    final weight = double.tryParse(weightController.text) ?? 0.0;
                    final scoreObtained = double.tryParse(scoreObtainedController.text) ?? 0.0;
                    final scoreMax = double.tryParse(scoreMaxController.text) ?? 100.0;

                    if (name.isNotEmpty && scoreMax > 0) {
                      // Basic grade letter mapping for logs
                      final pct = (scoreObtained / scoreMax) * 100;
                      String letter = 'F';
                      if (pct >= 90) {
                        letter = 'A';
                      } else if (pct >= 80) {
                        letter = 'B';
                      } else if (pct >= 70) {
                        letter = 'C';
                      } else if (pct >= 60) {
                        letter = 'D';
                      }

                      ref.read(gradeNotifierProvider.notifier).addGrade(
                            subjectId: selectedSubjectId,
                            assessmentName: name,
                            weight: weight,
                            scoreObtained: scoreObtained,
                            scoreMax: scoreMax,
                            gradeLetter: letter,
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GpaCalculations {
  final double gpa;
  final double totalUnits;
  final List<_SubjectGradeSummary> subjectSummaries;

  _GpaCalculations({
    required this.gpa,
    required this.totalUnits,
    required this.subjectSummaries,
  });
}

class _SubjectGradeSummary {
  final dynamic subject;
  final double averagePercentage;
  final double gpaPoints;
  final String gradeLetter;

  _SubjectGradeSummary({
    required this.subject,
    required this.averagePercentage,
    required this.gpaPoints,
    required this.gradeLetter,
  });
}

class _GPASummaryCard extends StatelessWidget {
  final double semesterGPA;
  final double totalUnits;

  const _GPASummaryCard({required this.semesterGPA, required this.totalUnits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppTheme.primaryGradient),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEMESTER GPA',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                semesterGPA.toStringAsFixed(2),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 36,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 8),
              Text(
                '$totalUnits Graded Units',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubjectGradeExpansionTile extends ConsumerWidget {
  final _SubjectGradeSummary summary;
  final List<GradeEntity> grades;

  const _SubjectGradeExpansionTile({required this.summary, required this.grades});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subjectColor = Color(summary.subject.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: subjectColor, shape: BoxShape.circle),
        ),
        title: Text(
          '${summary.subject.code}: ${summary.subject.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Avg: ${summary.averagePercentage.toStringAsFixed(1)}% (${summary.gradeLetter}) | GPA: ${summary.gpaPoints.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        children: [
          if (grades.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No individual assessments logged.'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                return ListTile(
                  title: Text(grade.assessmentName),
                  subtitle: Text('Weight: ${grade.weight}% | Score: ${grade.scoreObtained}/${grade.scoreMax}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${grade.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () {
                          ref.read(gradeNotifierProvider.notifier).deleteGrade(grade.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
