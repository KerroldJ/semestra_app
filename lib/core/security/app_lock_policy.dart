class AppLockPolicy {
  const AppLockPolicy();

  bool shouldLockOnResume({
    required bool biometricsEnabled,
    required bool wasBackgrounded,
  }) {
    return biometricsEnabled && wasBackgrounded;
  }

  bool shouldLockOnStart({
    required bool biometricsEnabled,
    required bool sessionUnlocked,
  }) {
    return biometricsEnabled && !sessionUnlocked;
  }
}
