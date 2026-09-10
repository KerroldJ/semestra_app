import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_providers.dart';
import '../data/user_profile_local_data_source.dart';
import '../domain/entities/user_profile.dart';

/// Where the user sits in the (offline) onboarding flow. Drives the router
/// redirect in `app_router.dart`.
enum AuthStatus {
  /// Still restoring on launch — show splash.
  unknown,

  /// No local profile yet — show the "create username" screen.
  needsUsername,

  /// Username chosen — app unlocked.
  ready,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? profile;

  const AuthState({required this.status, this.profile});

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}

AuthStatus _statusFor(UserProfile? p) {
  if (p == null || !p.hasUsername) return AuthStatus.needsUsername;
  return AuthStatus.ready;
}

/// Offline-first profile controller. No network, no accounts — just a locally
/// stored username.
class AuthNotifier extends StateNotifier<AuthState> {
  final UserProfileLocalDataSource _store;
  static const _uuid = Uuid();

  AuthNotifier(this._store)
      : super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final existing = await _store.getProfile();
      state = AuthState(status: _statusFor(existing), profile: existing);
    } catch (_) {
      // Never leave the gate stuck on the splash: fall back to the username
      // screen so the user can still get in.
      state = const AuthState(status: AuthStatus.needsUsername);
    }
  }

  /// Creates the local profile on first launch and unlocks the app.
  Future<void> createUsername(String username) async {
    final existing = state.profile;
    final profile = existing == null
        ? UserProfile(id: _uuid.v4(), username: username.trim())
        : existing.copyWith(username: username.trim());
    await _store.saveProfile(profile);
    state = AuthState(status: _statusFor(profile), profile: profile);
  }

  /// Renames the handle from Settings. No-op if no profile exists yet.
  Future<void> updateUsername(String username) async {
    final p = state.profile;
    if (p == null) return;
    final updated = p.copyWith(username: username.trim());
    await _store.saveProfile(updated);
    state = state.copyWith(status: _statusFor(updated), profile: updated);
  }

  /// Clears the local profile (returns to the username screen).
  Future<void> resetProfile() async {
    await _store.clear();
    state = const AuthState(status: AuthStatus.needsUsername);
  }
}

final userProfileLocalDataSourceProvider =
    Provider<UserProfileLocalDataSource>((ref) {
  return UserProfileLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(userProfileLocalDataSourceProvider));
});
