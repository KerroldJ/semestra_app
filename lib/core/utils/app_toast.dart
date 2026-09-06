import 'dart:async';
import 'package:flutter/material.dart';

/// Global messenger key so toasts can be resolved to an [Overlay] from anywhere
/// (notifiers, providers) without needing a local BuildContext. Wired into
/// MaterialApp in main.dart.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum _ToastKind { success, info, error }

/// Modern, rounded toast rendered at the TOP of the screen via the app overlay.
class AppToast {
  static OverlayEntry? _entry;

  static void success(String message) => _show(message, _ToastKind.success);
  static void info(String message) => _show(message, _ToastKind.info);
  static void error(String message) => _show(message, _ToastKind.error);

  static void _show(String message, _ToastKind kind) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final overlay = Overlay.maybeOf(messenger.context, rootOverlay: true);
    if (overlay == null) return;

    // Replace any visible toast immediately.
    _entry?.remove();
    _entry = null;

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

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        accent: accent,
        icon: icon,
        onDone: () {
          if (identical(_entry, entry)) {
            entry.remove();
            _entry = null;
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color accent;
  final IconData icon;
  final VoidCallback onDone;

  const _TopToast({
    required this.message,
    required this.accent,
    required this.icon,
    required this.onDone,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2200), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SlideTransition(
            position: _offset,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2235) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: widget.accent.withOpacity(0.35), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                              color: widget.accent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(widget.icon,
                                color: widget.accent, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
