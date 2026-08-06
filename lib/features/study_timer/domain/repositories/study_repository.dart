import '../entities/study_session_entity.dart';

abstract class StudyRepository {
  Future<List<StudySessionEntity>> getStudySessions();
  Future<List<StudySessionEntity>> getStudySessionsBySubject(String subjectId);
  Future<void> saveStudySession(StudySessionEntity session);
}
