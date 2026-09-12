class AppSettings {
  final String themeMode; // "dark", "light"
  final bool notificationsEnabled;
  final int pomodoroFocusDuration; // in minutes
  final int pomodoroShortBreak; // in minutes
  final int pomodoroLongBreak; // in minutes
  final List<String> mainTabRoutes;
  final int weekStartsOn; // 1 = Monday ... 7 = Sunday
  final String textSize; // "small", "default", "large"
  final String userName;
  final String program; // e.g. "Computer Science"
  final String? backupDirectoryPath;

  const AppSettings({
    required this.themeMode,
    required this.notificationsEnabled,
    required this.pomodoroFocusDuration,
    required this.pomodoroShortBreak,
    required this.pomodoroLongBreak,
    required this.mainTabRoutes,
    this.weekStartsOn = 1,
    this.textSize = 'default',
    this.userName = 'Student',
    this.program = 'Computer Science',
    this.backupDirectoryPath,
  });

  AppSettings copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    int? pomodoroFocusDuration,
    int? pomodoroShortBreak,
    int? pomodoroLongBreak,
    List<String>? mainTabRoutes,
    int? weekStartsOn,
    String? textSize,
    String? userName,
    String? program,
    String? backupDirectoryPath,
    bool clearBackupDirectory = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      pomodoroFocusDuration: pomodoroFocusDuration ?? this.pomodoroFocusDuration,
      pomodoroShortBreak: pomodoroShortBreak ?? this.pomodoroShortBreak,
      pomodoroLongBreak: pomodoroLongBreak ?? this.pomodoroLongBreak,
      mainTabRoutes: mainTabRoutes ?? this.mainTabRoutes,
      weekStartsOn: weekStartsOn ?? this.weekStartsOn,
      textSize: textSize ?? this.textSize,
      userName: userName ?? this.userName,
      program: program ?? this.program,
      backupDirectoryPath: clearBackupDirectory
          ? null
          : (backupDirectoryPath ?? this.backupDirectoryPath),
    );
  }

  double get textScale {
    switch (textSize) {
      case 'small':
        return 0.9;
      case 'large':
        return 1.15;
      default:
        return 1.0;
    }
  }
}
