import '../../domain/entities/semester_entity.dart';
import '../../domain/repositories/semester_repository.dart';
import '../datasources/semester_local_data_source.dart';
import '../models/semester_model.dart';

class SemesterRepositoryImpl implements SemesterRepository {
  final SemesterLocalDataSource localDataSource;

  SemesterRepositoryImpl(this.localDataSource);

  @override
  Future<List<SemesterEntity>> getSemesters({bool includeArchived = true}) async {
    final models = await localDataSource.getSemesters(includeArchived: includeArchived);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SemesterEntity?> getSemesterById(String id) async {
    final model = await localDataSource.getSemesterById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveSemester(SemesterEntity semester) async {
    final model = SemesterModel.fromEntity(semester);
    await localDataSource.saveSemester(model);
  }

  @override
  Future<void> deleteSemester(String id) async {
    await localDataSource.deleteSemester(id);
  }
}
