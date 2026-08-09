import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/core/utils/app_toast.dart';
import 'package:semestra_app/features/item/domain/entities/item_entity.dart';
import 'package:semestra_app/features/item/domain/repositories/item_repository.dart';

class ItemNotifier extends StateNotifier<AsyncValue<List<ItemEntity>>> {
  final ItemRepository _repository;

  ItemNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  String _label(ItemType type) {
    switch (type) {
      case ItemType.note:
        return 'Note';
      case ItemType.task:
        return 'Task';
      case ItemType.assignment:
        return 'Assignment';
    }
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getItems();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addItem({
    required ItemType type,
    String? subjectId,
    required String title,
    String content = '',
    String notes = '',
    List<String> tags = const [],
    DateTime? dueDate,
    int priority = 0,
    int status = 0,
  }) async {
    final now = DateTime.now();
    final newItem = ItemEntity(
      id: const Uuid().v4(),
      type: type,
      subjectId: subjectId,
      title: title,
      content: content,
      notes: notes,
      tags: tags,
      dueDate: dueDate,
      priority: priority,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.saveItem(newItem);
      await loadItems();
      AppToast.success('${_label(type)} added');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not add ${_label(type).toLowerCase()}');
    }
  }

  Future<void> editItem(ItemEntity item, {bool silent = false}) async {
    final updated = item.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.saveItem(updated);
      await loadItems();
      if (!silent) AppToast.success('${_label(item.type)} updated');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not update ${_label(item.type).toLowerCase()}');
    }
  }

  Future<void> toggleTaskCompletion(ItemEntity item) async {
    final updated = item.copyWith(
      status: item.isCompleted ? 0 : 2,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.saveItem(updated);
      await loadItems();
      AppToast.success(updated.isCompleted ? 'Task completed 🎉' : 'Task reopened');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(ItemEntity item, int status) async {
    final updated = item.copyWith(status: status, updatedAt: DateTime.now());
    try {
      await _repository.saveItem(updated);
      await loadItems();
      AppToast.success('${_label(item.type)} updated');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteItem(String id, ItemType type) async {
    try {
      await _repository.deleteItem(id);
      await loadItems();
      AppToast.success('${_label(type)} deleted');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not delete ${_label(type).toLowerCase()}');
    }
  }
}

final itemNotifierProvider =
    StateNotifierProvider<ItemNotifier, AsyncValue<List<ItemEntity>>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return ItemNotifier(repository);
});
