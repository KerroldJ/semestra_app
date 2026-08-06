class AppSettings {
  final String themeMode; // "dark", "light"
  final bool notificationsEnabled;
  final int pomodoroFocusDuration; // in minutes
  final int pomodoroShortBreak; // in minutes
  final int pomodoroLongBreak; // in minutes

  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.pomodoroFocusDuration,
    required this.pomodoroShortBreak,
    required this.pomodoroLongBreak,
  });

  AppSettings copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    int? pomodoroFocusDuration,
    int? pomodoroShortBreak,
    int? pomodoroLongBreak,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pomodoroFocusDuration: pomodoroFocusDuration ?? this.pomodoroFocusDuration,
      pomodoroShortBreak: pomodoroShortBreak ?? this.pomodoroShortBreak,
      pomodoroLongBreak: pomodoroLongBreak ?? this.pomodoroLongBreak,
    );
  }
}
