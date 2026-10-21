import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../screens/home_timer_controller.dart';
import 'layout.dart';

class RingsTimerButton extends StatefulWidget {
  final String timeText;

  /// Время окончания отсчёта; null — таймер не идёт.
  final DateTime? endsAt;
  final Duration totalDuration;
  final TimerState state;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Что произойдёт по нажатию — для экранных дикторов.
  final String? semanticsHint;

  const RingsTimerButton({
    super.key,
    required this.timeText,
    required this.endsAt,
    required this.totalDuration,
    required this.state,
    required this.onTap,
    required this.onLongPress,
    this.semanticsHint,
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

  /// «Выезд» дуги при старте и «уезд» при сбросе.
  late AnimationController _revealController;

  // Press animation (UI-only, independent of timer state)
  late Animation<double> _pressScale;

  // Pulse animation (for critical state)
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Fade and resurface animations
  late Animation<double> _fadeOpacity;
  late Animation<double> _resurfaceOpacity;
  late Animation<double> _resurfaceScale;

  // Continuous progress: repaints the canvas only, no widget rebuilds.
  final ValueNotifier<double> _progress = ValueNotifier(0);
  double _rawProgress = 0;
  late final Ticker _frameTicker;
  Timer? _slowTimer;
  double _diameter = AppMetrics.minCircle;

  @override
  void initState() {
    super.initState();

    // Press flash: scale 1.0 → 1.1 → 1.0, 150ms total
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 75),
      vsync: this,
    );
    _pressScale = Tween<double>(begin: 1.0, end: 1.1).animate(
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

    _revealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      // Таймер, восстановленный после перезапуска, показываем сразу.
      value: widget.endsAt != null ? 1 : 0,
    )..addListener(_publishProgress);

    _frameTicker = createTicker((_) => _updateProgress());
    _syncProgressDriver();

    _handleStateChange(widget.state);
  }

  @override
  void didUpdateWidget(RingsTimerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt ||
        oldWidget.totalDuration != widget.totalDuration) {
      if (oldWidget.endsAt == null && widget.endsAt != null) {
        _revealController.forward(from: 0);
      } else if (oldWidget.endsAt != null && widget.endsAt == null) {
        if (widget.state == TimerState.completed) {
          _rawProgress = 0;
        } else {
          _revealController.reverse();
        }
      }
      _syncProgressDriver();
    }
    if (oldWidget.state != widget.state) {
      _handleStateChange(widget.state);
    }
  }

  /// Подбирает частоту обновления дуги: короткий таймер (дуга бежит быстро) —
  /// каждый кадр; длинный — примерно на каждые полпикселя движения.
  /// Так 5-минутный отсчёт не гоняет 60–120 кадров/с ради сдвига в 0,05 px.
  void _syncProgressDriver() {
    _frameTicker.stop();
    _slowTimer?.cancel();
    _slowTimer = null;
    if (widget.endsAt == null) {
      _publishProgress();
      return;
    }
    _updateProgress();

    final totalMs = widget.totalDuration.inMilliseconds;
    final circumference = math.pi * _diameter;
    final msPerHalfPixel = totalMs / (circumference * 2);
    if (msPerHalfPixel <= 33) {
      _frameTicker.start();
    } else {
      final interval =
          Duration(milliseconds: msPerHalfPixel.clamp(33, 250).round());
      _slowTimer = Timer.periodic(interval, (_) => _updateProgress());
    }
  }

  void _updateProgress() {
    final endsAt = widget.endsAt;
    final totalMs = widget.totalDuration.inMilliseconds;
    if (endsAt == null || totalMs <= 0) return;
    final leftMs = endsAt.difference(DateTime.now()).inMilliseconds;
    _rawProgress = (leftMs / totalMs).clamp(0.0, 1.0);
    _publishProgress();
  }

  void _publishProgress() {
    final reveal = Curves.easeOutCubic.transform(_revealController.value);
    _progress.value = _rawProgress * reveal;
  }

  void _playPress() {
    _pressController.forward(from: 0).then((_) {
      if (mounted) _pressController.reverse();
    });
  }

  void _handleStateChange(TimerState state) {
    // Stop state animations first (press flash is independent and keeps playing)
    _pulseController.stop();
    _fadeController.stop();
    _resurfaceController.stop();

    switch (state) {
      case TimerState.idle:
        // No animation, static state
        _pulseController.reset();
        _fadeController.reset();
        _resurfaceController.reset();
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
    _revealController.dispose();
    _frameTicker.dispose();
    _slowTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    final size = metrics.timerButtonSize; // ~150-200px
    if (size != _diameter) {
      _diameter = size;
      // Частота обновления зависит от длины окружности.
      if (widget.endsAt != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncProgressDriver();
        });
      }
    }

    return Semantics(
      button: true,
      label: widget.timeText,
      hint: widget.semanticsHint,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTapDown: (_) => _playPress(),
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
                  ]),
                  builder: (context, _) {
                    double scale = 1.0;
                    double opacity = 1.0;

                    if (widget.state == TimerState.critical) {
                      scale = _pulseScale.value;
                      opacity = _pulseOpacity.value;
                    }

                    scale *= _pressScale.value;

                    if (widget.state == TimerState.completed) {
                      opacity = _fadeOpacity.value;
                      if (_resurfaceController.isAnimating) {
                        opacity = _resurfaceOpacity.value;
                      }
                    }

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
                            progress: _progress,
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
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  /// 0.0–1.0; при изменении холст перерисовывается без перестройки виджетов.
  final ValueListenable<double> progress;
  final TimerState state;
  final double fadeProgress; // 0.0 to 1.0
  final double resurfaceProgress; // 0.0 to 1.0

  _RingsPainter({
    required this.progress,
    required this.state,
    required this.fadeProgress,
    required this.resurfaceProgress,
  }) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final progress = this.progress.value;
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 10;
    final opacity = _getBaseOpacity();

    const rings = [
      (
        radiusFactor: 0.95,
        strokeWidth: 3.0,
        glowWidth: 12.0,
        glowBlur: 12.0,
        glowAlpha: 0.28
      ),
      (
        radiusFactor: 0.72,
        strokeWidth: 2.2,
        glowWidth: 9.0,
        glowBlur: 10.0,
        glowAlpha: 0.22
      ),
      (
        radiusFactor: 0.48,
        strokeWidth: 1.4,
        glowWidth: 7.0,
        glowBlur: 8.0,
        glowAlpha: 0.18
      ),
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
            alpha: (ring.glowAlpha * opacity).clamp(0.0, 1.0),
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
          alpha: (opacity * (0.42 + i * 0.12)).clamp(0.0, 1.0),
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
        alpha: (0.95 * opacity * progressVisibility).clamp(0.0, 1.0),
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
        Paint()
          ..color = progressColor.withValues(
              alpha: (0.6 * progressVisibility).clamp(0.0, 1.0)),
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
