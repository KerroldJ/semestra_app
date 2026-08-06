import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/reading/domain/entities/reading_entity.dart';
import 'package:semestra_app/features/reading/domain/repositories/reading_repository.dart';

class ReadingNotifier extends StateNotifier<AsyncValue<List<ReadingEntity>>> {
  final ReadingRepository _repository;

  ReadingNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadReadings();
  }

  Future<void> loadReadings() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getReadings();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addReading({
    required String title,
    required String author,
    String? filePath,
    required int format,
    required int totalPages,
    required int currentPage,
    required int status,
    required String notes,
  }) async {
    final newReading = ReadingEntity(
      id: const Uuid().v4(),
      title: title,
      author: author,
      filePath: filePath,
      format: format,
      totalPages: totalPages,
      currentPage: currentPage,
      status: status,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveReading(newReading);
      await loadReadings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editReading(ReadingEntity reading) async {
    final updated = reading.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveReading(updated);
      await loadReadings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProgress(ReadingEntity reading, int currentPage) async {
    int nextStatus = reading.status;
    if (currentPage >= reading.totalPages) {
      currentPage = reading.totalPages;
      nextStatus = 2; // Completed
    } else if (currentPage > 0 && reading.status == 0) {
      nextStatus = 1; // Reading
    }
    
    final updated = reading.copyWith(
      currentPage: currentPage,
      status: nextStatus,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveReading(updated);
      await loadReadings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteReading(String id) async {
    try {
      await _repository.deleteReading(id);
      await loadReadings();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final readingNotifierProvider =
    StateNotifierProvider<ReadingNotifier, AsyncValue<List<ReadingEntity>>>((ref) {
  final repository = ref.watch(readingRepositoryProvider);
  return ReadingNotifier(repository);
});
