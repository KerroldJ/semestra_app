import '../../domain/entities/study_session_entity.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/study_local_data_source.dart';
import '../models/study_session_model.dart';

class StudyRepositoryImpl implements StudyRepository {
  final StudyLocalDataSource localDataSource;

  StudyRepositoryImpl(this.localDataSource);

  @override
  Future<List<StudySessionEntity>> getStudySessions() async {
    final models = await localDataSource.getStudySessions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<StudySessionEntity>> getStudySessionsBySubject(String subjectId) async {
    final models = await localDataSource.getStudySessionsBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveStudySession(StudySessionEntity session) async {
    final model = StudySessionModel.fromEntity(session);
    await localDataSource.saveStudySession(model);
  }
}
