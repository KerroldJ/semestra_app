import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/settings/domain/entities/app_settings.dart';
import 'package:semestra_app/features/settings/domain/repositories/settings_repository.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository)
      : super(const AppSettings(
          themeMode: 'dark',
          notificationsEnabled: true,
          pomodoroFocusDuration: 25,
          pomodoroShortBreak: 5,
          pomodoroLongBreak: 15,
          mainTabRoutes: [
            '/dashboard',
            '/semesters',
            '/subjects',
            '/schedule',
            '/notes'
          ],
        )) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final settings = await _repository.getSettings();
      state = settings;
    } catch (_) {
      // Keep defaults on failure
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      await _repository.saveSettings(newSettings);
      state = newSettings;
    } catch (_) {
      // Handle error
    }
  }

  Future<void> toggleThemeMode() async {
    final mode = state.themeMode == 'dark' ? 'light' : 'dark';
    await updateSettings(state.copyWith(themeMode: mode));
  }

  Future<void> toggleNotifications(bool enabled) async {
    await updateSettings(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateMainTabRoutes(List<String> routes) async {
    await updateSettings(state.copyWith(mainTabRoutes: routes));
  }



  Future<void> updatePomodoroFocus(int duration) async {
    await updateSettings(state.copyWith(pomodoroFocusDuration: duration));
  }

  Future<void> updatePomodoroShortBreak(int duration) async {
    await updateSettings(state.copyWith(pomodoroShortBreak: duration));
  }

  Future<void> updatePomodoroLongBreak(int duration) async {
    await updateSettings(state.copyWith(pomodoroLongBreak: duration));
  }
}

final settingsNotifierProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repository);
});
