import 'package:flutter_test/flutter_test.dart';
import 'package:semestra_app/features/gpa/domain/gpa_calculator.dart';

void main() {
  group('GpaCalculator', () {
    test('returns the weighted GPA from units and Philippine grade points', () {
      final result = GpaCalculator.calculate([
        const GpaCourseInput(units: 3, gradePoint: 1.5),
        const GpaCourseInput(units: 2, gradePoint: 1.75),
      ]);

      expect(result, closeTo(1.6, 0.001));
    });

    test('ignores incomplete rows and zero-unit rows', () {
      final result = GpaCalculator.calculate([
        const GpaCourseInput(units: 3, gradePoint: 1.25),
        const GpaCourseInput(units: 0, gradePoint: 1),
        const GpaCourseInput(units: 2),
      ]);

      expect(result, 1.25);
    });

    test('ignores grade points outside the Philippine 1-to-5 scale', () {
      final result = GpaCalculator.calculate([
        const GpaCourseInput(units: 3, gradePoint: 2),
        const GpaCourseInput(units: 3, gradePoint: 0.75),
        const GpaCourseInput(units: 3, gradePoint: 5.25),
      ]);

      expect(result, 2);
    });
  });
}
