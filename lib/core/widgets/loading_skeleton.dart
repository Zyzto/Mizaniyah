import 'package:flutter/material.dart';

/// A skeleton loading widget for cards
class CardSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsets? margin;

  const CardSkeleton({super.key, this.height = 100, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate available height after padding
            final availableHeight = constraints.maxHeight;
            // If constrained height is too small, show minimal skeleton
            if (availableHeight < 60) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SkeletonLine(width: 200, height: 12),
                  SizedBox(height: 8),
                  _SkeletonLine(width: 150, height: 10),
                ],
              );
            }
            // Normal skeleton for larger heights
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SkeletonLine(width: 200, height: 16),
                SizedBox(height: 12),
                _SkeletonLine(width: 150, height: 14),
                SizedBox(height: 8),
                _SkeletonLine(width: 100, height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A skeleton line widget
class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// A list of skeleton cards for loading states
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({super.key, this.itemCount = 5, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => CardSkeleton(height: itemHeight),
    );
  }
}
