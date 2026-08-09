import 'package:flutter_riverpod/flutter_riverpod.dart';

// Database Helper
import '../database/database_helper.dart';

// Semesters
import '../../features/semester/data/datasources/semester_local_data_source.dart';
import '../../features/semester/data/repositories/semester_repository_impl.dart';
import '../../features/semester/domain/repositories/semester_repository.dart';

// Subjects
import '../../features/subject/data/datasources/subject_local_data_source.dart';
import '../../features/subject/data/repositories/subject_repository_impl.dart';
import '../../features/subject/domain/repositories/subject_repository.dart';

// Schedules
import '../../features/schedule/data/datasources/schedule_local_data_source.dart';
import '../../features/schedule/data/repositories/schedule_repository_impl.dart';
import '../../features/schedule/domain/repositories/schedule_repository.dart';

// Items (unified Notes + Tasks + Assignments)
import '../../features/item/data/datasources/item_local_data_source.dart';
import '../../features/item/data/repositories/item_repository_impl.dart';
import '../../features/item/domain/repositories/item_repository.dart';

// Settings
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';

// Core DB provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// Semester Providers
final semesterLocalDataSourceProvider = Provider<SemesterLocalDataSource>((ref) {
  return SemesterLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final semesterRepositoryProvider = Provider<SemesterRepository>((ref) {
  return SemesterRepositoryImpl(ref.watch(semesterLocalDataSourceProvider));
});

// Subject Providers
final subjectLocalDataSourceProvider = Provider<SubjectLocalDataSource>((ref) {
  return SubjectLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl(ref.watch(subjectLocalDataSourceProvider));
});

// Schedule Providers
final scheduleLocalDataSourceProvider = Provider<ScheduleLocalDataSource>((ref) {
  return ScheduleLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(scheduleLocalDataSourceProvider));
});

// Item Providers (unified module)
final itemLocalDataSourceProvider = Provider<ItemLocalDataSource>((ref) {
  return ItemLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepositoryImpl(ref.watch(itemLocalDataSourceProvider));
});

// Settings Providers
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider));
});
