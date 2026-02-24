import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ToastType { success, error, info, warning }

class AppToast extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const AppToast({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast> {
  @override
  Widget build(BuildContext context) {
    return Container(); // Not used directly
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(widget.type);

    return Positioned(
      bottom: 24,
      left: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: colorScheme.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        colorScheme.icon,
                        color: colorScheme.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastScheme _getColorScheme(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastScheme(
          icon: LucideIcons.checkCircle2,
          color: const Color(0xFF5a6c37),
          bgColor: const Color(0xFF5a6c37).withValues(alpha: 0.1),
        );
      case ToastType.error:
        return _ToastScheme(
          icon: LucideIcons.alertCircle,
          color: Colors.red[700]!,
          bgColor: Colors.red[50]!,
        );
      case ToastType.warning:
        return _ToastScheme(
          icon: LucideIcons.alertTriangle,
          color: Colors.orange[700]!,
          bgColor: Colors.orange[50]!,
        );
      case ToastType.info:
        return _ToastScheme(
          icon: LucideIcons.info,
          color: Colors.blue[700]!,
          bgColor: Colors.blue[50]!,
        );
    }
  }
}

class _ToastScheme {
  final IconData icon;
  final Color color;
  final Color bgColor;

  _ToastScheme({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
