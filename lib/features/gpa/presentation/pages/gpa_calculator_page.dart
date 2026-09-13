import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../semester/domain/entities/semester_entity.dart';
import '../../../semester/presentation/providers/semester_provider.dart';
import '../../../subject/domain/entities/subject_entity.dart';
import '../../../subject/presentation/providers/subject_provider.dart';
import '../../domain/gpa_calculator.dart';

class GpaCalculatorPage extends ConsumerStatefulWidget {
  const GpaCalculatorPage({super.key});

  @override
  ConsumerState<GpaCalculatorPage> createState() => _GpaCalculatorPageState();
}

class _GpaCalculatorPageState extends ConsumerState<GpaCalculatorPage> {
  final List<_CourseGradeRow> _rows = [];
  bool _seeded = false;
  String? _selectedSemesterId;
  int _selectedMode = 0;
  GradingSystem _selectedGradingSystem = GradingSystem.philippine;
  double? _savedGpa;

  // Cumulative mode controllers
  final TextEditingController _priorGpaController = TextEditingController();
  final TextEditingController _priorUnitsController = TextEditingController();
  final TextEditingController _currentSemGpaController =
      TextEditingController();
  final TextEditingController _currentSemUnitsController =
      TextEditingController();
  bool _useCurrentTableForCumulative = true;

  // Target GPA mode controllers
  final TextEditingController _targetCurrentGpaController =
      TextEditingController();
  final TextEditingController _targetCurrentUnitsController =
      TextEditingController();
  final TextEditingController _targetGoalGpaController =
      TextEditingController();
  final TextEditingController _targetRemainingUnitsController =
      TextEditingController();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _priorGpaController.dispose();
    _priorUnitsController.dispose();
    _currentSemGpaController.dispose();
    _currentSemUnitsController.dispose();
    _targetCurrentGpaController.dispose();
    _targetCurrentUnitsController.dispose();
    _targetGoalGpaController.dispose();
    _targetRemainingUnitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectNotifierProvider).value ?? [];
    final semesters = ref.watch(semesterNotifierProvider).value ?? [];
    _seedRows(subjects, semesters);

    final activeSemester = _activeSemester(semesters);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gpa = GpaCalculator.calculate(
      _rows.map((row) => row.input).toList(),
      gradingSystem: _selectedGradingSystem,
    );
    final completedRows = _rows
        .where(
          (row) =>
              row.input.gradePoint != null &&
              _selectedGradingSystem.isValidGrade(row.input.gradePoint!),
        )
        .length;
    final totalUnits = _rows.fold<double>(
      0,
      (sum, row) => sum + row.input.units,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF07140F)
          : Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _Header(onBack: () => context.pop()),
            const SizedBox(height: 14),
            _GpaHero(gpa: gpa, totalUnits: totalUnits, isSaved: _isSaved(gpa)),
            const SizedBox(height: 12),
            _ModeTabs(
              selectedIndex: _selectedMode,
              onChanged: (index) => setState(() => _selectedMode = index),
            ),
            const SizedBox(height: 12),
            if (_selectedMode == 0) ...[
              _SemesterSelector(
                label: activeSemester?.name ?? 'Current Semester',
                onTap: semesters.isNotEmpty
                    ? () => _showSemesterPicker(context, semesters, subjects)
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            _GradingSystemCard(
              gradingSystem: _selectedGradingSystem,
              onTap: () => _showGradingSystemPicker(context),
            ),
            const SizedBox(height: 12),
            if (_selectedMode == 0)
              _SubjectsPanel(
                rows: _rows,
                completedRows: completedRows,
                totalUnits: totalUnits,
                onChanged: () => setState(() {}),
                onAdd: _addBlankRow,
                onRemove: (row) {
                  if (_rows.length <= 1) return;
                  setState(() {
                    row.dispose();
                    _rows.remove(row);
                  });
                },
              )
            else if (_selectedMode == 1)
              _CumulativeGpaPanel(
                gradingSystem: _selectedGradingSystem,
                priorGpaController: _priorGpaController,
                priorUnitsController: _priorUnitsController,
                currentSemGpaController: _currentSemGpaController,
                currentSemUnitsController: _currentSemUnitsController,
                useCurrentTable: _useCurrentTableForCumulative,
                onToggleUseCurrentTable: (val) =>
                    setState(() => _useCurrentTableForCumulative = val),
                currentSemesterGpa: gpa,
                currentSemesterUnits: totalUnits,
                onChanged: () => setState(() {}),
              )
            else
              _TargetGpaPanel(
                gradingSystem: _selectedGradingSystem,
                currentGpaController: _targetCurrentGpaController,
                currentUnitsController: _targetCurrentUnitsController,
                targetGoalGpaController: _targetGoalGpaController,
                remainingUnitsController: _targetRemainingUnitsController,
                onChanged: () => setState(() {}),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(
        onCalculate: () {
          if (_selectedMode == 0) {
            if (gpa == null) {
              AppToast.error(
                'Please enter valid grades (${_selectedGradingSystem.hintText}) and units',
              );
              return;
            }
            _showGpaResultSheet(context, gpa, totalUnits, completedRows);
          } else if (_selectedMode == 1) {
            final priorGpa = double.tryParse(_priorGpaController.text.trim());
            final priorUnits =
                double.tryParse(_priorUnitsController.text.trim());

            double? curGpa;
            double? curUnits;

            if (_useCurrentTableForCumulative) {
              curGpa = gpa;
              curUnits = totalUnits;
            } else {
              curGpa = double.tryParse(_currentSemGpaController.text.trim());
              curUnits =
                  double.tryParse(_currentSemUnitsController.text.trim());
            }

            if (priorGpa == null ||
                priorUnits == null ||
                !_selectedGradingSystem.isValidGrade(priorGpa) ||
                priorUnits <= 0) {
              AppToast.error(
                'Enter valid prior GPA (${_selectedGradingSystem.hintText}) and units',
              );
              return;
            }

            if (curGpa == null ||
                curUnits == null ||
                !_selectedGradingSystem.isValidGrade(curGpa) ||
                curUnits <= 0) {
              AppToast.error(
                'Enter valid current semester GPA (${_selectedGradingSystem.hintText}) and units',
              );
              return;
            }

            final cumGpa = GpaCalculator.calculateCumulative(
              priorGpa: priorGpa,
              priorUnits: priorUnits,
              currentGpa: curGpa,
              currentUnits: curUnits,
            );

            if (cumGpa == null) {
              AppToast.error('Could not compute cumulative GPA');
              return;
            }

            _showCumulativeResultSheet(
              context,
              cumulativeGpa: cumGpa,
              priorGpa: priorGpa,
              priorUnits: priorUnits,
              currentGpa: curGpa,
              currentUnits: curUnits,
            );
          } else {
            final currentGpa =
                double.tryParse(_targetCurrentGpaController.text.trim());
            final currentUnits =
                double.tryParse(_targetCurrentUnitsController.text.trim());
            final targetGoal =
                double.tryParse(_targetGoalGpaController.text.trim());
            final remainingUnits =
                double.tryParse(_targetRemainingUnitsController.text.trim());

            if (currentGpa == null ||
                currentUnits == null ||
                !_selectedGradingSystem.isValidGrade(currentGpa) ||
                currentUnits <= 0) {
              AppToast.error(
                'Enter valid current GPA (${_selectedGradingSystem.hintText}) and units',
              );
              return;
            }

            if (targetGoal == null ||
                !_selectedGradingSystem.isValidGrade(targetGoal)) {
              AppToast.error(
                'Enter a valid target goal GPA (${_selectedGradingSystem.hintText})',
              );
              return;
            }

            if (remainingUnits == null || remainingUnits <= 0) {
              AppToast.error('Enter valid remaining units to take');
              return;
            }

            final evaluation = GpaCalculator.evaluateTarget(
              currentGpa: currentGpa,
              currentUnits: currentUnits,
              targetGpa: targetGoal,
              remainingUnits: remainingUnits,
              gradingSystem: _selectedGradingSystem,
            );

            if (evaluation == null) {
              AppToast.error('Could not evaluate target GPA');
              return;
            }

            _showTargetResultSheet(
              context,
              evaluation: evaluation,
              currentGpa: currentGpa,
              currentUnits: currentUnits,
              targetGoal: targetGoal,
              remainingUnits: remainingUnits,
            );
          }
        },
        onSave: () {
          if (_selectedMode == 0) {
            if (gpa == null) {
              AppToast.error('Add valid grades before saving');
              return;
            }
            setState(() => _savedGpa = gpa);
            AppToast.success('Semester GPA result saved');
          } else if (_selectedMode == 1) {
            final priorGpa = double.tryParse(_priorGpaController.text.trim());
            final priorUnits =
                double.tryParse(_priorUnitsController.text.trim());
            double? curGpa = _useCurrentTableForCumulative
                ? gpa
                : double.tryParse(_currentSemGpaController.text.trim());
            double? curUnits = _useCurrentTableForCumulative
                ? totalUnits
                : double.tryParse(_currentSemUnitsController.text.trim());

            if (priorGpa != null &&
                priorUnits != null &&
                curGpa != null &&
                curUnits != null) {
              final cumGpa = GpaCalculator.calculateCumulative(
                priorGpa: priorGpa,
                priorUnits: priorUnits,
                currentGpa: curGpa,
                currentUnits: curUnits,
              );
              if (cumGpa != null) {
                setState(() => _savedGpa = cumGpa);
                AppToast.success('Cumulative GPA result saved');
                return;
              }
            }
            AppToast.error('Enter all cumulative details before saving');
          } else {
            AppToast.info('Target GPA calculations are for goal planning');
          }
        },
      ),
    );
  }

  void _showGradingSystemPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF10231A) : Colors.white;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.hairlineBorder(sheetContext),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Select Grading System',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF133B2D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the scale used by your institution to calculate GPA',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : const Color(0xFF5E796D),
                ),
              ),
              const SizedBox(height: 16),
              for (final system in GradingSystem.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _selectedGradingSystem = system);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedGradingSystem == system
                            ? AppTheme.accent(sheetContext).withValues(
                                alpha: isDark ? 0.2 : 0.1,
                              )
                            : (isDark
                                ? const Color(0xFF0D1B15)
                                : const Color(0xFFF7FCF9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedGradingSystem == system
                              ? AppTheme.accent(sheetContext)
                              : AppTheme.hairlineBorder(sheetContext),
                          width: _selectedGradingSystem == system ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  system.name,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedGradingSystem == system
                                        ? AppTheme.accent(sheetContext)
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF17382C)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  system.description,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF5F7A6E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedGradingSystem == system)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.accent(sheetContext),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showGpaResultSheet(
    BuildContext context,
    double gpa,
    double totalUnits,
    int completedRows,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF10231A) : Colors.white;
        final remark = _selectedGradingSystem.getRemark(gpa);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.hairlineBorder(sheetContext),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.accent(sheetContext).withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: AppTheme.accent(sheetContext),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester GPA Result',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Calculated Semester Grade Point Average',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A1812)
                      : const Color(0xFFF3FAF6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.hairlineBorder(sheetContext)),
                ),
                child: Column(
                  children: [
                    Text(
                      gpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: AppTheme.accent(sheetContext),
                      ).merge(AppTheme.tnum),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent(sheetContext).withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        remark,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent(sheetContext),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              _formatNumber(totalUnits),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Total Units',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppTheme.hairlineBorder(sheetContext),
                        ),
                        Column(
                          children: [
                            Text(
                              '$completedRows',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Subjects',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white70
                            : const Color(0xFF557064),
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(
                            color: AppTheme.hairlineBorder(sheetContext)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() => _savedGpa = gpa);
                        Navigator.of(sheetContext).pop();
                        AppToast.success('GPA result saved');
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save Result'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent(sheetContext),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCumulativeResultSheet(
    BuildContext context, {
    required double cumulativeGpa,
    required double priorGpa,
    required double priorUnits,
    required double currentGpa,
    required double currentUnits,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF10231A) : Colors.white;
        final remark = _selectedGradingSystem.getRemark(cumulativeGpa);
        final totalUnits = priorUnits + currentUnits;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.hairlineBorder(sheetContext),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D8CE2).withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      color: Color(0xFF2D8CE2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cumulative GPA Result',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Overall Combined Academic Performance',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A1812)
                      : const Color(0xFFF3FAF6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.hairlineBorder(sheetContext)),
                ),
                child: Column(
                  children: [
                    Text(
                      cumulativeGpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: AppTheme.accent(sheetContext),
                      ).merge(AppTheme.tnum),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent(sheetContext).withValues(
                          alpha: isDark ? 0.25 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        remark,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accent(sheetContext),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${priorGpa.toStringAsFixed(2)} (${_formatNumber(priorUnits)}u)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Prior Record',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppTheme.hairlineBorder(sheetContext),
                        ),
                        Column(
                          children: [
                            Text(
                              '${currentGpa.toStringAsFixed(2)} (${_formatNumber(currentUnits)}u)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Current Term',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppTheme.hairlineBorder(sheetContext),
                        ),
                        Column(
                          children: [
                            Text(
                              _formatNumber(totalUnits),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Total Units',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white70
                            : const Color(0xFF557064),
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(
                            color: AppTheme.hairlineBorder(sheetContext)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() => _savedGpa = cumulativeGpa);
                        Navigator.of(sheetContext).pop();
                        AppToast.success('Cumulative GPA result saved');
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save Result'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent(sheetContext),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTargetResultSheet(
    BuildContext context, {
    required TargetGpaEvaluation evaluation,
    required double currentGpa,
    required double currentUnits,
    required double targetGoal,
    required double remainingUnits,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF10231A) : Colors.white;

        Color badgeColor;
        String badgeText;
        IconData badgeIcon;

        switch (evaluation.feasibility) {
          case TargetFeasibility.achievable:
            badgeColor = const Color(0xFF20A779);
            badgeText = 'Target Achievable';
            badgeIcon = Icons.check_circle_rounded;
            break;
          case TargetFeasibility.challenging:
            badgeColor = const Color(0xFFF39C12);
            badgeText = 'Challenging Goal';
            badgeIcon = Icons.warning_amber_rounded;
            break;
          case TargetFeasibility.unachievable:
            badgeColor = const Color(0xFFE74C3C);
            badgeText = 'Target Unachievable';
            badgeIcon = Icons.cancel_rounded;
            break;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.hairlineBorder(sheetContext),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE05A52).withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFFE05A52),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target GPA Analysis',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Required grade average in remaining units',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A1812)
                      : const Color(0xFFF3FAF6),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppTheme.hairlineBorder(sheetContext)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Grade Needed:',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : const Color(0xFF5E796D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evaluation.requiredGpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: badgeColor,
                      ).merge(AppTheme.tnum),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(
                            alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeColor),
                          const SizedBox(width: 4),
                          Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      evaluation.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF4C6A5D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${currentGpa.toStringAsFixed(2)} (${_formatNumber(currentUnits)}u)',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Current',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppTheme.hairlineBorder(sheetContext),
                        ),
                        Column(
                          children: [
                            Text(
                              targetGoal.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Target Goal',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: AppTheme.hairlineBorder(sheetContext),
                        ),
                        Column(
                          children: [
                            Text(
                              _formatNumber(remainingUnits),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A332A),
                              ),
                            ),
                            Text(
                              'Units to Take',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF5E796D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent(sheetContext),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSaved(double? gpa) {
    final savedGpa = _savedGpa;
    if (gpa == null || savedGpa == null) return false;
    return (savedGpa - gpa).abs() < 0.001;
  }

  SemesterEntity? _activeSemester(List<SemesterEntity> semesters) {
    if (semesters.isEmpty) return null;
    if (_selectedSemesterId != null) {
      final match = semesters.where((s) => s.id == _selectedSemesterId);
      if (match.isNotEmpty) return match.first;
    }
    for (final semester in semesters) {
      if (semester.isActive && !semester.isArchived) return semester;
    }
    return semesters.first;
  }

  void _seedRows(List<SubjectEntity> subjects, List<SemesterEntity> semesters) {
    if (_seeded) return;
    _seeded = true;

    final activeSem = _activeSemester(semesters);
    if (activeSem != null) {
      _selectedSemesterId = activeSem.id;
    }

    final visibleSubjects = activeSem == null
        ? subjects
        : subjects.where((s) => s.semesterId == activeSem.id).toList();

    if (visibleSubjects.isEmpty) {
      _rows.addAll([
        _CourseGradeRow.blank(name: 'Web Development', units: 3, grade: 1.50),
        _CourseGradeRow.blank(name: 'Database Systems', units: 3, grade: 1.75),
        _CourseGradeRow.blank(name: 'Systems Analysis', units: 3, grade: 2.00),
        _CourseGradeRow.blank(name: 'PE', units: 2, grade: 1.25),
      ]);
      return;
    }

    _rows.addAll(visibleSubjects.map(_CourseGradeRow.fromSubject));
  }

  void _showSemesterPicker(
    BuildContext context,
    List<SemesterEntity> semesters,
    List<SubjectEntity> subjects,
  ) {
    if (semesters.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF10231A) : Colors.white;
        final active = _activeSemester(semesters);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppTheme.hairlineBorder(sheetContext),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.accent(sheetContext).withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: AppTheme.accent(sheetContext),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Semester',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF133B2D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose semester to load subjects',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF5D7B6F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final sem in semesters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _selectedSemesterId = sem.id;
                          for (final r in _rows) {
                            r.dispose();
                          }
                          _rows.clear();
                          final semSubjects = subjects
                              .where((s) => s.semesterId == sem.id)
                              .toList();
                          if (semSubjects.isNotEmpty) {
                            _rows.addAll(
                              semSubjects.map(_CourseGradeRow.fromSubject),
                            );
                          } else {
                            _rows.add(_CourseGradeRow.blank());
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (active?.id == sem.id)
                              ? AppTheme.accent(sheetContext).withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                )
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : const Color(0xFFF6FAF7)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (active?.id == sem.id)
                                ? AppTheme.accent(sheetContext)
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2ECE6)),
                            width: (active?.id == sem.id) ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                sem.name,
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 14,
                                  fontWeight: (active?.id == sem.id)
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: (active?.id == sem.id)
                                      ? AppTheme.accent(sheetContext)
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF12382C)),
                                ),
                              ),
                            ),
                            if (active?.id == sem.id)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.accent(sheetContext),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _addBlankRow() {
    setState(() => _rows.add(_CourseGradeRow.blank()));
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0D2E25);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF658070);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.white,
              foregroundColor: AppTheme.accent(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GPA Calculator',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compute today. A brighter tomorrow.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterSelector extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SemesterSelector({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          _IconTile(
            icon: Icons.school_rounded,
            color: const Color(0xFF259B6D),
            backgroundColor: const Color(0xFFE2F7EC),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF16392D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF607B70),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF557064),
          ),
        ],
      ),
    );
  }
}

class _GpaHero extends StatelessWidget {
  final double? gpa;
  final double? totalUnits;
  final bool isSaved;

  const _GpaHero({
    this.gpa,
    this.totalUnits,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: 154,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/GPA.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              child: Align(
                alignment: Alignment.topRight,
                child: _GpaStatusBadge(isSaved: isSaved),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpaStatusBadge extends StatelessWidget {
  final bool isSaved;

  const _GpaStatusBadge({required this.isSaved});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xDD1D4C38) : const Color(0xE6E0F7E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 13,
            color: AppTheme.accent(context),
          ),
          const SizedBox(width: 4),
          Text(
            isSaved ? 'Offline Saved' : 'Live Preview',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ModeTabs({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = ['Semester GPA', 'Cumulative', 'Target GPA'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10231A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedIndex == i
                          ? AppTheme.accent(context)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: selectedIndex == i
                              ? Colors.white
                              : isDark
                              ? Colors.white70
                              : const Color(0xFF547063),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradingSystemCard extends StatelessWidget {
  final GradingSystem gradingSystem;
  final VoidCallback onTap;

  const _GradingSystemCard({
    required this.gradingSystem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          _IconTile(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF259B6D),
            backgroundColor: const Color(0xFFE2F7EC),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grading System',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF16392D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  gradingSystem.name,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF607B70),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF557064),
          ),
        ],
      ),
    );
  }
}

class _SubjectsPanel extends StatelessWidget {
  final List<_CourseGradeRow> rows;
  final int completedRows;
  final double totalUnits;
  final VoidCallback onChanged;
  final VoidCallback onAdd;
  final ValueChanged<_CourseGradeRow> onRemove;

  const _SubjectsPanel({
    required this.rows,
    required this.completedRows,
    required this.totalUnits,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _Surface(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              _IconTile(
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF239768),
                backgroundColor: const Color(0xFFE0F7EB),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Subjects',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF15382D),
                  ),
                ),
              ),
              Text(
                '$completedRows subject${completedRows == 1 ? '' : 's'} • ${_formatNumber(totalUnits)} units',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF60796F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < rows.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SubjectGradeRowCard(
                row: rows[index],
                onChanged: onChanged,
                onRemove:
                    rows.length <= 1 ? null : () => onRemove(rows[index]),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Add Subject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent(context),
                side: BorderSide(
                  color: AppTheme.accent(context).withValues(alpha: 0.28),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectGradeRowCard extends StatelessWidget {
  final _CourseGradeRow row;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _SubjectGradeRowCard({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B15) : const Color(0xFFFBFEFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: row.nameController,
                  onChanged: (_) => onChanged(),
                  minLines: 1,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A332A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Subject name',
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _CompactNumberField(
                      label: 'Units',
                      controller: row.unitsController,
                      onChanged: onChanged,
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      color: AppTheme.hairlineBorder(context),
                    ),
                    _CompactNumberField(
                      label: 'Grade',
                      controller: row.gradeController,
                      onChanged: onChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Remove subject',
              visualDensity: VisualDensity.compact,
              color: isDark ? Colors.white70 : const Color(0xFF557064),
            ),
          ],
        ],
      ),
    );
  }
}

class _CumulativeGpaPanel extends StatelessWidget {
  final GradingSystem gradingSystem;
  final TextEditingController priorGpaController;
  final TextEditingController priorUnitsController;
  final TextEditingController currentSemGpaController;
  final TextEditingController currentSemUnitsController;
  final bool useCurrentTable;
  final ValueChanged<bool> onToggleUseCurrentTable;
  final double? currentSemesterGpa;
  final double currentSemesterUnits;
  final VoidCallback onChanged;

  const _CumulativeGpaPanel({
    required this.gradingSystem,
    required this.priorGpaController,
    required this.priorUnitsController,
    required this.currentSemGpaController,
    required this.currentSemUnitsController,
    required this.useCurrentTable,
    required this.onToggleUseCurrentTable,
    required this.currentSemesterGpa,
    required this.currentSemesterUnits,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _Surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(
                    icon: Icons.history_edu_rounded,
                    color: const Color(0xFF2D8CE2),
                    backgroundColor: const Color(0xFFE5F1FC),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prior Academic Record',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Previous semesters before current term',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Prior Cumulative GPA',
                      hintText: gradingSystem.hintText,
                      controller: priorGpaController,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Prior Total Units',
                      hintText: 'e.g. 45',
                      controller: priorUnitsController,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(
                    icon: Icons.class_rounded,
                    color: const Color(0xFF7D62F2),
                    backgroundColor: const Color(0xFFEFEAFC),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Semester',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Incorporate current term grades',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('From Subject List'),
                    selected: useCurrentTable,
                    onSelected: (val) => onToggleUseCurrentTable(true),
                    selectedColor:
                        AppTheme.accent(context).withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: useCurrentTable
                          ? AppTheme.accent(context)
                          : (isDark
                              ? Colors.white70
                              : const Color(0xFF557064)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Manual Entry'),
                    selected: !useCurrentTable,
                    onSelected: (val) => onToggleUseCurrentTable(false),
                    selectedColor:
                        AppTheme.accent(context).withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: !useCurrentTable
                          ? AppTheme.accent(context)
                          : (isDark
                              ? Colors.white70
                              : const Color(0xFF557064)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (useCurrentTable)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF091611)
                        : const Color(0xFFF3FAF6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.hairlineBorder(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Semester Calculated',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF5E796D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentSemesterGpa == null
                                ? 'No grades entered yet in Subject tab'
                                : 'GPA: ${currentSemesterGpa!.toStringAsFixed(2)} • ${_formatNumber(currentSemesterUnits)} Units',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accent(context),
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: AppTheme.accent(context),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _LabeledInputField(
                        label: 'Semester GPA',
                        hintText: gradingSystem.hintText,
                        controller: currentSemGpaController,
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LabeledInputField(
                        label: 'Semester Units',
                        hintText: 'e.g. 18',
                        controller: currentSemUnitsController,
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetGpaPanel extends StatelessWidget {
  final GradingSystem gradingSystem;
  final TextEditingController currentGpaController;
  final TextEditingController currentUnitsController;
  final TextEditingController targetGoalGpaController;
  final TextEditingController remainingUnitsController;
  final VoidCallback onChanged;

  const _TargetGpaPanel({
    required this.gradingSystem,
    required this.currentGpaController,
    required this.currentUnitsController,
    required this.targetGoalGpaController,
    required this.remainingUnitsController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _Surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(
                    icon: Icons.account_balance_rounded,
                    color: const Color(0xFF20A779),
                    backgroundColor: const Color(0xFFE3F7EE),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Standing',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Your overall performance so far',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Current Cumulative GPA',
                      hintText: gradingSystem.hintText,
                      controller: currentGpaController,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Completed Units',
                      hintText: 'e.g. 60',
                      controller: currentUnitsController,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(
                    icon: Icons.flag_rounded,
                    color: const Color(0xFFE05A52),
                    backgroundColor: const Color(0xFFFDECEB),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target Goal',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF133B2D),
                          ),
                        ),
                        Text(
                          'Desired GPA and upcoming units',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF5E796D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Target Goal GPA',
                      hintText: gradingSystem.hintText,
                      controller: targetGoalGpaController,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledInputField(
                      label: 'Remaining Units',
                      hintText: 'e.g. 21',
                      controller: remainingUnitsController,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF091611)
                      : const Color(0xFFF3FAF6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.hairlineBorder(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 16,
                      color: AppTheme.accent(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Computes the exact average grade needed in your remaining units.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF4B695C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabeledInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _LabeledInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF081510) : const Color(0xFFF6FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF5E796D),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [const _DecimalInputFormatter()],
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF133B2D),
            ).merge(AppTheme.tnum),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _CompactNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white60 : const Color(0xFF62796F),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [const _DecimalInputFormatter()],
              minLines: 1,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF243C33),
              ).merge(AppTheme.tnum),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onSave;

  const _BottomActions({required this.onCalculate, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF07140F) : Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.hairlineBorder(context)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onCalculate,
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: const Text('Calculate'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent(context),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Result'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent(context),
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: AppTheme.accent(context)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _Surface({
    required this.child,
    required this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final container = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10231A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.hairlineBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return container;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _CourseGradeRow {
  final TextEditingController nameController;
  final TextEditingController unitsController;
  final TextEditingController gradeController;

  _CourseGradeRow({
    required this.nameController,
    required this.unitsController,
    required this.gradeController,
  });

  factory _CourseGradeRow.fromSubject(SubjectEntity subject) {
    return _CourseGradeRow(
      nameController: TextEditingController(text: subject.name),
      unitsController: TextEditingController(
        text: _formatNumber(subject.units),
      ),
      gradeController: TextEditingController(),
    );
  }

  factory _CourseGradeRow.blank({
    String name = '',
    double? units,
    double? grade,
  }) {
    return _CourseGradeRow(
      nameController: TextEditingController(text: name),
      unitsController: TextEditingController(
        text: units == null ? '' : _formatNumber(units),
      ),
      gradeController: TextEditingController(
        text: grade == null ? '' : grade.toStringAsFixed(2),
      ),
    );
  }

  GpaCourseInput get input {
    return GpaCourseInput(
      units: double.tryParse(unitsController.text.trim()) ?? 0,
      gradePoint: double.tryParse(gradeController.text.trim()),
    );
  }

  void dispose() {
    nameController.dispose();
    unitsController.dispose();
    gradeController.dispose();
  }
}

String _formatNumber(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

class _DecimalInputFormatter extends TextInputFormatter {
  const _DecimalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final value = newValue.text;
    if (value.isEmpty || RegExp(r'^\d{0,3}(\.\d{0,2})?$').hasMatch(value)) {
      return newValue;
    }
    return oldValue;
  }
}
