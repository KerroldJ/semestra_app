import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/app_toast.dart';
import '../../domain/entities/resource_entity.dart';
import '../../domain/repositories/resource_repository.dart';

class ResourceNotifier extends StateNotifier<AsyncValue<List<ResourceEntity>>> {
  final ResourceRepository _repository;

  ResourceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadResources();
  }

  Future<void> loadResources() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getResources();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addResource({
    required String subjectId,
    required String title,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final newResource = ResourceEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      title: title.trim().isEmpty ? fileName : title.trim(),
      fileName: fileName,
      filePath: filePath,
      fileType: fileType,
      fileSize: fileSize,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.createResource(newResource);
      await loadResources();
      AppToast.success('Resource uploaded successfully');
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not save resource: $e');
      return false;
    }
  }

  Future<void> deleteResource(String id, {String? filePath}) async {
    try {
      await _repository.deleteResource(id);
      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {
            // Ignore file deletion error if missing
          }
        }
      }
      await loadResources();
      AppToast.success('Resource deleted');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not delete resource');
    }
  }

  Future<void> updateResource(ResourceEntity resource) async {
    final updated = resource.copyWith(updatedAt: DateTime.now());
    try {
      await _repository.updateResource(updated);
      await loadResources();
      AppToast.success('Resource updated');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      AppToast.error('Could not update resource');
    }
  }
}

final resourceNotifierProvider =
    StateNotifierProvider<ResourceNotifier, AsyncValue<List<ResourceEntity>>>((ref) {
  return ResourceNotifier(ref.watch(resourceRepositoryProvider));
});

/// Provider for resources filtered by a specific subject id
final resourcesForSubjectProvider =
    Provider.family<List<ResourceEntity>, String>((ref, subjectId) {
  final all = ref.watch(resourceNotifierProvider).value ?? [];
  return all.where((r) => r.subjectId == subjectId && !r.isDeleted).toList();
});
