import '../entities/item_entity.dart';

abstract class ItemRepository {
  Future<List<ItemEntity>> getItems();
  Future<List<ItemEntity>> getItemsByType(ItemType type);
  Future<ItemEntity?> getItemById(String id);
  Future<void> saveItem(ItemEntity item);
  Future<void> deleteItem(String id);
}
