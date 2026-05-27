import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppSkeletonizer extends StatelessWidget {
  const AppSkeletonizer({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = dark ? const Color(0xFF2A2A2A) : const Color(0xFFE7ECF4);
    final highlightColor = dark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFF4F7FC);

    return SkeletonizerConfig(
      data: SkeletonizerConfigData(
        containersColor: baseColor,
        effect: ShimmerEffect(
          baseColor: baseColor,
          highlightColor: highlightColor,
          duration: const Duration(milliseconds: 1300),
        ),
      ),
      child: Skeletonizer(
        enabled: enabled,
        enableSwitchAnimation: false,
        containersColor: baseColor,
        child: child,
      ),
    );
  }
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF2A2A2A) : const Color(0xFFE7ECF4);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
    );
  }
}

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF2A2A2A) : const Color(0xFFE7ECF4),
      highlightColor: dark ? const Color(0xFF3A3A3A) : const Color(0xFFF4F7FC),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 4,
    this.separatorHeight = 12,
    this.useShimmer = true,
  });

  final int itemCount;
  final double separatorHeight;
  final bool useShimmer;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final list = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: separatorHeight),
      itemBuilder: itemBuilder,
    );
    return useShimmer ? ShimmerSkeleton(child: list) : list;
  }
}

class ScreenSkeleton extends StatelessWidget {
  const ScreenSkeleton({super.key, this.lines = 6});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SkeletonList(
        itemCount: lines,
        separatorHeight: 14,
        itemBuilder: (context, index) {
          return AppSkeletonizer(
            enabled: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBlock(height: 16, width: 180),
                  SizedBox(height: 10),
                  SkeletonBlock(height: 12),
                  SizedBox(height: 8),
                  SkeletonBlock(height: 12, width: 220),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 32,
            color: Color(0xFFB3261E),
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF64748B)),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
