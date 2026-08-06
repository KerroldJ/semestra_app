import '../entities/exam_entity.dart';

abstract class ExamRepository {
  Future<List<ExamEntity>> getExams();
  Future<List<ExamEntity>> getExamsBySubject(String subjectId);
  Future<void> saveExam(ExamEntity exam);
  Future<void> deleteExam(String id);
}
