import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void show(
    String title,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _GlassSnackbar(
        title: title,
        message: message,
        isError: isError,
        isSuccess: isSuccess,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

class _GlassSnackbar extends StatefulWidget {
  final String title;
  final String message;
  final bool isError;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _GlassSnackbar({
    required this.title,
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_GlassSnackbar> createState() => _GlassSnackbarState();
}

class _GlassSnackbarState extends State<_GlassSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🎨 Dynamic glass color
  Color _getGlassColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444).withOpacity(0.18); // red glass
    } else if (widget.isSuccess) {
      return const Color(0xFF22C55E).withOpacity(0.18); // green glass
    } else {
      return Colors.white.withOpacity(0.12); // default glass
    }
  }

  /// 🎨 Border color
  Color _getBorderColor() {
    if (widget.isError) {
      return const Color(0xFFEF4444).withOpacity(0.35);
    } else if (widget.isSuccess) {
      return  Color(0xFF22C55E).withOpacity(0.35);
    } else {
      return Color(0xFF122B52).withOpacity(0.25);
    }
  }

  /// 🎨 Icon color
  Color _getIconColor() {
    if (widget.isError) return Colors.red.shade300;
    if (widget.isSuccess) return Colors.green.shade300;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 12,
      right: 12,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _getGlassColor(),
                        border: Border.all(color: _getBorderColor()),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.002),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.isError
                                ? Icons.error_outline
                                : widget.isSuccess
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                            color: _getIconColor(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.85),
                                  ),
                                ),
                              ],
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