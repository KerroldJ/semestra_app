import '../../domain/entities/subject_entity.dart';
import '../../domain/repositories/subject_repository.dart';
import '../datasources/subject_local_data_source.dart';
import '../models/subject_model.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectLocalDataSource localDataSource;

  SubjectRepositoryImpl(this.localDataSource);

  @override
  Future<List<SubjectEntity>> getSubjects() async {
    final models = await localDataSource.getSubjects();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SubjectEntity>> getSubjectsBySemester(String semesterId) async {
    final models = await localDataSource.getSubjectsBySemester(semesterId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SubjectEntity?> getSubjectById(String id) async {
    final model = await localDataSource.getSubjectById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveSubject(SubjectEntity subject) async {
    final model = SubjectModel.fromEntity(subject);
    await localDataSource.saveSubject(model);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await localDataSource.deleteSubject(id);
  }
}
