import '../entities/resource_entity.dart';

abstract class ResourceRepository {
  Future<List<ResourceEntity>> getResources({String? subjectId});
  Future<ResourceEntity?> getResourceById(String id);
  Future<void> createResource(ResourceEntity resource);
  Future<void> updateResource(ResourceEntity resource);
  Future<void> deleteResource(String id);
}
