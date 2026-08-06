import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/exam/domain/entities/exam_entity.dart';
import 'package:semestra_app/features/exam/domain/repositories/exam_repository.dart';

class ExamNotifier extends StateNotifier<AsyncValue<List<ExamEntity>>> {
  final ExamRepository _repository;

  ExamNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExams();
  }

  Future<void> loadExams() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getExams();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addExam({
    required String subjectId,
    required String title,
    required DateTime scheduledDate,
    required String coverage,
    required String notes,
    required int type,
  }) async {
    final newExam = ExamEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: title,
      scheduledDate: scheduledDate,
      coverage: coverage,
      notes: notes,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveExam(newExam);
      await loadExams();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editExam(ExamEntity exam) async {
    final updated = exam.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveExam(updated);
      await loadExams();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      await _repository.deleteExam(id);
      await loadExams();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final examNotifierProvider =
    StateNotifierProvider<ExamNotifier, AsyncValue<List<ExamEntity>>>((ref) {
  final repository = ref.watch(examRepositoryProvider);
  return ExamNotifier(repository);
});
