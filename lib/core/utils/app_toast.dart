import 'package:flutter/material.dart';

/// Global messenger key so toasts can be fired from anywhere (notifiers,
/// providers) without needing a BuildContext. Wired into MaterialApp in main.dart.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum _ToastKind { success, info, error }

/// Modern, rounded, floating toast used across the app for CRUD feedback.
class AppToast {
  static void success(String message) => _show(message, _ToastKind.success);
  static void info(String message) => _show(message, _ToastKind.info);
  static void error(String message) => _show(message, _ToastKind.error);

  static void _show(String message, _ToastKind kind) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    late final Color accent;
    late final IconData icon;
    switch (kind) {
      case _ToastKind.success:
        accent = const Color(0xFF10B981); // green
        icon = Icons.check_circle_rounded;
        break;
      case _ToastKind.info:
        accent = const Color(0xFF6366F1); // indigo
        icon = Icons.info_rounded;
        break;
      case _ToastKind.error:
        accent = const Color(0xFFEF4444); // red
        icon = Icons.error_rounded;
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 2),
          padding: EdgeInsets.zero,
          content: _ToastBody(message: message, accent: accent, icon: icon),
        ),
      );
  }
}

class _ToastBody extends StatelessWidget {
  final String message;
  final Color accent;
  final IconData icon;

  const _ToastBody({
    required this.message,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
