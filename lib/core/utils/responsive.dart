import 'package:flutter/material.dart';

/// Shared breakpoint and viewport helpers used across the app.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 420;
  static const double tablet = 720;
  static const double desktop = 1200;
  static const double wide = 1440;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompactWidth => screenWidth < AppBreakpoints.compact;

  bool get isTabletWidth =>
      screenWidth >= AppBreakpoints.compact &&
      screenWidth < AppBreakpoints.desktop;

  bool get isDesktopWidth => screenWidth >= AppBreakpoints.desktop;

  EdgeInsets get horizontalPagePadding {
    if (screenWidth < AppBreakpoints.compact) {
      return const EdgeInsets.symmetric(horizontal: 12);
    }
    if (screenWidth < AppBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 20);
  }
}

/// Centers the app on large viewports while keeping mobile layouts unchanged.
class ResponsiveAppViewport extends StatelessWidget {
  const ResponsiveAppViewport({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.wide,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: viewportWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
