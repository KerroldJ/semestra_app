# Google OAuth setup (Semestra)

Semestra uses `google_sign_in` for **identity only** — no backend, no Firebase.
Client IDs are supplied at build time via `--dart-define` (see
`dart_defines.example.json`); nothing secret is committed.

> **Platform support:** `google_sign_in` works on **Android, iOS, macOS, Web**.
> It does **not** support Linux or Windows desktop — the sign-in screen will
> always show "not configured" there. Use Android to test.

## App identifiers

| | Value |
|---|---|
| Android package name | `com.example.semestra_app` |
| iOS/macOS bundle id | `com.example.semestraApp` |
| Debug SHA-1 | `BD:32:18:DB:BF:A5:89:CF:92:9F:1F:A6:3E:01:D9:8C:60:8F:FA:37` |

Get the SHA-1 for another machine with:

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android -keypass android
```

## Console setup (console.cloud.google.com → APIs & Services → Credentials)

1. **OAuth consent screen** — configure it, and under *Audience* add your own
   Google account as a **Test user** (otherwise sign-in fails with
   `access_denied` while the app is in "Testing").
2. **Android OAuth client** — Create credentials → OAuth client ID → *Android*.
   - Package name: `com.example.semestra_app`
   - SHA-1: the debug fingerprint above
3. **Web application OAuth client** — Create credentials → OAuth client ID →
   *Web application*. Copy its client id (`…apps.googleusercontent.com`).
   - **Required on Android:** google_sign_in v7 uses Credential Manager, which
     needs this Web client id passed as `serverClientId`.

## Wire the client id into the app

Copy the template and paste your **Web** client id into both fields (the web
client id serves as `clientId` on web/iOS and as `serverClientId` on Android):

```bash
cp dart_defines.example.json dart_defines.json   # already done for you
```

```json
{
  "GOOGLE_CLIENT_ID": "YOUR-WEB-CLIENT-ID.apps.googleusercontent.com",
  "GOOGLE_SERVER_CLIENT_ID": "YOUR-WEB-CLIENT-ID.apps.googleusercontent.com"
}
```

`dart_defines.json` is git-ignored.

## Run on Android

```bash
flutter emulators                       # list emulators
flutter emulators --launch <id>         # or plug in a device
flutter run -d <android-device> --dart-define-from-file=dart_defines.json
```

The "not configured" hint disappears and **Continue with Google** opens the
account picker.

## iOS / macOS (optional)

Also add the iOS client id's reversed form as a URL scheme in
`ios/Runner/Info.plist`, then run with the same `--dart-define-from-file`.

## Release builds

The debug SHA-1 only signs debug builds. For Play Store you'll register a
**release** keystore's SHA-1 (and the Play App Signing SHA-1) as an additional
Android OAuth client.
