import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Базовый эталон для расчётов (iPhone 12 mini). UI масштабируется под любой экран.
class AppMetrics {
  AppMetrics._({
    required this.size,
    required this.viewPadding,
    required this.textScaleFactor,
  });

  final Size size;
  final EdgeInsets viewPadding;
  final double textScaleFactor;

  /// Эталонный телефон — только как точка отсчёта, не жёсткий размер.
  static const referenceShortestSide = 375.0;

  static const minCircle = 168.0;
  static const maxCircle = 320.0;
  static const maxContentWidth = 440.0;

  factory AppMetrics.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    final textScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.35);
    return AppMetrics._(
      size: mq.size,
      viewPadding: mq.viewPadding,
      textScaleFactor: textScaler.scale(1.0),
    );
  }

  double get width => size.width;
  double get height => size.height;
  double get shortestSide => math.min(width, height);
  double get longestSide => math.max(width, height);
  double get aspectRatio => width / height;

  /// Широкий экран: Z Fold (раскрыт), планшет, альбом на телефоне.
  bool get isWideLayout =>
      width >= 600 || (aspectRatio > 1.2 && shortestSide >= 360);

  /// Мало места по высоте (ландшафт, cover-экран с клавиатурой).
  bool get isCompactHeight =>
      height - viewPadding.vertical < 520;

  /// Узкая половинка Z Fold / маленький Android.
  bool get isNarrowPhone => width < 340;

  double get uiScale =>
      (shortestSide / referenceShortestSide).clamp(0.82, 1.18);

  double get edgeInset {
    if (isWideLayout) return 28;
    if (isNarrowPhone) return 14;
    return (shortestSide * 0.053).clamp(16.0, 28.0);
  }

  /// Минимум 44 pt — рекомендация Apple/Google для зоны нажатия.
  double get cornerButtonSize =>
      (shortestSide * 0.117).clamp(44.0, 52.0);

  double get usableWidth => width - edgeInset * 2;
  double get usableHeight =>
      height - viewPadding.top - viewPadding.bottom - edgeInset * 2;

  /// На широких экранах UI не растягивается на всю ширину — остаётся «как телефон» по центру.
  double get contentMaxWidth =>
      isWideLayout ? maxContentWidth : width;

  double get circleDiameter {
    final cornerReserve = cornerButtonSize + 16;

    final byWidth = usableWidth - (isWideLayout ? 48 : 24);
    final byHeight = usableHeight - cornerReserve * 2;

    final heightFactor = isCompactHeight ? 0.58 : 0.66;
    final widthFactor = isWideLayout ? 0.50 : 0.70;
    final proportional =
        math.min(usableWidth * widthFactor, usableHeight * heightFactor);

    return math.min(byWidth, math.min(byHeight, proportional))
        .clamp(minCircle, maxCircle);
  }

  /// Alias для circleDiameter (используется в RingsTimerButton)
  double get timerButtonSize => circleDiameter;

  double timeFontSize(double circleSize) =>
      (circleSize * 0.197 * textScaleFactor).clamp(34.0, 68.0);

  double hintFontSize(double circleSize) =>
      (circleSize * 0.042 * textScaleFactor).clamp(9.0, 15.0);

  double ringStrokeWidth(double circleSize) =>
      (circleSize * 0.013).clamp(2.5, 5.0);

  double sp(double designValue) => designValue * uiScale;

  double sheetRadius() => sp(20);

  EdgeInsets get screenPadding => EdgeInsets.all(edgeInset);
}

/// Центрирует интерфейс на широких экранах (Z Fold, планшеты, Windows-окно).
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = AppMetrics.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.contentMaxWidth),
        child: child,
      ),
    );
  }
}
