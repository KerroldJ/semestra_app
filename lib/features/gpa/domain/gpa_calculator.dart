enum GradingSystem {
  philippine(
    id: 'philippine',
    name: 'Philippine College (1.00 - 5.00)',
    description: '1.00 is highest, 3.00 is passing, 5.00 is failing',
    minGrade: 1.0,
    maxGrade: 5.0,
    hintText: '1.00 - 5.00',
    isLowerBetter: true,
  ),
  phDepEd(
    id: 'ph_deped',
    name: 'Philippine High School / SHS (DepEd 60 - 100)',
    description: 'DepEd K-12 with Academic Honors (75 passing)',
    minGrade: 60.0,
    maxGrade: 100.0,
    hintText: '60.00 - 100.00',
    isLowerBetter: false,
  ),
  usFourPoint(
    id: 'us_4_0',
    name: 'US 4.0 Scale (0.00 - 4.00)',
    description: '4.00 is highest (A), 2.00 is passing (C), 0.00 is failing (F)',
    minGrade: 0.0,
    maxGrade: 4.0,
    hintText: '0.00 - 4.00',
    isLowerBetter: false,
  ),
  percentage(
    id: 'percentage',
    name: 'Percentage Scale (0% - 100%)',
    description: '100% highest, 75% passing grade',
    minGrade: 0.0,
    maxGrade: 100.0,
    hintText: '0 - 100',
    isLowerBetter: false,
  ),
  fivePoint(
    id: 'five_point',
    name: '5.0 Scale (1.00 - 5.00)',
    description: '5.00 is highest, 3.00 is passing',
    minGrade: 1.0,
    maxGrade: 5.0,
    hintText: '1.00 - 5.00',
    isLowerBetter: false,
  );

  final String id;
  final String name;
  final String description;
  final double minGrade;
  final double maxGrade;
  final String hintText;
  final bool isLowerBetter;

  const GradingSystem({
    required this.id,
    required this.name,
    required this.description,
    required this.minGrade,
    required this.maxGrade,
    required this.hintText,
    required this.isLowerBetter,
  });

  bool isValidGrade(double grade) {
    return grade >= minGrade && grade <= maxGrade;
  }

  String getRemark(double gpa) {
    switch (this) {
      case GradingSystem.philippine:
        if (gpa >= 1.00 && gpa <= 1.25) return "Excellent (President's Lister)";
        if (gpa > 1.25 && gpa <= 1.75) return "Superior (Dean's Lister)";
        if (gpa > 1.75 && gpa <= 2.25) return 'Very Good';
        if (gpa > 2.25 && gpa <= 2.75) return 'Good';
        if (gpa > 2.75 && gpa <= 3.00) return 'Passed';
        return 'Needs Improvement / Failed';

      case GradingSystem.phDepEd:
        if (gpa >= 98.0) return 'With Highest Honors (Outstanding)';
        if (gpa >= 95.0) return 'With High Honors (Outstanding)';
        if (gpa >= 90.0) return 'With Honors (Very Satisfactory)';
        if (gpa >= 85.0) return 'Very Satisfactory';
        if (gpa >= 80.0) return 'Satisfactory';
        if (gpa >= 75.0) return 'Fairly Satisfactory (Passed)';
        return 'Did Not Meet Expectations (Failed)';

      case GradingSystem.usFourPoint:
        if (gpa >= 3.80) return 'Summa Cum Laude (High Honors)';
        if (gpa >= 3.50) return 'Magna Cum Laude (Honors)';
        if (gpa >= 3.00) return 'Cum Laude (Good Standing)';
        if (gpa >= 2.00) return 'Satisfactory / Passed';
        return 'Academic Probation / Below Standard';

      case GradingSystem.percentage:
        if (gpa >= 95) return 'Outstanding / Excellent';
        if (gpa >= 90) return 'Superior';
        if (gpa >= 85) return 'Very Satisfactory';
        if (gpa >= 80) return 'Satisfactory';
        if (gpa >= 75) return 'Passed';
        return 'Failed';

      case GradingSystem.fivePoint:
        if (gpa >= 4.50) return 'First Class Honours (Excellent)';
        if (gpa >= 4.00) return 'Second Class Upper';
        if (gpa >= 3.50) return 'Second Class Lower';
        if (gpa >= 3.00) return 'Third Class (Passed)';
        if (gpa >= 2.00) return 'Pass';
        return 'Failed';
    }
  }
}

enum TargetFeasibility {
  achievable,
  challenging,
  unachievable,
}

class TargetGpaEvaluation {
  final double requiredGpa;
  final TargetFeasibility feasibility;
  final String message;

  const TargetGpaEvaluation({
    required this.requiredGpa,
    required this.feasibility,
    required this.message,
  });
}

class GpaCourseInput {
  final double units;
  final double? gradePoint;

  const GpaCourseInput({required this.units, this.gradePoint});
}

class GpaCalculator {
  const GpaCalculator._();

  static double? calculate(
    List<GpaCourseInput> courses, {
    GradingSystem gradingSystem = GradingSystem.philippine,
  }) {
    var weightedPoints = 0.0;
    var totalUnits = 0.0;

    for (final course in courses) {
      final gradePoint = course.gradePoint;
      if (course.units <= 0 || gradePoint == null) continue;
      if (!gradingSystem.isValidGrade(gradePoint)) continue;

      weightedPoints += course.units * gradePoint;
      totalUnits += course.units;
    }

    if (totalUnits == 0) return null;
    return weightedPoints / totalUnits;
  }

  static double? calculateCumulative({
    required double priorGpa,
    required double priorUnits,
    required double currentGpa,
    required double currentUnits,
  }) {
    final totalUnits = priorUnits + currentUnits;
    if (totalUnits <= 0) return null;
    final totalPoints = (priorGpa * priorUnits) + (currentGpa * currentUnits);
    return totalPoints / totalUnits;
  }

  static TargetGpaEvaluation? evaluateTarget({
    required double currentGpa,
    required double currentUnits,
    required double targetGpa,
    required double remainingUnits,
    required GradingSystem gradingSystem,
  }) {
    if (remainingUnits <= 0) return null;
    final totalUnits = currentUnits + remainingUnits;
    final targetTotalPoints = targetGpa * totalUnits;
    final currentPoints = currentGpa * currentUnits;
    final requiredPoints = targetTotalPoints - currentPoints;
    final requiredGpa = requiredPoints / remainingUnits;

    TargetFeasibility feasibility;
    String message;

    if (gradingSystem.isLowerBetter) {
      if (requiredGpa < gradingSystem.minGrade - 0.001) {
        feasibility = TargetFeasibility.unachievable;
        message =
            'Mathematically unachievable with remaining units (requires ${requiredGpa.toStringAsFixed(2)}, which exceeds best possible ${gradingSystem.minGrade.toStringAsFixed(2)}).';
      } else if (requiredGpa > gradingSystem.maxGrade + 0.001) {
        feasibility = TargetFeasibility.achievable;
        message =
            'Target is already secured even with passing/minimum grades.';
      } else if (requiredGpa <= gradingSystem.minGrade + 0.35) {
        feasibility = TargetFeasibility.challenging;
        message =
            'Challenging! Requires an average grade of ${requiredGpa.toStringAsFixed(2)} across all remaining $remainingUnits units.';
      } else {
        feasibility = TargetFeasibility.achievable;
        message =
            'Achievable! Maintain an average grade of ${requiredGpa.toStringAsFixed(2)} or better across remaining $remainingUnits units.';
      }
    } else {
      if (requiredGpa > gradingSystem.maxGrade + 0.001) {
        feasibility = TargetFeasibility.unachievable;
        message =
            'Mathematically unachievable with remaining units (requires ${requiredGpa.toStringAsFixed(2)}, which exceeds max possible ${gradingSystem.maxGrade.toStringAsFixed(2)}).';
      } else if (requiredGpa < gradingSystem.minGrade - 0.001) {
        feasibility = TargetFeasibility.achievable;
        message =
            'Target is already secured even with minimum passing grades.';
      } else if (requiredGpa >=
          gradingSystem.maxGrade - (gradingSystem.maxGrade * 0.08)) {
        feasibility = TargetFeasibility.challenging;
        message =
            'Challenging! Requires top-tier grade average of ${requiredGpa.toStringAsFixed(2)} across all remaining $remainingUnits units.';
      } else {
        feasibility = TargetFeasibility.achievable;
        message =
            'Achievable! Maintain an average grade of ${requiredGpa.toStringAsFixed(2)} or better across remaining $remainingUnits units.';
      }
    }

    return TargetGpaEvaluation(
      requiredGpa: requiredGpa,
      feasibility: feasibility,
      message: message,
    );
  }
}
