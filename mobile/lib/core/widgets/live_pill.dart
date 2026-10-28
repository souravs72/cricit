import 'package:flutter/material.dart';

import '../../app/theme.dart';

class LivePill extends StatelessWidget {
  const LivePill({super.key, this.label = 'New'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.tertiary,
          borderRadius: BorderRadius.circular(CricitRadius.full),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CricitSpace.sm,
            vertical: CricitSpace.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onTertiary),
          ),
        ),
      ),
    );
  }
}
