import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/semester/domain/entities/semester_entity.dart';
import 'package:semestra_app/features/semester/domain/repositories/semester_repository.dart';

class SemesterNotifier extends StateNotifier<AsyncValue<List<SemesterEntity>>> {
  final SemesterRepository _repository;

  SemesterNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSemesters();
  }

  Future<void> loadSemesters() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getSemesters(includeArchived: true);
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSemester({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    final newSem = SemesterEntity(
      id: const Uuid().v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      isArchived: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // If making this semester active, deactivate others
    if (isActive) {
      await _deactivateAllSemesters();
    }

    try {
      await _repository.saveSemester(newSem);
      await loadSemesters();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editSemester(SemesterEntity semester) async {
    final updated = semester.copyWith(updatedAt: DateTime.now());
    
    // If making active, deactivate others
    if (updated.isActive) {
      await _deactivateAllSemesters();
    }

    try {
      await _repository.saveSemester(updated);
      await loadSemesters();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> archiveSemester(SemesterEntity semester, bool archive) async {
    final updated = semester.copyWith(
      isArchived: archive,
      isActive: archive ? false : semester.isActive,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.saveSemester(updated);
      await loadSemesters();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSemester(String id) async {
    try {
      await _repository.deleteSemester(id);
      await loadSemesters();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _deactivateAllSemesters() async {
    final currentList = state.value ?? [];
    for (final sem in currentList) {
      if (sem.isActive) {
        await _repository.saveSemester(sem.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        ));
      }
    }
  }
}

final semesterNotifierProvider =
    StateNotifierProvider<SemesterNotifier, AsyncValue<List<SemesterEntity>>>((ref) {
  final repository = ref.watch(semesterRepositoryProvider);
  return SemesterNotifier(repository);
});
