import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/assignment/domain/entities/assignment_entity.dart';
import 'package:semestra_app/features/assignment/domain/repositories/assignment_repository.dart';

class AssignmentNotifier extends StateNotifier<AsyncValue<List<AssignmentEntity>>> {
  final AssignmentRepository _repository;

  AssignmentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAssignments();
  }

  Future<void> loadAssignments() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getAssignments();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAssignment({
    required String subjectId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int priority,
    required int status,
    required String notes,
  }) async {
    final newAssignment = AssignmentEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: status,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveAssignment(newAssignment);
      await loadAssignments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editAssignment(AssignmentEntity assignment) async {
    final updated = assignment.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveAssignment(updated);
      await loadAssignments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateAssignmentStatus(AssignmentEntity assignment, int status) async {
    final updated = assignment.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.saveAssignment(updated);
      await loadAssignments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteAssignment(String id) async {
    try {
      await _repository.deleteAssignment(id);
      await loadAssignments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final assignmentNotifierProvider =
    StateNotifierProvider<AssignmentNotifier, AsyncValue<List<AssignmentEntity>>>((ref) {
  final repository = ref.watch(assignmentRepositoryProvider);
  return AssignmentNotifier(repository);
});
