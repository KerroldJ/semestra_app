import '../../domain/entities/grade_entity.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_local_data_source.dart';
import '../models/grade_model.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeLocalDataSource localDataSource;

  GradeRepositoryImpl(this.localDataSource);

  @override
  Future<List<GradeEntity>> getGrades() async {
    final models = await localDataSource.getGrades();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GradeEntity>> getGradesBySubject(String subjectId) async {
    final models = await localDataSource.getGradesBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveGrade(GradeEntity grade) async {
    final model = GradeModel.fromEntity(grade);
    await localDataSource.saveGrade(model);
  }

  @override
  Future<void> deleteGrade(String id) async {
    await localDataSource.deleteGrade(id);
  }
}
