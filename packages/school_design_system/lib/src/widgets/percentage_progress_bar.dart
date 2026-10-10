
import 'package:flutter/material.dart';

class PercentageProgressBar extends StatelessWidget {
  const PercentageProgressBar({
    super.key,
    required this.percentage,
    this.label,
    this.showPercentage = true,
    this.height = 8,
    this.color,
  });

  final double percentage;
  final String? label;
  final bool showPercentage;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null) Text(label!),
                if (showPercentage)
                  Text('${percentage.clamp(0, 100).round()}%'),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
