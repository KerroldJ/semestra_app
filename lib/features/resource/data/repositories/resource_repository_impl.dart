import '../../domain/entities/resource_entity.dart';
import '../../domain/repositories/resource_repository.dart';
import '../datasources/resource_local_data_source.dart';
import '../models/resource_model.dart';

class ResourceRepositoryImpl implements ResourceRepository {
  final ResourceLocalDataSource _localDataSource;

  ResourceRepositoryImpl(this._localDataSource);

  @override
  Future<List<ResourceEntity>> getResources({String? subjectId}) async {
    final models = await _localDataSource.getResources(subjectId: subjectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ResourceEntity?> getResourceById(String id) async {
    final model = await _localDataSource.getResourceById(id);
    return model?.toEntity();
  }

  @override
  Future<void> createResource(ResourceEntity resource) async {
    final model = ResourceModel.fromEntity(resource);
    await _localDataSource.saveResource(model);
  }

  @override
  Future<void> updateResource(ResourceEntity resource) async {
    final model = ResourceModel.fromEntity(resource);
    await _localDataSource.saveResource(model);
  }

  @override
  Future<void> deleteResource(String id) async {
    await _localDataSource.deleteResource(id);
  }
}
