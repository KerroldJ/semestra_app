import '../entities/assignment_entity.dart';

abstract class AssignmentRepository {
  Future<List<AssignmentEntity>> getAssignments();
  Future<List<AssignmentEntity>> getAssignmentsBySubject(String subjectId);
  Future<void> saveAssignment(AssignmentEntity assignment);
  Future<void> deleteAssignment(String id);
}
