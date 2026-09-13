import 'package:local_auth/local_auth.dart';

class BiometricLockService {
  BiometricLockService._();

  static final BiometricLockService instance = BiometricLockService._();

  final LocalAuthentication _auth = LocalAuthentication();
  bool _sessionUnlocked = false;

  bool get sessionUnlocked => _sessionUnlocked;

  void markSessionLocked() {
    _sessionUnlocked = false;
  }

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      return supported && biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlock() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Unlock Semestra to continue',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) _sessionUnlocked = true;
      return authenticated;
    } catch (_) {
      return false;
    }
  }
}
