import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircularTimerButton extends StatelessWidget {
  const CircularTimerButton({
    super.key,
    required this.size,
    required this.timeText,
    required this.progress,
    required this.running,
    required this.hint,
    required this.timeFontSize,
    required this.hintFontSize,
    required this.ringStrokeWidth,
    required this.onTap,
  });

  final double size;
  final String timeText;
  final double progress;
  final bool running;
  final String hint;
  final double timeFontSize;
  final double hintFontSize;
  final double ringStrokeWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringColor = running ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    return Semantics(
      button: true,
      label: timeText,
      child: Material(
        color: colorScheme.surface,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _RingPainter(
                progress: running ? progress : 0,
                color: ringColor,
                trackColor: colorScheme.onSurface.withValues(alpha: 0.12),
                strokeWidth: ringStrokeWidth,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: timeFontSize,
                            fontWeight: FontWeight.w200,
                            height: 1,
                            letterSpacing: -1,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                            color: colorScheme.primary,
                          ),
                        ),
                        if (size >= 140) ...[
                          SizedBox(height: size * 0.02),
                          Text(
                            hint.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: hintFontSize,
                              letterSpacing: 1.4,
                              color: colorScheme.onSurface.withValues(alpha: 0.32),
                            ),
                          ),
                        ],
                      ],
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
