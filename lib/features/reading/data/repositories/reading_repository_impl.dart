import '../../domain/entities/reading_entity.dart';
import '../../domain/repositories/reading_repository.dart';
import '../datasources/reading_local_data_source.dart';
import '../models/reading_model.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  final ReadingLocalDataSource localDataSource;

  ReadingRepositoryImpl(this.localDataSource);

  @override
  Future<List<ReadingEntity>> getReadings() async {
    final models = await localDataSource.getReadings();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveReading(ReadingEntity reading) async {
    final model = ReadingModel.fromEntity(reading);
    await localDataSource.saveReading(model);
  }

  @override
  Future<void> deleteReading(String id) async {
    await localDataSource.deleteReading(id);
  }
}
