import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

import '../l10n/strings.dart';

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
        title: S.forRu(isRu).timerDoneTitle,
        body: S.forRu(isRu).timerDoneScheduledBody,
      );
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
