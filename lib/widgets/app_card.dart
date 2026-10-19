import 'package:flutter/material.dart';

/// Reusable container that mirrors the active theme card styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BorderRadiusGeometry? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.border,
    this.boxShadow,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final shape = cardTheme.shape;

    BorderRadius? defaultRadius;
    BoxBorder? defaultBorder;

    // Extract border radius and border side when the theme uses a rounded shape.
    if (shape is RoundedRectangleBorder) {
      defaultRadius = shape.borderRadius as BorderRadius?;
      defaultBorder = Border.fromBorderSide(shape.side);
    }

    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? cardTheme.color ?? Colors.white,
        borderRadius: borderRadius ?? defaultRadius ?? BorderRadius.circular(12),
        border: border ?? defaultBorder,
        boxShadow: boxShadow ?? [
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
