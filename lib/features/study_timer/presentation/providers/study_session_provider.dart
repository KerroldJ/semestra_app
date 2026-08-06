import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'package:semestra_app/core/providers/database_providers.dart';
import 'package:semestra_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:semestra_app/features/study_timer/domain/entities/study_session_entity.dart';
import 'package:semestra_app/features/study_timer/domain/repositories/study_repository.dart';

// --- Study Session History Notifier ---

class StudySessionHistoryNotifier extends StateNotifier<AsyncValue<List<StudySessionEntity>>> {
  final StudyRepository _repository;

  StudySessionHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getStudySessions();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logSession({
    required String? subjectId,
    required int durationSeconds,
    required int sessionType,
  }) async {
    final newSession = StudySessionEntity(
      id: const Uuid().v4(),
      subjectId: subjectId,
      durationSeconds: durationSeconds,
      sessionType: sessionType,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.saveStudySession(newSession);
      await loadSessions();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final studySessionHistoryProvider =
    StateNotifierProvider<StudySessionHistoryNotifier, AsyncValue<List<StudySessionEntity>>>((ref) {
  final repository = ref.watch(studyRepositoryProvider);
  return StudySessionHistoryNotifier(repository);
});


// --- Pomodoro Live Timer Notifier ---

class PomodoroTimerState {
  final int remainingSeconds;
  final bool isRunning;
  final int sessionType; // 0 = Focus, 1 = Short Break, 2 = Long Break
  final String? activeSubjectId;
  final int initialSeconds;

  const PomodoroTimerState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.sessionType,
    this.activeSubjectId,
    required this.initialSeconds,
  });

  PomodoroTimerState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    int? sessionType,
    String? activeSubjectId,
    int? initialSeconds,
  }) {
    return PomodoroTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionType: sessionType ?? this.sessionType,
      activeSubjectId: activeSubjectId ?? this.activeSubjectId,
      initialSeconds: initialSeconds ?? this.initialSeconds,
    );
  }
}

class PomodoroTimerNotifier extends StateNotifier<PomodoroTimerState> {
  final Ref _ref;
  Timer? _timer;

  PomodoroTimerNotifier(this._ref)
      : super(const PomodoroTimerState(
          remainingSeconds: 25 * 60,
          isRunning: false,
          sessionType: 0,
          activeSubjectId: null,
          initialSeconds: 25 * 60,
        )) {
    // Reset timer when settings change
    _ref.listen(settingsNotifierProvider, (previous, next) {
      if (!state.isRunning) {
        resetTimer();
      }
    });
  }

  void startTimer() {
    if (state.isRunning) return;

    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimerComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resetTimer() {
    _timer?.cancel();
    final settings = _ref.read(settingsNotifierProvider);
    int minutes = settings.pomodoroFocusDuration;
    if (state.sessionType == 1) {
      minutes = settings.pomodoroShortBreak;
    } else if (state.sessionType == 2) {
      minutes = settings.pomodoroLongBreak;
    }
    
    state = state.copyWith(
      remainingSeconds: minutes * 60,
      initialSeconds: minutes * 60,
      isRunning: false,
    );
  }

  void changeSessionType(int type) {
    _timer?.cancel();
    final settings = _ref.read(settingsNotifierProvider);
    int minutes = settings.pomodoroFocusDuration;
    if (type == 1) {
      minutes = settings.pomodoroShortBreak;
    } else if (type == 2) {
      minutes = settings.pomodoroLongBreak;
    }

    state = state.copyWith(
      sessionType: type,
      remainingSeconds: minutes * 60,
      initialSeconds: minutes * 60,
      isRunning: false,
    );
  }

  void selectSubject(String? subjectId) {
    state = state.copyWith(activeSubjectId: subjectId);
  }

  void _onTimerComplete() {
    _timer?.cancel();
    
    // Save to history if it was a Focus session
    if (state.sessionType == 0) {
      _ref.read(studySessionHistoryProvider.notifier).logSession(
            subjectId: state.activeSubjectId,
            durationSeconds: state.initialSeconds,
            sessionType: state.sessionType,
          );
    }

    // Auto-transition to break or focus
    int nextType = 0;
    if (state.sessionType == 0) {
      nextType = 1; // Short break
    } else {
      nextType = 0; // Focus
    }

    changeSessionType(nextType);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroTimerProvider =
    StateNotifierProvider<PomodoroTimerNotifier, PomodoroTimerState>((ref) {
  return PomodoroTimerNotifier(ref);
});
