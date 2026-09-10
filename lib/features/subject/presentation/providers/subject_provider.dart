import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/subject/domain/entities/subject_entity.dart';
import 'package:semestra_app/features/subject/domain/repositories/subject_repository.dart';

class SubjectNotifier extends StateNotifier<AsyncValue<List<SubjectEntity>>> {
  final SubjectRepository _repository;

  SubjectNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getSubjects();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSubject({
    String? id,
    required String semesterId,
    required String code,
    required String name,
    required String instructor,
    required String classroom,
    required double units,
    required int colorValue,
  }) async {
    final newSubject = SubjectEntity(
      id: id ?? const Uuid().v4(),
      semesterId: semesterId,
      code: code,
      name: name,
      instructor: instructor,
      classroom: classroom,
      units: units,
      colorValue: colorValue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveSubject(newSubject);
      await loadSubjects();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editSubject(SubjectEntity subject) async {
    final updated = subject.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveSubject(updated);
      await loadSubjects();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      await _repository.deleteSubject(id);
      await loadSubjects();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final subjectNotifierProvider =
    StateNotifierProvider<SubjectNotifier, AsyncValue<List<SubjectEntity>>>((ref) {
  final repository = ref.watch(subjectRepositoryProvider);
  return SubjectNotifier(repository);
});
