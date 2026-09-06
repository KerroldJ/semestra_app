import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<AppSettings> getSettings() async {
    final settingsMap = await localDataSource.getAllSettings();
    
    final routesStr = settingsMap['main_tab_routes'];
    final mainTabRoutes = routesStr != null && routesStr.isNotEmpty
        ? routesStr.split(',')
        : ['/dashboard', '/semesters', '/subjects', '/schedule', '/planner'];

    return AppSettings(
      themeMode: settingsMap['theme_mode'] ?? 'light',
      notificationsEnabled: settingsMap['notifications_enabled'] == 'true',
      pomodoroFocusDuration: int.tryParse(settingsMap['pomodoro_focus_duration'] ?? '25') ?? 25,
      pomodoroShortBreak: int.tryParse(settingsMap['pomodoro_short_break'] ?? '5') ?? 5,
      pomodoroLongBreak: int.tryParse(settingsMap['pomodoro_long_break'] ?? '15') ?? 15,
      mainTabRoutes: mainTabRoutes,
      weekStartsOn: int.tryParse(settingsMap['week_starts_on'] ?? '1') ?? 1,
      textSize: settingsMap['text_size'] ?? 'default',
      userName: settingsMap['user_name'] ?? 'Student',
      program: settingsMap['program'] ?? 'Computer Science',
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await localDataSource.saveSetting('theme_mode', settings.themeMode);
    await localDataSource.saveSetting('notifications_enabled', settings.notificationsEnabled.toString());
    await localDataSource.saveSetting('pomodoro_focus_duration', settings.pomodoroFocusDuration.toString());
    await localDataSource.saveSetting('pomodoro_short_break', settings.pomodoroShortBreak.toString());
    await localDataSource.saveSetting('pomodoro_long_break', settings.pomodoroLongBreak.toString());
    await localDataSource.saveSetting('main_tab_routes', settings.mainTabRoutes.join(','));
    await localDataSource.saveSetting('week_starts_on', settings.weekStartsOn.toString());
    await localDataSource.saveSetting('text_size', settings.textSize);
    await localDataSource.saveSetting('user_name', settings.userName);
    await localDataSource.saveSetting('program', settings.program);
  }
}
