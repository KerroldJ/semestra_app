import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_config.dart';

/// Result of a sign-in attempt that the UI can branch on without knowing about
/// the google_sign_in package.
enum SignInOutcome { success, cancelled, notConfigured, unavailable, failed }

class SignInResult {
  final SignInOutcome outcome;
  final GoogleIdentity? identity;
  final String? message;
  const SignInResult(this.outcome, {this.identity, this.message});
}

/// Plain identity extracted from a Google account — keeps the rest of the app
/// free of google_sign_in types.
class GoogleIdentity {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  const GoogleIdentity({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

/// Thin wrapper over google_sign_in v7's singleton API.
///
/// Design goals:
/// - The app must run even when OAuth client ids are not configured yet. In
///   that case [isConfigured] is false and sign-in returns
///   [SignInOutcome.notConfigured] so the UI can show a setup hint.
/// - No other layer imports google_sign_in; everyone talks in [GoogleIdentity].
class AuthService {
  bool _initialized = false;
  bool _initFailed = false;

  /// True when we have enough config to attempt sign-in on this platform.
  /// Android resolves its client id from the console/SHA-1 rather than a
  /// compile-time constant, so it only needs the package to initialize.
  bool get isConfigured {
    if (_initFailed) return false;
    if (kIsWeb) return AuthConfig.hasClientId;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return true;
      case TargetPlatform.iOS:
        case TargetPlatform.macOS:
        return AuthConfig.hasClientId;
      default:
        return AuthConfig.hasClientId;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || _initFailed) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: AuthConfig.clientId.isEmpty ? null : AuthConfig.clientId,
        serverClientId:
            AuthConfig.serverClientId.isEmpty ? null : AuthConfig.serverClientId,
      );
      _initialized = true;
    } catch (e) {
      _initFailed = true;
      debugPrint('AuthService: initialize failed: $e');
    }
  }

  GoogleIdentity _toIdentity(GoogleSignInAccount a) => GoogleIdentity(
        id: a.id,
        email: a.email,
        displayName: a.displayName ?? a.email.split('@').first,
        photoUrl: a.photoUrl,
      );

  /// Silent restore on launch. Returns null if no session can be restored (or
  /// if auth is unconfigured / unavailable).
  Future<GoogleIdentity?> restore() async {
    if (!isConfigured) return null;
    await _ensureInitialized();
    if (!_initialized) return null;
    try {
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account == null) return null;
      return _toIdentity(account);
    } catch (e) {
      debugPrint('AuthService: restore failed: $e');
      return null;
    }
  }

  /// Interactive sign-in.
  Future<SignInResult> signIn() async {
    if (!isConfigured) {
      return const SignInResult(
        SignInOutcome.notConfigured,
        message: 'Google sign-in isn’t configured yet.',
      );
    }
    await _ensureInitialized();
    if (!_initialized) {
      return const SignInResult(
        SignInOutcome.notConfigured,
        message: 'Google sign-in isn’t configured yet.',
      );
    }

    // On some platforms (notably web) the platform prefers a rendered button
    // over a programmatic call. Report that clearly rather than throwing.
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      return const SignInResult(
        SignInOutcome.unavailable,
        message: 'Sign-in isn’t available on this platform build.',
      );
    }

    try {
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      return SignInResult(SignInOutcome.success, identity: _toIdentity(account));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SignInResult(SignInOutcome.cancelled);
      }
      debugPrint('AuthService: signIn exception: ${e.code} ${e.description}');
      return SignInResult(SignInOutcome.failed, message: e.description);
    } catch (e) {
      debugPrint('AuthService: signIn failed: $e');
      return SignInResult(SignInOutcome.failed, message: e.toString());
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('AuthService: signOut failed: $e');
    }
  }
}
