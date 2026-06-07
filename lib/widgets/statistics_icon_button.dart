import 'package:flutter/material.dart';

class StatisticsIconButton extends StatelessWidget {
  const StatisticsIconButton({
    super.key,
    required this.size,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.5;
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.bar_chart,
              size: iconSize,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
