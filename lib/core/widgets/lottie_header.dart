import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_theme.dart';

/// A playful animated page header. Renders a network Lottie animation next to a
/// gradient title/subtitle. If the animation fails to load (e.g. offline) it
/// gracefully falls back to a static gradient icon so the page never breaks.
class LottieHeader extends StatelessWidget {
  final String url;
  final String title;
  final String? subtitle;
  final double height;
  final IconData fallbackIcon;

  const LottieHeader({
    super.key,
    required this.url,
    required this.title,
    this.subtitle,
    this.height = 120,
    this.fallbackIcon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget fallback() => Container(
          width: height,
          height: height,
          alignment: Alignment.center,
          child: ShaderMask(
            shaderCallback: (bounds) =>
                const LinearGradient(colors: AppTheme.primaryGradient).createShader(bounds),
            child: Icon(fallbackIcon, size: height * 0.5, color: Colors.white),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          SizedBox(
            height: height,
            width: height,
            child: Lottie.network(
              url,
              fit: BoxFit.contain,
              frameRate: FrameRate.max,
              errorBuilder: (context, error, stack) => fallback(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      const LinearGradient(colors: AppTheme.primaryGradient).createShader(bounds),
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
