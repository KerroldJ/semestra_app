import '../entities/reading_entity.dart';

abstract class ReadingRepository {
  Future<List<ReadingEntity>> getReadings();
  Future<void> saveReading(ReadingEntity reading);
  Future<void> deleteReading(String id);
}
