/// Google OAuth client configuration.
///
/// These are filled in by the app owner after completing the Google Cloud
/// console setup (see `docs/GOOGLE_OAUTH_SETUP.md`). They are intentionally
/// build-time constants so the app compiles and runs with placeholders — when
/// they are still blank, [AuthService] reports an "unconfigured" state and the
/// sign-in screen shows a setup hint instead of crashing.
class AuthConfig {
  const AuthConfig._();

  /// Web / iOS OAuth client id (the `xxxx.apps.googleusercontent.com` value).
  /// Required for web and iOS. Leave blank until configured.
  static const String clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  /// Server (a.k.a. "web") client id used to request an ID token / server auth
  /// code. Optional for a pure identity gate; leave blank if unused.
  static const String serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// On Android the client id is resolved from the SHA-1 registered in the
  /// console + `google-services` metadata, so an explicit [clientId] is not
  /// required there. This flag lets the service decide whether sign-in can be
  /// attempted at all on the current platform.
  static bool get hasClientId => clientId.isNotEmpty;
}
