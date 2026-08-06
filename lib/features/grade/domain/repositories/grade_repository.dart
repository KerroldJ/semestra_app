import '../entities/grade_entity.dart';

abstract class GradeRepository {
  Future<List<GradeEntity>> getGrades();
  Future<List<GradeEntity>> getGradesBySubject(String subjectId);
  Future<void> saveGrade(GradeEntity grade);
  Future<void> deleteGrade(String id);
}
