import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/grade/domain/entities/grade_entity.dart';
import 'package:semestra_app/features/grade/domain/repositories/grade_repository.dart';

class GradeNotifier extends StateNotifier<AsyncValue<List<GradeEntity>>> {
  final GradeRepository _repository;

  GradeNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGrades();
  }

  Future<void> loadGrades() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getGrades();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addGrade({
    required String subjectId,
    required String assessmentName,
    required double weight,
    required double scoreObtained,
    required double scoreMax,
    required String gradeLetter,
  }) async {
    final newGrade = GradeEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      assessmentName: assessmentName,
      weight: weight,
      scoreObtained: scoreObtained,
      scoreMax: scoreMax,
      gradeLetter: gradeLetter,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveGrade(newGrade);
      await loadGrades();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editGrade(GradeEntity grade) async {
    final updated = grade.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveGrade(updated);
      await loadGrades();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteGrade(String id) async {
    try {
      await _repository.deleteGrade(id);
      await loadGrades();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final gradeNotifierProvider =
    StateNotifierProvider<GradeNotifier, AsyncValue<List<GradeEntity>>>((ref) {
  final repository = ref.watch(gradeRepositoryProvider);
  return GradeNotifier(repository);
});
