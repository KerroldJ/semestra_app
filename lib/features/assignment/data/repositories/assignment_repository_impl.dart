import '../../domain/entities/assignment_entity.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_local_data_source.dart';
import '../models/assignment_model.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentLocalDataSource localDataSource;

  AssignmentRepositoryImpl(this.localDataSource);

  @override
  Future<List<AssignmentEntity>> getAssignments() async {
    final models = await localDataSource.getAssignments();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AssignmentEntity>> getAssignmentsBySubject(String subjectId) async {
    final models = await localDataSource.getAssignmentsBySubject(subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveAssignment(AssignmentEntity assignment) async {
    final model = AssignmentModel.fromEntity(assignment);
    await localDataSource.saveAssignment(model);
  }

  @override
  Future<void> deleteAssignment(String id) async {
    await localDataSource.deleteAssignment(id);
  }
}
