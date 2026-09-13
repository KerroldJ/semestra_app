import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'app_lock_policy.dart';
import 'biometric_lock_service.dart';

class BiometricLockHost extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricLockHost({super.key, required this.child});

  @override
  ConsumerState<BiometricLockHost> createState() => _BiometricLockHostState();
}

class _BiometricLockHostState extends ConsumerState<BiometricLockHost>
    with WidgetsBindingObserver {
  final _policy = const AppLockPolicy();
  bool _wasBackgrounded = false;
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockOnStartIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (_authenticating) return;
      _wasBackgrounded = true;
      BiometricLockService.instance.markSessionLocked();
      return;
    }

    if (state == AppLifecycleState.resumed &&
        _policy.shouldLockOnResume(
          biometricsEnabled: ref
              .read(settingsNotifierProvider)
              .biometricLockEnabled,
          wasBackgrounded: _wasBackgrounded,
        )) {
      _wasBackgrounded = false;
      _lockAndAuthenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsNotifierProvider.select((s) => s.biometricLockEnabled), (
      previous,
      next,
    ) {
      if (!next) {
        setState(() => _locked = false);
        BiometricLockService.instance.markSessionLocked();
      } else {
        _lockOnStartIfNeeded();
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_locked) _LockedOverlay(onUnlock: _lockAndAuthenticate),
      ],
    );
  }

  Future<void> _lockAndAuthenticate() async {
    if (_authenticating) return;
    setState(() {
      _locked = true;
      _authenticating = true;
    });

    final unlocked = await BiometricLockService.instance.unlock();
    if (!mounted) return;

    setState(() {
      _locked = !unlocked;
      _authenticating = false;
    });
  }

  void _lockOnStartIfNeeded() {
    if (!mounted) return;
    final enabled = ref.read(settingsNotifierProvider).biometricLockEnabled;
    if (_policy.shouldLockOnStart(
      biometricsEnabled: enabled,
      sessionUnlocked: BiometricLockService.instance.sessionUnlocked,
    )) {
      _lockAndAuthenticate();
    }
  }
}

class _LockedOverlay extends StatelessWidget {
  final VoidCallback onUnlock;

  const _LockedOverlay({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0D1117) : AppTheme.bg;
    final textColor = isDark ? Colors.white : AppTheme.ink;
    final mutedColor = isDark ? Colors.white60 : AppTheme.inkMuted;

    return Material(
      color: background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppTheme.goldDeep,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Semestra is locked',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use your device biometrics to continue.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text('Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
