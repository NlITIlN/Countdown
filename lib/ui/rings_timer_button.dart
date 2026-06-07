import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/home_timer_controller.dart';
import 'layout.dart';

class RingsTimerButton extends StatefulWidget {
  final String timeText;
  final double progress; // 0.0 to 1.0
  final TimerState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const RingsTimerButton({
    super.key,
    required this.timeText,
    required this.progress,
    required this.state,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<RingsTimerButton> createState() => _RingsTimerButtonState();
}

class _RingsTimerButtonState extends State<RingsTimerButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _resurfaceController;
  late AnimationController _progressController;

  // Press animation
  late Animation<double> _pressScale;
  late Animation<double> _pressOpacity;

  // Pulse animation (for critical state)
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Fade and resurface animations
  late Animation<double> _fadeOpacity;
  late Animation<double> _resurfaceOpacity;
  late Animation<double> _resurfaceScale;

  // Smooth progress animation
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Press animation: 150ms scale and opacity
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
    _pressOpacity = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );

    // Pulse animation: 800-1000ms, repeating
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade animation: 220ms, triggered on completion
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _fadeOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Resurface animation: 1.8 sec, triggered after fade
    _resurfaceController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _resurfaceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resurfaceController, curve: Curves.easeOut),
    );
    _resurfaceScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _resurfaceController, curve: Curves.easeOutBack),
    );

    // Animate progress changes smoothly between ticks
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = AlwaysStoppedAnimation(widget.progress);

    _handleStateChange(widget.state);
  }

  @override
  void didUpdateWidget(RingsTimerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animateProgress(oldWidget.progress, widget.progress);
    }
    if (oldWidget.state != widget.state) {
      _handleStateChange(widget.state);
    }
  }

  void _animateProgress(double from, double to) {
    _progressController.stop();
    _progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController
      ..value = 0
      ..forward();
  }

  void _handleStateChange(TimerState state) {
    // Stop all animations first
    _pressController.stop();
    _pulseController.stop();
    _fadeController.stop();
    _resurfaceController.stop();

    switch (state) {
      case TimerState.idle:
        // No animation, static state
        _pressController.reset();
        _pulseController.reset();
        _fadeController.reset();
        _resurfaceController.reset();
        break;

      case TimerState.press:
        // Trigger press animation
        _pressController.forward().then((_) {
          _pressController.reverse();
        });
        break;

      case TimerState.running:
        // Stop pulse, keep running smooth
        _pulseController.stop();
        break;

      case TimerState.critical:
        // Start repeating pulse
        _pulseController.repeat(reverse: true);
        break;

      case TimerState.completed:
        // Fade out, pause briefly, then resurface with a snappier rebound
        _fadeController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              _resurfaceController.forward();
            }
          });
        });
        break;
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _resurfaceController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    final size = metrics.timerButtonSize; // ~150-200px

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Main ring painter with state-based animations
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _pressController,
                  _pulseController,
                  _fadeController,
                  _resurfaceController,
                  _progressController,
                ]),
                builder: (context, _) {
                  double scale = 1.0;
                  double opacity = 1.0;

                  if (_pressController.isAnimating) {
                    scale = _pressScale.value;
                    opacity = _pressOpacity.value;
                  }

                  if (widget.state == TimerState.critical) {
                    scale = _pulseScale.value;
                    opacity = _pulseOpacity.value;
                  }

                  if (widget.state == TimerState.completed) {
                    opacity = _fadeOpacity.value;
                    if (_resurfaceController.isAnimating) {
                      opacity = _resurfaceOpacity.value;
                    }
                  }

                  final progress = _progressController.isAnimating
                      ? _progressAnimation.value
                      : widget.progress;

                  if (widget.state == TimerState.completed &&
                      _resurfaceController.isAnimating) {
                    scale *= _resurfaceScale.value;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _RingsPainter(
                          progress: progress,
                          state: widget.state,
                          fadeProgress: _fadeController.value,
                          resurfaceProgress: _resurfaceController.value,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Time text overlay
            Text(
              widget.timeText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final TimerState state;
  final double fadeProgress; // 0.0 to 1.0
  final double resurfaceProgress; // 0.0 to 1.0

  _RingsPainter({
    required this.progress,
    required this.state,
    required this.fadeProgress,
    required this.resurfaceProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 10;
    final opacity = _getBaseOpacity();

    const rings = [
      (radiusFactor: 0.95, strokeWidth: 3.0, glowWidth: 12.0, glowBlur: 12.0, glowAlpha: 0.28),
      (radiusFactor: 0.72, strokeWidth: 2.2, glowWidth: 9.0, glowBlur: 10.0, glowAlpha: 0.22),
      (radiusFactor: 0.48, strokeWidth: 1.4, glowWidth: 7.0, glowBlur: 8.0, glowAlpha: 0.18),
    ];

    for (var i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = baseRadius * ring.radiusFactor;
      
      // Draw glow for critical/completed state with per-ring intensity
      if (state == TimerState.critical || state == TimerState.completed) {
        final glowColor = Color.lerp(
          const Color(0xFF27AE60),
          const Color(0xFF6EE7A0),
          i * 0.14,
        )!;
        final glowPaint = Paint()
          ..color = glowColor.withValues(
            alpha: (ring.glowAlpha * opacity * 255).clamp(0.0, 255.0).roundToDouble(),
          )
          ..strokeWidth = ring.glowWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.glowBlur);
        canvas.drawCircle(center, radius, glowPaint);
      }
      
      final baseColor = Color.lerp(
        Colors.grey[600],
        Colors.white,
        0.04 + i * 0.08,
      )!;
      final paint = Paint()
        ..color = baseColor.withValues(
          alpha: (opacity * (0.42 + i * 0.12) * 255).clamp(0.0, 255.0).roundToDouble(),
        )
        ..strokeWidth = ring.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paint);
    }

    final progressVisibility = state == TimerState.completed
        ? (1.0 - fadeProgress).clamp(0.0, 1.0)
        : 1.0;

    if (progress > 0 && progressVisibility > 0.0) {
      final outerRadius = baseRadius * rings.first.radiusFactor;
      final progressColor = _getProgressColor().withValues(
        alpha: (0.95 * opacity * progressVisibility * 255).roundToDouble(),
      );
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final rect = Rect.fromCircle(center: center, radius: outerRadius);
      final startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      final crispPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, crispPaint);

      final angle = startAngle + sweepAngle;
      final indicator = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );
      canvas.drawCircle(
        indicator,
        5.8,
        Paint()..color = progressColor.withValues(alpha: (0.6 * progressVisibility * 255).roundToDouble()),
      );
      canvas.drawCircle(
        indicator,
        3.2,
        Paint()..color = progressColor,
      );
    }
  }

  double _getBaseOpacity() {
    if (state == TimerState.completed) {
      if (fadeProgress < 1.0) {
        return 1.0 - fadeProgress;
      }
      return resurfaceProgress;
    }
    if (state == TimerState.idle) {
      return 0.32;
    }
    if (state == TimerState.running) {
      return 0.9;
    }
    if (state == TimerState.critical) {
      return 1.0;
    }
    return 1.0;
  }

  Color _getProgressColor() {
    switch (state) {
      case TimerState.critical:
        return const Color(0xFFFFB86C);
      case TimerState.completed:
        return const Color(0xFF7EE7F7);
      default:
        return const Color(0xFF6EE7A0);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.state != state ||
        oldDelegate.fadeProgress != fadeProgress ||
        oldDelegate.resurfaceProgress != resurfaceProgress;
  }
}
