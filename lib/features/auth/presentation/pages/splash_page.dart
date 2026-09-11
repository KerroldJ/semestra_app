import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';

/// Shown while auth state is [AuthStatus.unknown] (restoring on launch).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Green color spectrum for the light change effect:
    // Transitions smoothly between deeper rich green and glowing bright light green.
    final baseColor = isDark ? const Color(0xFF00B050) : const Color(0xFF009647);
    final lightColor = isDark ? const Color(0xFF86FFB8) : const Color(0xFF2EE67B);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final t = _animation.value;
            final animatedColor = Color.lerp(baseColor, lightColor, t)!;
            final glowRadius = 3.0 + 16.0 * t;
            final glowAlpha = isDark ? (0.25 + 0.35 * t) : (0.12 + 0.28 * t);

            return Wordmark(
              size: 44,
              color: animatedColor,
              dotColor: animatedColor,
              shadows: [
                Shadow(
                  color: AppTheme.brand.withValues(alpha: glowAlpha),
                  blurRadius: glowRadius,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
