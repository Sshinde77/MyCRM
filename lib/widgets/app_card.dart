import 'package:flutter/material.dart';

/// Reusable container that mirrors the active theme card styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final shape = cardTheme.shape;

    BorderRadius? borderRadius;
    BoxBorder? border;

    // Extract border radius and border side when the theme uses a rounded shape.
    if (shape is RoundedRectangleBorder) {
      borderRadius = shape.borderRadius as BorderRadius?;
      border = Border.fromBorderSide(shape.side);
    }

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardTheme.color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border,
        boxShadow: [
          if ((cardTheme.elevation ?? 0) > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: cardTheme.elevation!,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );
  }
}
