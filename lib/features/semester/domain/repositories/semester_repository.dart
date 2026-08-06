import '../entities/semester_entity.dart';

abstract class SemesterRepository {
  Future<List<SemesterEntity>> getSemesters({bool includeArchived = true});
  Future<SemesterEntity?> getSemesterById(String id);
  Future<void> saveSemester(SemesterEntity semester);
  Future<void> deleteSemester(String id);
}
