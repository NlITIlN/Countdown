import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

class DesktopNotificationHandler {
  final Map<int, Timer> _timers = {};

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> init() async {
    if (!isDesktop) return;

    try {
      await localNotifier.setup(
        appName: 'Countdown',
      );
    } catch (e) {
      debugPrint('Desktop notifications init failed: $e');
    }
  }

  Future<void> scheduleSteps({
    required DateTime endsAt,
    required int totalSeconds,
    required bool isRu,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    await cancelSteps();

    try {
      await _scheduleNotification(
        id: 100,
        at: endsAt,
        title: isRu ? 'Таймер завершён' : 'Timer finished',
        body: isRu
            ? 'Время вышло — нажмите для нового запуска'
            : 'Time is up — tap to start again',
      );

      if (totalSeconds >= 120) {
        final halfAt = endsAt.subtract(Duration(seconds: totalSeconds ~/ 2));
        if (halfAt.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: 101,
            at: halfAt,
            title: isRu ? 'Половина пути' : 'Halfway there',
            body: isRu ? 'Осталось 50% времени' : '50% of time remaining',
          );
        }
      }

      if (totalSeconds > 15) {
        final tenAt = endsAt.subtract(const Duration(seconds: 10));
        if (tenAt.isAfter(DateTime.now())) {
          await _scheduleNotification(
            id: 102,
            at: tenAt,
            title: isRu ? '10 секунд' : '10 seconds',
            body: isRu ? 'Скоро окончание таймера' : 'Timer ending soon',
          );
        }
      }
    } catch (e) {
      debugPrint('scheduleSteps failed: $e');
    }
  }

  Future<void> cancelSteps() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  Future<void> show(
    String title,
    String body, {
    required int id,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    try {
      if (isDesktop) {
        await LocalNotification(title: title, body: body).show();
      }
    } catch (e) {
      debugPrint('show failed: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    _timers[id]?.cancel();

    final delay = at.difference(DateTime.now());
    if (delay.isNegative) return;

    _timers[id] = Timer(delay, () {
      LocalNotification(title: title, body: body).show();
    });
  }
}
