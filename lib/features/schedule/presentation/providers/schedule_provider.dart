import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/schedule/domain/entities/schedule_entity.dart';
import 'package:semestra_app/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleNotifier extends StateNotifier<AsyncValue<List<ScheduleEntity>>> {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getSchedules();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSchedule({
    required String subjectId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required String classroom,
    required String instructor,
    int type = 0,
  }) async {
    final newSchedule = ScheduleEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      classroom: classroom,
      instructor: instructor,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveSchedule(newSchedule);
      await loadSchedules();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> editSchedule(ScheduleEntity schedule) async {
    final updated = schedule.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveSchedule(updated);
      await loadSchedules();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await _repository.deleteSchedule(id);
      await loadSchedules();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final scheduleNotifierProvider =
    StateNotifierProvider<ScheduleNotifier, AsyncValue<List<ScheduleEntity>>>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleNotifier(repository);
});
