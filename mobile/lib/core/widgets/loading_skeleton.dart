import 'package:flutter/material.dart';

import '../../app/theme.dart';

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        return Semantics(
          label: 'Loading stories',
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: scheme.outline.withValues(alpha: 0.35),
                child: SizedBox(height: height * 0.42),
              ),
              Padding(
                padding: const EdgeInsets.all(CricitSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Bar(width: 220, color: scheme.outline),
                    const SizedBox(height: CricitSpace.md),
                    _Bar(width: double.infinity, color: scheme.outline),
                    const SizedBox(height: CricitSpace.sm),
                    _Bar(width: double.infinity, color: scheme.outline),
                    const SizedBox(height: CricitSpace.sm),
                    _Bar(width: 180, color: scheme.outline),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(CricitRadius.sm),
      ),
    );
  }
}
