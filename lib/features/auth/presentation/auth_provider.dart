import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/providers/database_providers.dart';
import '../data/auth_service.dart';
import '../data/user_profile_local_data_source.dart';
import '../domain/entities/user_profile.dart';

/// Where the user sits in the sign-in / onboarding flow. Drives the router
/// redirect in `app_router.dart`.
enum AuthStatus {
  /// Still restoring on launch — show splash.
  unknown,

  /// No local profile — show welcome / sign-in.
  signedOut,

  /// Signed in but no username chosen yet.
  needsUsername,

  /// Username chosen but onboarding (subjects/schedule) not finished.
  needsSetup,

  /// Fully onboarded — app unlocked.
  ready,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? profile;

  /// True when Google OAuth client ids are not configured; the sign-in screen
  /// surfaces a setup hint in this case.
  final bool signInConfigured;

  /// Transient message from the last sign-in attempt (error / hint).
  final String? message;

  /// True while an interactive sign-in is in flight.
  final bool busy;

  const AuthState({
    required this.status,
    this.profile,
    this.signInConfigured = true,
    this.message,
    this.busy = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
    bool? signInConfigured,
    String? message,
    bool clearMessage = false,
    bool? busy,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      signInConfigured: signInConfigured ?? this.signInConfigured,
      message: clearMessage ? null : (message ?? this.message),
      busy: busy ?? this.busy,
    );
  }
}

/// Derives the flow status from a stored profile.
AuthStatus _statusFor(UserProfile? p) {
  if (p == null) return AuthStatus.signedOut;
  if (!p.hasUsername) return AuthStatus.needsUsername;
  if (!p.isOnboarded) return AuthStatus.needsSetup;
  return AuthStatus.ready;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _auth;
  final UserProfileLocalDataSource _store;

  AuthNotifier(this._auth, this._store)
      : super(const AuthState(status: AuthStatus.unknown)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _bootstrapInner();
    } catch (_) {
      // Never leave the gate stuck on the splash (AuthStatus.unknown). If
      // bootstrap fails (e.g. a database error), fall back to signed-out so
      // the user can still reach the welcome / sign-in flow.
      state = AuthState(
        status: AuthStatus.signedOut,
        signInConfigured: _auth.isConfigured,
      );
    }
  }

  Future<void> _bootstrapInner() async {
    final configured = _auth.isConfigured;
    // A stored profile is the source of truth for the gate. We keep the local
    // profile even across app restarts so users don't re-onboard; the Google
    // session is only needed for the initial identity.
    final existing = await _store.getProfile();
    if (existing != null) {
      state = AuthState(
        status: _statusFor(existing),
        profile: existing,
        signInConfigured: configured,
      );
      // Best-effort silent restore in the background (keeps the Google session
      // warm) but it does not change the gate.
      _auth.restore();
      return;
    }

    // No local profile: try a lightweight restore so returning users who
    // cleared local data can slide back in without a tap.
    final identity = configured ? await _auth.restore() : null;
    if (identity != null) {
      final profile = UserProfile(
        googleId: identity.id,
        email: identity.email,
        displayName: identity.displayName,
        photoUrl: identity.photoUrl,
      );
      await _store.saveProfile(profile);
      state = AuthState(
        status: _statusFor(profile),
        profile: profile,
        signInConfigured: configured,
      );
      return;
    }

    state = AuthState(
      status: AuthStatus.signedOut,
      signInConfigured: configured,
    );
  }

  Future<void> signIn() async {
    state = state.copyWith(busy: true, clearMessage: true);
    final result = await _auth.signIn();
    switch (result.outcome) {
      case SignInOutcome.success:
        final id = result.identity!;
        // Preserve an existing local profile for the same account (keeps the
        // chosen username + onboarding), otherwise start fresh.
        final existing = await _store.getProfile();
        final profile = (existing != null && existing.googleId == id.id)
            ? existing.copyWith(
                email: id.email,
                displayName: id.displayName,
                photoUrl: id.photoUrl,
              )
            : UserProfile(
                googleId: id.id,
                email: id.email,
                displayName: id.displayName,
                photoUrl: id.photoUrl,
              );
        await _store.saveProfile(profile);
        state = state.copyWith(
          status: _statusFor(profile),
          profile: profile,
          busy: false,
          clearMessage: true,
        );
        break;
      case SignInOutcome.cancelled:
        state = state.copyWith(busy: false, clearMessage: true);
        break;
      case SignInOutcome.notConfigured:
        state = state.copyWith(
          busy: false,
          signInConfigured: false,
          message: result.message,
        );
        break;
      case SignInOutcome.unavailable:
      case SignInOutcome.failed:
        state = state.copyWith(busy: false, message: result.message);
        break;
    }
  }

  Future<void> setUsername(String username) async {
    final p = state.profile;
    if (p == null) return;
    final updated = p.copyWith(username: username.trim());
    await _store.saveProfile(updated);
    state = state.copyWith(status: _statusFor(updated), profile: updated);
  }

  /// Marks onboarding complete (called after the subjects/schedule steps).
  Future<void> completeOnboarding() async {
    final p = state.profile;
    if (p == null) return;
    final updated = p.copyWith(onboardedAt: DateTime.now());
    await _store.saveProfile(updated);
    state = state.copyWith(status: _statusFor(updated), profile: updated);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _store.clear();
    state = AuthState(
      status: AuthStatus.signedOut,
      signInConfigured: _auth.isConfigured,
    );
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final userProfileLocalDataSourceProvider =
    Provider<UserProfileLocalDataSource>((ref) {
  return UserProfileLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authServiceProvider),
    ref.watch(userProfileLocalDataSourceProvider),
  );
});
