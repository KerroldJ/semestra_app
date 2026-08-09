import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/item_local_data_source.dart';
import '../models/item_model.dart';

class ItemRepositoryImpl implements ItemRepository {
  final ItemLocalDataSource localDataSource;

  ItemRepositoryImpl(this.localDataSource);

  @override
  Future<List<ItemEntity>> getItems() async {
    final models = await localDataSource.getItems();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ItemEntity>> getItemsByType(ItemType type) async {
    final models = await localDataSource.getItemsByType(type.value);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    final model = await localDataSource.getItemById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveItem(ItemEntity item) async {
    final model = ItemModel.fromEntity(item);
    await localDataSource.saveItem(model);
  }

  @override
  Future<void> deleteItem(String id) async {
    await localDataSource.deleteItem(id);
  }
}
