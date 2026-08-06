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

// Assignments
import '../../features/assignment/data/datasources/assignment_local_data_source.dart';
import '../../features/assignment/data/repositories/assignment_repository_impl.dart';
import '../../features/assignment/domain/repositories/assignment_repository.dart';

// Notes
import '../../features/note/data/datasources/note_local_data_source.dart';
import '../../features/note/data/repositories/note_repository_impl.dart';
import '../../features/note/domain/repositories/note_repository.dart';

// Exams
import '../../features/exam/data/datasources/exam_local_data_source.dart';
import '../../features/exam/data/repositories/exam_repository_impl.dart';
import '../../features/exam/domain/repositories/exam_repository.dart';

// Study Session
import '../../features/study_timer/data/datasources/study_local_data_source.dart';
import '../../features/study_timer/data/repositories/study_repository_impl.dart';
import '../../features/study_timer/domain/repositories/study_repository.dart';

// Daily Tasks
import '../../features/daily_planner/data/datasources/daily_task_local_data_source.dart';
import '../../features/daily_planner/data/repositories/daily_task_repository_impl.dart';
import '../../features/daily_planner/domain/repositories/daily_task_repository.dart';

// Grades
import '../../features/grade/data/datasources/grade_local_data_source.dart';
import '../../features/grade/data/repositories/grade_repository_impl.dart';
import '../../features/grade/domain/repositories/grade_repository.dart';

// Expenses
import '../../features/budget/data/datasources/expense_local_data_source.dart';
import '../../features/budget/data/repositories/expense_repository_impl.dart';
import '../../features/budget/domain/repositories/expense_repository.dart';

// Readings
import '../../features/reading/data/datasources/reading_local_data_source.dart';
import '../../features/reading/data/repositories/reading_repository_impl.dart';
import '../../features/reading/domain/repositories/reading_repository.dart';

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

// Assignment Providers
final assignmentLocalDataSourceProvider = Provider<AssignmentLocalDataSource>((ref) {
  return AssignmentLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepositoryImpl(ref.watch(assignmentLocalDataSourceProvider));
});

// Note Providers
final noteLocalDataSourceProvider = Provider<NoteLocalDataSource>((ref) {
  return NoteLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(ref.watch(noteLocalDataSourceProvider));
});

// Exam Providers
final examLocalDataSourceProvider = Provider<ExamLocalDataSource>((ref) {
  return ExamLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepositoryImpl(ref.watch(examLocalDataSourceProvider));
});

// Study Session Providers
final studyLocalDataSourceProvider = Provider<StudyLocalDataSource>((ref) {
  return StudyLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepositoryImpl(ref.watch(studyLocalDataSourceProvider));
});

// Daily Task Providers
final dailyTaskLocalDataSourceProvider = Provider<DailyTaskLocalDataSource>((ref) {
  return DailyTaskLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>((ref) {
  return DailyTaskRepositoryImpl(ref.watch(dailyTaskLocalDataSourceProvider));
});

// Grade Providers
final gradeLocalDataSourceProvider = Provider<GradeLocalDataSource>((ref) {
  return GradeLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  return GradeRepositoryImpl(ref.watch(gradeLocalDataSourceProvider));
});

// Expense Providers
final expenseLocalDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return ExpenseLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(expenseLocalDataSourceProvider));
});

// Reading Providers
final readingLocalDataSourceProvider = Provider<ReadingLocalDataSource>((ref) {
  return ReadingLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepositoryImpl(ref.watch(readingLocalDataSourceProvider));
});

// Settings Providers
final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsLocalDataSourceProvider));
});
