import '../entities/subject_entity.dart';

abstract class SubjectRepository {
  Future<List<SubjectEntity>> getSubjects();
  Future<List<SubjectEntity>> getSubjectsBySemester(String semesterId);
  Future<SubjectEntity?> getSubjectById(String id);
  Future<void> saveSubject(SubjectEntity subject);
  Future<void> deleteSubject(String id);
}
