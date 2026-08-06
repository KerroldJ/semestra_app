import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_local_data_source.dart';
import '../models/exam_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  final ExamLocalDataSource localDataSource;

  ExamRepositoryImpl(this.localDataSource);

  @override
  Future<List<ExamEntity>> getExams() async {
    final models = await localDataSource.getExams();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ExamEntity>> getExamsBySubject(String subjectId) async {
    final models = await localDataSource.getExamsBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveExam(ExamEntity exam) async {
    final model = ExamModel.fromEntity(exam);
    await localDataSource.saveExam(model);
  }

  @override
  Future<void> deleteExam(String id) async {
    await localDataSource.deleteExam(id);
  }
}
