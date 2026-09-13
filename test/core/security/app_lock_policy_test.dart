import 'package:flutter_test/flutter_test.dart';
import 'package:semestra_app/core/security/app_lock_policy.dart';

void main() {
  group('AppLockPolicy', () {
    test('does not lock when biometrics are disabled', () {
      const policy = AppLockPolicy();

      expect(
        policy.shouldLockOnResume(
          biometricsEnabled: false,
          wasBackgrounded: true,
        ),
        isFalse,
      );
    });

    test('locks on resume after the app was backgrounded', () {
      const policy = AppLockPolicy();

      expect(
        policy.shouldLockOnResume(
          biometricsEnabled: true,
          wasBackgrounded: true,
        ),
        isTrue,
      );
    });

    test(
      'locks on app start when biometric lock is enabled for a new session',
      () {
        const policy = AppLockPolicy();

        expect(
          policy.shouldLockOnStart(
            biometricsEnabled: true,
            sessionUnlocked: false,
          ),
          isTrue,
        );
      },
    );
  });
}
